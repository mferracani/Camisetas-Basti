#!/bin/zsh

set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "Uso: scripts/archive-testflight.sh <build-number>" >&2
  exit 64
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

branch="$(git branch --show-current)"
if [[ "$branch" != "main" ]]; then
  echo "Release cancelado: la rama actual es '$branch', no 'main'." >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Release cancelado: el working tree tiene cambios sin commit." >&2
  exit 1
fi

if [[ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]]; then
  echo "Release cancelado: main local no coincide con origin/main." >&2
  exit 1
fi

simulator_view="Views/TournamentSimulatorView.swift"
required_markers=(
  '@State private var selectedCountryId = "wc26"'
  'Label("EQUIPOS"'
  '"ALEATORIO"'
  'Label("ORIGINAL"'
  '"SIMULAR TODO"'
)

for marker in "${required_markers[@]}"; do
  if ! grep -Fq "$marker" "$simulator_view"; then
    echo "Release cancelado: falta el marcador del Mundial: $marker" >&2
    exit 1
  fi
done

if grep -Fq 'filter { $0.id != "wc26" }' "$simulator_view"; then
  echo "Release cancelado: SIMULAR TORNEO sigue excluyendo MUNDIAL 2026." >&2
  exit 1
fi

build_number="$1"
archive_path="build/TestFlight/CamisetasBasti-build${build_number}-worldcup.xcarchive"

if [[ "${RELEASE_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "Preflight OK: commit $(git rev-parse --short HEAD), build $build_number"
  exit 0
fi

echo "Archivando commit $(git rev-parse --short HEAD), build $build_number"
xcodebuild \
  -project CamisetasBasti.xcodeproj \
  -scheme CamisetasBasti \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  CURRENT_PROJECT_VERSION="$build_number" \
  archive

echo "Archive listo: $archive_path"

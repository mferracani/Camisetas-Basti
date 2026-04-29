# Project State

## Fase actual
frontend

## Gate status
- [x] Gate 1: PRD aprobado
- [x] Gate 2: UX aprobado
- [x] Gate 3: Build completo (código Swift)
- [x] Security Review: Aprobado (COPPA/Kids compliant)
- [x] QA Checklist: Generado
- [ ] Assets finales: Faltan fuentes, sonidos, icono, launch screen

## Decisiones tomadas
- 2026-04-29 Product Manager: Stack = Swift nativo (SwiftUI) para iOS + macOS. No Next.js/Supabase.
- 2026-04-29 Product Manager: Sin backend remoto. App local-first, offline, UserDefaults.
- 2026-04-29 Product Manager: Sin onboarding. Niño aprende explorando.
- 2026-04-29 Product Manager: 4 sonidos embebidos (tap, success, celebrate, error-soft).
- 2026-04-29 Product Manager: Escudos y camisetas en vectores nativos estilizados (no oficiales).
- 2026-04-29 Product Manager: iPad landscape. macOS ventana adaptable.
- 2026-04-29 Product Manager: MVP 3-4 semanas.
- 2026-04-29 Local Data Designer: UserDefaults Codable para persistencia. Sin Core Data en MVP.
- 2026-04-29 Local Data Designer: AVAudioPlayer con categoría .ambient (respeta silencio).
- 2026-04-29 Local Data Designer: ContentVersion = 1 para migración futura.

## Handoffs completados
- [x] product-manager → ux-designer: PRD aprobado, pasar a UX Spec
- [x] ux-designer → backend-designer: UX spec generado y aprobado
- [x] backend-designer → swiftui-engineer: backend-spec generado y aprobado
- [x] swiftui-engineer → security-reviewer: código Swift implementado
- [x] security-reviewer → qa-engineer: revisión aprobada (COPPA compliant)
- [x] qa-engineer → usuario/assets: checklist generado, tests escritos

## Bloqueante actual
Faltan assets binarios (fuentes, sonidos, icono) y proyecto Xcode. Ver `ASSETS.md`.

## Open questions para el usuario
- (ninguna, todas cerradas en PRD sección 10)

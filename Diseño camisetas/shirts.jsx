// Shirt + Crest SVG renderer.
// Shirt path is consistent across all teams: front view, short sleeves,
// crew neck, slight shoulder bevel, soft inner shadow for volume.
// Reveal mode: applies a SVG <mask> for partial discovery.
//
// Props: { team, kit:'home'|'away', size, mode:'color'|'gray'|'partial', revealPct }
// mode='partial' uses revealPct (0..100) to clip the colored shirt over a gray shirt.

const SHIRT_W = 240, SHIRT_H = 280;

// Master shirt outline path. Approx 240x280 viewBox.
const SHIRT_PATH = "M 60 28 L 92 14 C 100 30 140 30 148 14 L 180 28 L 220 56 L 200 96 L 178 86 L 178 252 C 178 262 172 268 162 268 L 78 268 C 68 268 62 262 62 252 L 62 86 L 40 96 L 20 56 Z";
const SLEEVE_L = "M 60 28 L 20 56 L 40 96 L 62 86 L 62 60 Z";
const SLEEVE_R = "M 180 28 L 220 56 L 200 96 L 178 86 L 178 60 Z";
const COLLAR = "M 92 14 C 100 30 140 30 148 14 L 142 22 C 134 32 106 32 98 22 Z";

function PatternFill({ pattern, colors, id }) {
  const [c1, c2, c3] = colors;
  switch (pattern) {
    case 'solid':
      return <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />;
    case 'stripes-v': {
      const stripeW = 22;
      const stripes = [];
      for (let x = 0; x < SHIRT_W; x += stripeW) {
        stripes.push(<rect key={x} x={x} y="0" width={stripeW} height={SHIRT_H} fill={Math.floor(x / stripeW) % 2 === 0 ? c1 : c2} />);
      }
      return <g>{stripes}</g>;
    }
    case 'stripes-h':
    case 'hoops': {
      const stripeH = 24;
      const stripes = [];
      for (let y = 0; y < SHIRT_H; y += stripeH) {
        stripes.push(<rect key={y} x="0" y={y} width={SHIRT_W} height={stripeH} fill={Math.floor(y / stripeH) % 2 === 0 ? c1 : c2} />);
      }
      return <g>{stripes}</g>;
    }
    case 'split-v':
      return <g>
        <rect x="0" y="0" width={SHIRT_W / 2} height={SHIRT_H} fill={c1} />
        <rect x={SHIRT_W / 2} y="0" width={SHIRT_W / 2} height={SHIRT_H} fill={c2} />
      </g>;
    case 'split-v-blue-claret':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <rect x="86" y="0" width={68} height={SHIRT_H} fill={c2} />
      </g>;
    case 'split-d':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <polygon points={`0,${SHIRT_H} ${SHIRT_W},0 ${SHIRT_W},${SHIRT_H}`} fill={c2} />
      </g>;
    case 'sash-d':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <polygon points="20,260 60,260 220,40 180,40" fill={c2} />
      </g>;
    case 'sash-h':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <rect x="0" y="100" width={SHIRT_W} height="56" fill={c2} />
      </g>;
    case 'sash-h-thin':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <rect x="0" y="110" width={SHIRT_W} height="36" fill={c2} />
      </g>;
    case 'sash-h-thick':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <rect x="0" y="80" width={SHIRT_W} height="68" fill={c2} />
      </g>;
    case 'sash-v':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <polygon points="48,16 108,16 168,260 108,260" fill={c2} />
      </g>;
    case 'sash-v-fat':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
        <rect x="92" y="0" width="56" height={SHIRT_H} fill={c2} />
      </g>;
    case 'sleeves-w':
      return <g>
        <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />
      </g>;
    default:
      return <rect x="0" y="0" width={SHIRT_W} height={SHIRT_H} fill={c1} />;
  }
}

// Renders a shirt at given size. mode: 'color' | 'gray' | 'partial' | 'mini'
// kit: 'home' | 'away'
function Shirt({ team, kit = 'home', size = 200, mode = 'color', revealPct = 0, showCrest = true, withShadow = true, idSuffix = '' }) {
  const kitData = team[kit] || team.home;
  const colors = kitData.c;
  const pattern = kitData.pattern;
  const uid = React.useMemo(() => `s${Math.random().toString(36).slice(2, 8)}${idSuffix}`, [idSuffix]);

  const aspectH = (size * SHIRT_H) / SHIRT_W;
  const isGray = mode === 'gray';
  const isPartial = mode === 'partial';

  // Sleeve secondary: white sleeves for Arsenal-style; otherwise pattern continues
  const sleeveColor = pattern === 'sleeves-w' ? '#FFFFFF' : null;

  return (
    <svg width={size} height={aspectH} viewBox={`0 0 ${SHIRT_W} ${SHIRT_H}`} style={{ display: 'block' }}>
      <defs>
        <clipPath id={`clip-${uid}`}>
          <path d={SHIRT_PATH} />
        </clipPath>
        <linearGradient id={`shadow-${uid}`} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="rgba(0,0,0,0)" />
          <stop offset="100%" stopColor="rgba(0,0,0,0.18)" />
        </linearGradient>
        <linearGradient id={`hi-${uid}`} x1="0" x2="1" y1="0" y2="0">
          <stop offset="0%" stopColor="rgba(255,255,255,0.18)" />
          <stop offset="50%" stopColor="rgba(255,255,255,0)" />
          <stop offset="100%" stopColor="rgba(0,0,0,0.10)" />
        </linearGradient>
        {/* Fabric texture */}
        <pattern id={`tex-${uid}`} x="0" y="0" width="6" height="6" patternUnits="userSpaceOnUse">
          <rect width="6" height="6" fill="rgba(255,255,255,0)" />
          <circle cx="1" cy="1" r="0.4" fill="rgba(255,255,255,0.06)" />
        </pattern>
        {/* Reveal mask */}
        {isPartial && (
          <mask id={`reveal-${uid}`}>
            <rect width={SHIRT_W} height={SHIRT_H} fill="black" />
            {/* irregular reveal blobs based on pct */}
            <RevealBlobs pct={revealPct} />
          </mask>
        )}
      </defs>

      {withShadow && (
        <ellipse cx={SHIRT_W / 2} cy={SHIRT_H - 4} rx="86" ry="6" fill="rgba(0,0,0,0.10)" />
      )}

      {/* Gray base layer (always present so partial reveal has a substrate) */}
      <g clipPath={`url(#clip-${uid})`}>
        <rect width={SHIRT_W} height={SHIRT_H} fill={isGray ? '#D9D5CE' : (isPartial ? '#D9D5CE' : '#FFFFFF')} />
      </g>

      {/* Real shirt: visible if mode=color; clipped by reveal if partial */}
      {!isGray && (
        <g clipPath={`url(#clip-${uid})`} mask={isPartial ? `url(#reveal-${uid})` : undefined}>
          <PatternFill pattern={pattern} colors={colors} id={uid} />
          {sleeveColor && (
            <g>
              <path d={SLEEVE_L} fill={sleeveColor} />
              <path d={SLEEVE_R} fill={sleeveColor} />
            </g>
          )}
          <rect width={SHIRT_W} height={SHIRT_H} fill={`url(#tex-${uid})`} />
          <rect width={SHIRT_W} height={SHIRT_H} fill={`url(#hi-${uid})`} />
          <rect width={SHIRT_W} height={SHIRT_H} fill={`url(#shadow-${uid})`} />
        </g>
      )}

      {/* If gray mode: stitching lines for fabric feel */}
      {isGray && (
        <g clipPath={`url(#clip-${uid})`}>
          <rect width={SHIRT_W} height={SHIRT_H} fill="url(#tex-${uid})" />
          <rect width={SHIRT_W} height={SHIRT_H} fill={`url(#shadow-${uid})`} />
          {/* Center seam hint */}
          <line x1={SHIRT_W/2} y1="40" x2={SHIRT_W/2} y2="260" stroke="rgba(0,0,0,0.06)" strokeWidth="1" strokeDasharray="2 4" />
        </g>
      )}

      {/* Outline */}
      <path d={SHIRT_PATH} fill="none" stroke={isGray ? 'rgba(0,0,0,0.15)' : 'rgba(0,0,0,0.18)'} strokeWidth="1.5" strokeLinejoin="round" />
      {/* Collar */}
      <path d={COLLAR} fill={isGray ? '#C8C3B9' : (kit === 'home' ? colors[1] : colors[0])} stroke="rgba(0,0,0,0.15)" strokeWidth="1" />

      {/* Crest */}
      {showCrest && !isGray && mode !== 'partial' && (
        <g transform="translate(150, 100)">
          <Crest crest={team.crest} size={36} />
        </g>
      )}
      {showCrest && isPartial && revealPct > 50 && (
        <g transform="translate(150, 100)" style={{ opacity: Math.min(1, (revealPct - 50) / 30) }}>
          <Crest crest={team.crest} size={36} />
        </g>
      )}
    </svg>
  );
}

// Pseudo-random reveal blobs based on pct.
// Returns N white circles distributed across the shirt area.
function RevealBlobs({ pct }) {
  const blobs = React.useMemo(() => {
    // Deterministic pseudo-random
    const seed = 42;
    const rand = (n) => {
      const x = Math.sin(seed + n * 13.37) * 10000;
      return x - Math.floor(x);
    };
    const out = [];
    const total = 28;
    const visible = Math.ceil((pct / 100) * total);
    for (let i = 0; i < visible; i++) {
      out.push({
        cx: 30 + rand(i) * 180,
        cy: 30 + rand(i + 100) * 220,
        r: 28 + rand(i + 200) * 18,
      });
    }
    return out;
  }, [pct]);
  return <g>{blobs.map((b, i) => <circle key={i} cx={b.cx} cy={b.cy} r={b.r} fill="white" />)}</g>;
}

// Crest renderer.
function Crest({ crest, size = 40 }) {
  if (!crest) return null;
  const [c1, c2] = crest.colors;
  const text = crest.text || '';
  const half = size / 2;

  let shape;
  if (crest.shape === 'round') {
    shape = <circle cx={half} cy={half} r={half - 1} fill={c1} stroke={c2} strokeWidth="2" />;
  } else if (crest.shape === 'diamond') {
    shape = <polygon points={`${half},1 ${size-1},${half} ${half},${size-1} 1,${half}`} fill={c1} stroke={c2} strokeWidth="2" />;
  } else { // shield
    shape = <path d={`M 2 2 L ${size-2} 2 L ${size-2} ${size*0.55} Q ${size-2} ${size-1} ${half} ${size-1} Q 2 ${size-1} 2 ${size*0.55} Z`} fill={c1} stroke={c2} strokeWidth="2" />;
  }

  // Dynamically size text
  const fontSize = text.length <= 2 ? size * 0.42 : text.length <= 3 ? size * 0.32 : size * 0.24;

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ overflow: 'visible' }}>
      {shape}
      <text x={half} y={half + fontSize * 0.35} textAnchor="middle" fontWeight="900" fontSize={fontSize} fill={c2} style={{ fontFamily: 'system-ui, -apple-system, sans-serif', letterSpacing: '-0.5px' }}>
        {text}
      </text>
    </svg>
  );
}

// Standalone large crest (for headers, ficha)
function BigCrest({ crest, size = 80 }) {
  return <Crest crest={crest} size={size} />;
}

// Country flag SVG
function Flag({ country, w = 80, h = 56, rounded = 8 }) {
  const id = `f${country.id}`;
  if (country.id === 'arg') {
    return (
      <svg width={w} height={h} viewBox="0 0 80 56">
        <defs><clipPath id={id}><rect width="80" height="56" rx={rounded} /></clipPath></defs>
        <g clipPath={`url(#${id})`}>
          <rect y="0" width="80" height="18.6" fill="#75AADB" />
          <rect y="18.6" width="80" height="18.8" fill="#FFFFFF" />
          <rect y="37.4" width="80" height="18.6" fill="#75AADB" />
          <circle cx="40" cy="28" r="6" fill="#FCBF49" stroke="#B07900" strokeWidth="0.8" />
          <g transform="translate(40,28)">
            {Array.from({length:8}).map((_,i)=>(
              <rect key={i} x="-0.8" y="-9" width="1.6" height="3" fill="#FCBF49" transform={`rotate(${i*45})`} />
            ))}
          </g>
        </g>
      </svg>
    );
  }
  if (country.id === 'eng') {
    return (
      <svg width={w} height={h} viewBox="0 0 80 56">
        <defs><clipPath id={id}><rect width="80" height="56" rx={rounded} /></clipPath></defs>
        <g clipPath={`url(#${id})`}>
          <rect width="80" height="56" fill="#FFFFFF" />
          <rect x="34" y="0" width="12" height="56" fill="#CE1124" />
          <rect x="0" y="22" width="80" height="12" fill="#CE1124" />
        </g>
      </svg>
    );
  }
  if (country.id === 'esp') {
    return (
      <svg width={w} height={h} viewBox="0 0 80 56">
        <defs><clipPath id={id}><rect width="80" height="56" rx={rounded} /></clipPath></defs>
        <g clipPath={`url(#${id})`}>
          <rect y="0" width="80" height="14" fill="#AA151B" />
          <rect y="14" width="80" height="28" fill="#F1BF00" />
          <rect y="42" width="80" height="14" fill="#AA151B" />
        </g>
      </svg>
    );
  }
  if (country.id === 'ita') {
    return (
      <svg width={w} height={h} viewBox="0 0 80 56">
        <defs><clipPath id={id}><rect width="80" height="56" rx={rounded} /></clipPath></defs>
        <g clipPath={`url(#${id})`}>
          <rect x="0" width="26.7" height="56" fill="#008C45" />
          <rect x="26.7" width="26.7" height="56" fill="#F4F5F0" />
          <rect x="53.3" width="26.7" height="56" fill="#CD212A" />
        </g>
      </svg>
    );
  }
  if (country.id === 'fra') {
    return (
      <svg width={w} height={h} viewBox="0 0 80 56">
        <defs><clipPath id={id}><rect width="80" height="56" rx={rounded} /></clipPath></defs>
        <g clipPath={`url(#${id})`}>
          <rect x="0" width="26.7" height="56" fill="#0055A4" />
          <rect x="26.7" width="26.7" height="56" fill="#FFFFFF" />
          <rect x="53.3" width="26.7" height="56" fill="#EF4135" />
        </g>
      </svg>
    );
  }
  if (country.id === 'ger') {
    return (
      <svg width={w} height={h} viewBox="0 0 80 56">
        <defs><clipPath id={id}><rect width="80" height="56" rx={rounded} /></clipPath></defs>
        <g clipPath={`url(#${id})`}>
          <rect y="0" width="80" height="18.7" fill="#000000" />
          <rect y="18.7" width="80" height="18.6" fill="#DD0000" />
          <rect y="37.3" width="80" height="18.7" fill="#FFCE00" />
        </g>
      </svg>
    );
  }
  return null;
}

Object.assign(window, { Shirt, Crest, BigCrest, Flag });

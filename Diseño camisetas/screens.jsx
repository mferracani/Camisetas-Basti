// Common UI primitives + screens.

function BackButton({ onClick }) {
  return (
    <button onClick={onClick} style={{
      width: 64, height: 64, borderRadius: 32, border: 'none',
      background: '#FFFFFF', boxShadow: '0 4px 12px rgba(80,50,20,0.10)',
      fontSize: 32, fontWeight: 900, color: '#7A4E1B', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center'
    }}>←</button>
  );
}

function BigKidButton({ children, onClick, variant = 'primary', icon, size = 'md', style = {} }) {
  const variants = {
    primary: { bg: '#FF7B3D', fg: '#FFFFFF', shadow: 'rgba(255,123,61,0.4)' },
    secondary: { bg: '#FFFFFF', fg: '#3D2A1F', shadow: 'rgba(80,50,20,0.12)' },
    sun: { bg: '#FFC93C', fg: '#3D2A1F', shadow: 'rgba(232,159,0,0.35)' },
    sky: { bg: '#6BCBFF', fg: '#FFFFFF', shadow: 'rgba(107,203,255,0.4)' },
    grass: { bg: '#7DDB8B', fg: '#FFFFFF', shadow: 'rgba(125,219,139,0.4)' },
  };
  const v = variants[variant];
  const sizes = {
    sm: { padY: 14, padX: 22, fz: 16, minH: 56 },
    md: { padY: 18, padX: 28, fz: 22, minH: 80 },
    lg: { padY: 24, padX: 36, fz: 28, minH: 104 },
  };
  const s = sizes[size];
  return (
    <button onClick={onClick} style={{
      background: v.bg, color: v.fg, border: 'none',
      padding: `${s.padY}px ${s.padX}px`, minHeight: s.minH,
      borderRadius: 28, fontSize: s.fz, fontWeight: 900, letterSpacing: '0.5px',
      boxShadow: `0 8px 0 ${v.shadow}, 0 12px 24px ${v.shadow}`,
      cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 12,
      transition: 'transform 120ms, box-shadow 120ms', ...style
    }}
    onMouseDown={e => { e.currentTarget.style.transform = 'translateY(4px)'; e.currentTarget.style.boxShadow = `0 4px 0 ${v.shadow}, 0 6px 12px ${v.shadow}`; }}
    onMouseUp={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = `0 8px 0 ${v.shadow}, 0 12px 24px ${v.shadow}`; }}
    onMouseLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = `0 8px 0 ${v.shadow}, 0 12px 24px ${v.shadow}`; }}
    >
      {icon && <span style={{ fontSize: s.fz * 1.2 }}>{icon}</span>}
      {children}
    </button>
  );
}

function ProgressStars({ count = 2, total = 2, size = 24 }) {
  return (
    <div style={{ display: 'flex', gap: 4 }}>
      {Array.from({length: total}).map((_,i)=>(
        <div key={i} style={{ fontSize: size, opacity: i<count?1:0.3, filter: i<count?'none':'grayscale(1)' }}>⭐</div>
      ))}
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 1. HOME
// ──────────────────────────────────────────────────────
function HomeScreen({ palette, onGo }) {
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
      {/* Decorative blobs */}
      <div style={{ position: 'absolute', top: -80, right: -60, width: 280, height: 280, borderRadius: '50%', background: '#FFE9C7', opacity: 0.5 }} />
      <div style={{ position: 'absolute', bottom: -100, left: -80, width: 320, height: 320, borderRadius: '50%', background: '#FFD7C0', opacity: 0.4 }} />

      {/* Top status bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: '20px 36px', position: 'relative', zIndex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 16px', background: '#FFFFFF', borderRadius: 999, boxShadow: '0 2px 8px rgba(80,50,20,0.08)' }}>
          <span style={{ fontSize: 14 }}>✈</span>
          <span style={{ fontSize: 12, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1 }}>LISTO PARA JUGAR SIN INTERNET</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 16px', background: '#FFFFFF', borderRadius: 999, boxShadow: '0 2px 8px rgba(80,50,20,0.08)' }}>
          <span style={{ fontSize: 16 }}>⭐</span>
          <span style={{ fontSize: 16, fontWeight: 900, color: '#3D2A1F' }}>12</span>
        </div>
      </div>

      {/* Title */}
      <div style={{ textAlign: 'center', marginTop: 20, position: 'relative', zIndex: 1 }}>
        <div style={{ fontSize: 88, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-2px', lineHeight: 1 }}>
          CAMISETAS
        </div>
        <div style={{ fontSize: 22, fontWeight: 700, color: '#7A4E1B', letterSpacing: 2, marginTop: 8 }}>
          ⚽ PINTA · DESCUBRE · COLECCIONA ⚽
        </div>
      </div>

      {/* Hero shirts */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginTop: 24, position: 'relative', zIndex: 1 }}>
        <div style={{ transform: 'rotate(-12deg) translateY(20px)' }}><Shirt team={CAMI_DATA.TEAMS.arg[0]} kit="home" size={140} /></div>
        <div style={{ transform: 'translateY(-10px)' }}><Shirt team={CAMI_DATA.TEAMS.esp[1]} kit="home" size={170} /></div>
        <div style={{ transform: 'rotate(12deg) translateY(20px)' }}><Shirt team={CAMI_DATA.TEAMS.eng[2]} kit="home" size={140} /></div>
      </div>

      {/* Buttons */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', paddingBottom: 56, gap: 18, position: 'relative', zIndex: 1 }}>
        <BigKidButton variant="primary" size="lg" icon="🌎" onClick={() => onGo('countries')} style={{ minWidth: 380 }}>PAÍSES</BigKidButton>
        <div style={{ display: 'flex', gap: 18 }}>
          <BigKidButton variant="sky" size="md" icon="👕" onClick={() => onGo('games')} style={{ minWidth: 200 }}>JUGAR</BigKidButton>
          <BigKidButton variant="grass" size="md" icon="📒" onClick={() => onGo('album')} style={{ minWidth: 200 }}>ÁLBUM</BigKidButton>
        </div>
        <BigKidButton variant="sun" size="sm" icon="⭐" onClick={() => onGo('rewards')}>PREMIOS</BigKidButton>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 2. PAÍSES
// ──────────────────────────────────────────────────────
function CountriesScreen({ palette, onBack, onPick }) {
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 12 }}>
        <BackButton onClick={onBack} />
        <div style={{ fontSize: 44, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>ELIGE UN PAÍS</div>
      </div>
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gridTemplateRows: 'repeat(2, 1fr)', gap: 20 }}>
        {CAMI_DATA.COUNTRIES.map(c => {
          const teams = CAMI_DATA.TEAMS[c.id] || [];
          let total = teams.length * 2;
          let got = 0;
          teams.forEach(t => {
            const h = CAMI_DATA.SEED_PROGRESS[`${c.id}.${t.id}.home`] || 0;
            const a = CAMI_DATA.SEED_PROGRESS[`${c.id}.${t.id}.away`] || 0;
            got += (h===2?1:0) + (a===2?1:0);
          });
          return (
            <button key={c.id} onClick={() => onPick(c)} style={{
              background: '#FFFFFF', border: 'none', borderRadius: 32,
              boxShadow: '0 8px 24px rgba(80,50,20,0.10), 0 2px 0 rgba(80,50,20,0.06)',
              cursor: 'pointer', padding: 24, display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center', gap: 14, position: 'relative',
              transition: 'transform 150ms'
            }}
            onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-4px)'}
            onMouseLeave={e => e.currentTarget.style.transform = ''}
            >
              <div style={{ filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.12))' }}>
                <Flag country={c} w={180} h={120} rounded={18} />
              </div>
              <div style={{ fontSize: 28, fontWeight: 900, color: '#3D2A1F', letterSpacing: '0.5px' }}>{c.name}</div>
              <div style={{ position: 'absolute', top: 16, right: 16, padding: '4px 12px', background: '#FFE9C7', borderRadius: 999, fontSize: 13, fontWeight: 800, color: '#7A4E1B' }}>{got}/{total}</div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 3. LISTA DE EQUIPOS
// ──────────────────────────────────────────────────────
function TeamsScreen({ palette, country, onBack, onPick }) {
  const teams = CAMI_DATA.TEAMS[country.id] || [];
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 16 }}>
        <BackButton onClick={onBack} />
        <Flag country={country} w={64} h={44} rounded={8} />
        <div style={{ fontSize: 36, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>{country.name}</div>
      </div>
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gridTemplateRows: 'repeat(2, 1fr)', gap: 16, overflow: 'hidden' }}>
        {teams.map(t => {
          const h = CAMI_DATA.SEED_PROGRESS[`${country.id}.${t.id}.home`] || 0;
          const a = CAMI_DATA.SEED_PROGRESS[`${country.id}.${t.id}.away`] || 0;
          const got = (h===2?1:0) + (a===2?1:0);
          const partial = (h===1) || (a===1);
          let mode = 'gray';
          if (got === 2) mode = 'color';
          else if (got === 1 || partial) mode = 'partial';
          const revealPct = mode==='partial' ? 60 : 0;
          return (
            <button key={t.id} onClick={() => onPick(t)} style={{
              background: '#FFFFFF', border: 'none', borderRadius: 24,
              boxShadow: '0 6px 18px rgba(80,50,20,0.08)',
              cursor: 'pointer', padding: 12, display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'space-between', gap: 6, position: 'relative',
              transition: 'transform 150ms'
            }}
            onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-3px)'}
            onMouseLeave={e => e.currentTarget.style.transform = ''}
            >
              <div style={{ position: 'absolute', top: 10, right: 10, padding: '3px 9px', background: got===2?'#7DDB8B':got===1?'#FFC93C':'#EBE3D2', borderRadius: 999, fontSize: 11, fontWeight: 900, color: got===0?'#7A4E1B':'#FFFFFF' }}>{got}/2</div>
              <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Shirt team={t} kit="home" size={110} mode={mode} revealPct={revealPct} idSuffix={t.id} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, paddingTop: 4 }}>
                <Crest crest={t.crest} size={22} />
                <div style={{ fontSize: 13, fontWeight: 900, color: '#3D2A1F', letterSpacing: '0.3px' }}>{t.short}</div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 4. DETALLE DE EQUIPO
// ──────────────────────────────────────────────────────
function TeamDetailScreen({ palette, country, team, onBack, onPick }) {
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <BackButton onClick={onBack} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <BigCrest crest={team.crest} size={70} />
          <div>
            <div style={{ fontSize: 38, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px', lineHeight: 1 }}>{team.name}</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
              <Flag country={country} w={32} h={22} rounded={4} />
              <div style={{ fontSize: 14, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1 }}>{country.name}</div>
            </div>
          </div>
        </div>
        <div style={{ width: 64 }} />
      </div>
      <div style={{ textAlign: 'center', fontSize: 22, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.5, margin: '12px 0' }}>ELIGE UNA CAMISETA PARA PINTAR</div>
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 28 }}>
        {[
          { kit: 'home', label: 'TITULAR', tag: '🏠' },
          { kit: 'away', label: 'SUPLENTE', tag: '✈️' },
        ].map(k => {
          const status = CAMI_DATA.SEED_PROGRESS[`${country.id}.${team.id}.${k.kit}`] || 0;
          return (
            <button key={k.kit} onClick={() => onPick(k.kit)} style={{
              background: '#FFFFFF', border: 'none', borderRadius: 32,
              boxShadow: '0 10px 28px rgba(80,50,20,0.12)',
              cursor: 'pointer', padding: 24, display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center', gap: 12, position: 'relative',
              transition: 'transform 150ms'
            }}
            onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-6px)'}
            onMouseLeave={e => e.currentTarget.style.transform = ''}
            >
              <div style={{ position: 'absolute', top: 20, left: 20, padding: '6px 14px', background: status===2?'#7DDB8B':'#FFE9C7', borderRadius: 999, fontSize: 13, fontWeight: 900, color: status===2?'#FFFFFF':'#7A4E1B', letterSpacing: 1.2 }}>
                {status===2?'✓ DESCUBIERTA':'POR DESCUBRIR'}
              </div>
              <Shirt team={team} kit={k.kit} size={240} mode={status===2?'color':'gray'} idSuffix={`${k.kit}d`} />
              <div style={{ fontSize: 30, fontWeight: 900, color: '#3D2A1F', letterSpacing: '0.5px', marginTop: 8 }}>{k.label}</div>
              <div style={{ padding: '10px 24px', background: '#FF7B3D', color: '#FFFFFF', borderRadius: 999, fontSize: 16, fontWeight: 900, letterSpacing: 1 }}>👆 PINTAR</div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 6. FICHA FINAL
// ──────────────────────────────────────────────────────
function FichaScreen({ palette, country, team, kit, onBack, onAlbum, onAnother, onRepaint }) {
  const colorNames = team[kit].c.map(hexToColorName).join(' Y ');
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '24px 36px', display: 'flex', flexDirection: 'column', position: 'relative', overflow: 'hidden' }}>
      <div style={{ position: 'absolute', top: -60, right: -60, width: 220, height: 220, borderRadius: '50%', background: '#FFE9C7', opacity: 0.5 }} />
      <div style={{ position: 'absolute', bottom: -80, left: -60, width: 260, height: 260, borderRadius: '50%', background: '#FFD7C0', opacity: 0.4 }} />

      <div style={{ display: 'flex', justifyContent: 'space-between', position: 'relative' }}>
        <BackButton onClick={onBack} />
        <div style={{ fontSize: 56, fontWeight: 900, color: '#FF7B3D', letterSpacing: '-1px' }}>¡MUY BIEN!</div>
        <div style={{ width: 64 }} />
      </div>
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 32, position: 'relative', alignItems: 'center' }}>
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <div style={{ background: '#FFFFFF', borderRadius: 40, padding: 32, boxShadow: '0 16px 48px rgba(80,50,20,0.14)', transform: 'rotate(-2deg)' }}>
            <Shirt team={team} kit={kit} size={320} mode="color" idSuffix="ficha" />
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <BigCrest crest={team.crest} size={84} />
            <div style={{ fontSize: 40, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px', lineHeight: 1 }}>{team.name}</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 18px', background: '#FFFFFF', borderRadius: 24, alignSelf: 'flex-start', boxShadow: '0 4px 12px rgba(80,50,20,0.08)' }}>
            <Flag country={country} w={42} h={28} rounded={6} />
            <div style={{ fontSize: 20, fontWeight: 800, color: '#3D2A1F', letterSpacing: 0.5 }}>{country.name}</div>
          </div>
          <div style={{ padding: '14px 20px', background: '#FFE9C7', borderRadius: 24, alignSelf: 'flex-start' }}>
            <div style={{ fontSize: 13, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.2, marginBottom: 4 }}>COLORES</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              {team[kit].c.slice(0,2).map((c, i) => (
                <div key={i} style={{ width: 28, height: 28, borderRadius: 14, background: c, border: '2px solid white', boxShadow: '0 2px 6px rgba(0,0,0,0.15)' }} />
              ))}
              <div style={{ fontSize: 18, fontWeight: 900, color: '#3D2A1F', letterSpacing: 0.5 }}>{colorNames}</div>
            </div>
          </div>
          <div style={{ padding: '12px 20px', background: '#FFFFFF', borderRadius: 24, alignSelf: 'flex-start', boxShadow: '0 4px 12px rgba(80,50,20,0.08)' }}>
            <div style={{ fontSize: 13, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.2, marginBottom: 4 }}>{kit==='home'?'TITULAR':'SUPLENTE'}</div>
            <div style={{ fontSize: 18, fontWeight: 900, color: '#3D2A1F' }}>+1 SUMADA AL ÁLBUM</div>
          </div>
          <div style={{ display: 'flex', gap: 12, marginTop: 12, flexWrap: 'wrap' }}>
            <BigKidButton variant="primary" size="md" onClick={onAnother}>OTRA →</BigKidButton>
            <BigKidButton variant="grass" size="md" icon="📒" onClick={onAlbum}>ÁLBUM</BigKidButton>
            <BigKidButton variant="secondary" size="md" icon="🔄" onClick={onRepaint}>REPINTAR</BigKidButton>
          </div>
        </div>
      </div>
    </div>
  );
}

function hexToColorName(hex) {
  const map = {
    '#FFFFFF': 'BLANCO', '#0A2A6C': 'AZUL', '#FFD700': 'AMARILLO', '#E2272F': 'ROJO',
    '#FFE600': 'AMARILLO', '#1A1A1A': 'NEGRO', '#74ACDF': 'CELESTE', '#C8102E': 'ROJO',
    '#A50044': 'GRANATE', '#004D98': 'AZUL', '#FEBE10': 'DORADO', '#CB3524': 'ROJO',
    '#EE2523': 'ROJO', '#0067B1': 'AZUL', '#D9001A': 'ROJO', '#F18E00': 'NARANJA',
    '#005EB8': 'AZUL', '#0BB363': 'VERDE', '#6CABDD': 'CELESTE', '#DA291C': 'ROJO',
    '#EF0107': 'ROJO', '#034694': 'AZUL', '#7A003C': 'GRANATE', '#86C5FF': 'CELESTE',
    '#1BB1E7': 'CELESTE', '#003399': 'AZUL', '#12A0D7': 'CELESTE', '#8E1F2F': 'GRANATE',
    '#F2A93B': 'DORADO', '#87CEEB': 'CELESTE', '#5B2D88': 'VIOLETA', '#2FAEE0': 'CELESTE',
    '#DC052D': 'ROJO', '#0066B2': 'AZUL', '#FDE100': 'AMARILLO', '#E32219': 'ROJO',
    '#DD0741': 'ROJO', '#65B32E': 'VERDE', '#1D9053': 'VERDE', '#CE1124': 'ROJO',
    '#7FE3D9': 'TURQUESA', '#FCBF49': 'DORADO',
  };
  return map[hex] || 'COLOR';
}

// ──────────────────────────────────────────────────────
// 7. ÁLBUM
// ──────────────────────────────────────────────────────
function AlbumScreen({ palette, onBack }) {
  const [filter, setFilter] = React.useState('all');
  const all = [];
  CAMI_DATA.COUNTRIES.forEach(c => {
    (CAMI_DATA.TEAMS[c.id] || []).forEach(t => {
      ['home', 'away'].forEach(k => {
        const status = CAMI_DATA.SEED_PROGRESS[`${c.id}.${t.id}.${k}`] || 0;
        all.push({ country: c, team: t, kit: k, status });
      });
    });
  });
  const filtered = filter === 'all' ? all : all.filter(x => x.country.id === filter);
  const got = all.filter(x => x.status === 2).length;

  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 12px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <BackButton onClick={onBack} />
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 18 }}>
          <div style={{ fontSize: 44, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>MI ÁLBUM</div>
          <div style={{ padding: '6px 16px', background: '#7DDB8B', borderRadius: 999, fontSize: 18, fontWeight: 900, color: '#FFFFFF' }}>{got} / {all.length}</div>
        </div>
        <div style={{ width: 64 }} />
      </div>

      <div style={{ display: 'flex', gap: 10, marginBottom: 12, flexWrap: 'wrap' }}>
        <button onClick={() => setFilter('all')} style={{ padding: '10px 18px', borderRadius: 999, border: 'none', background: filter==='all'?'#FF7B3D':'#FFFFFF', color: filter==='all'?'#FFFFFF':'#3D2A1F', fontWeight: 900, fontSize: 14, letterSpacing: 1, cursor: 'pointer', boxShadow: '0 4px 10px rgba(80,50,20,0.08)' }}>TODAS</button>
        {CAMI_DATA.COUNTRIES.map(c => (
          <button key={c.id} onClick={() => setFilter(c.id)} style={{ padding: '8px 14px', borderRadius: 999, border: 'none', background: filter===c.id?'#FF7B3D':'#FFFFFF', display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', boxShadow: '0 4px 10px rgba(80,50,20,0.08)' }}>
            <Flag country={c} w={28} h={20} rounded={4} />
            <span style={{ fontSize: 13, fontWeight: 900, color: filter===c.id?'#FFFFFF':'#3D2A1F', letterSpacing: 0.8 }}>{c.name}</span>
          </button>
        ))}
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: '#FFFFFF', borderRadius: 24, padding: 18, boxShadow: 'inset 0 2px 8px rgba(80,50,20,0.06)' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: 12 }}>
          {filtered.map((x, i) => {
            const mode = x.status === 2 ? 'color' : x.status === 1 ? 'partial' : 'gray';
            return (
              <div key={i} style={{ background: '#FFF7EC', borderRadius: 14, padding: 8, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, border: x.status===2?'2px solid #7DDB8B':'2px dashed #EBE3D2' }}>
                <Shirt team={x.team} kit={x.kit} size={70} mode={mode} revealPct={50} idSuffix={`alb${i}`} />
                <div style={{ fontSize: 9, fontWeight: 900, color: x.status===0?'#A89580':'#3D2A1F', letterSpacing: 0.4, textAlign: 'center', lineHeight: 1.1 }}>{x.team.short}</div>
                <div style={{ fontSize: 8, fontWeight: 700, color: '#7A4E1B', letterSpacing: 0.6 }}>{x.kit==='home'?'TITULAR':'SUPLENTE'}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 8. JUEGOS
// ──────────────────────────────────────────────────────
function GamesScreen({ palette, onBack, onPlay }) {
  const games = [
    { id: 'paint', title: 'PINTAR', sub: 'DESCUBRE LA CAMISETA', color: '#FF7B3D', icon: '🎨' },
    { id: 'guess', title: 'ADIVINAR', sub: '¿CUÁL ES?', color: '#6BCBFF', icon: '❓' },
    { id: 'memory', title: 'MEMORIA', sub: 'BUSCA LOS PARES', color: '#7DDB8B', icon: '🃏' },
  ];
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 24 }}>
        <BackButton onClick={onBack} />
        <div style={{ fontSize: 44, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>JUGAR</div>
      </div>
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24 }}>
        {games.map(g => (
          <button key={g.id} onClick={() => onPlay(g.id)} style={{
            background: '#FFFFFF', border: 'none', borderRadius: 32,
            boxShadow: `0 12px 32px rgba(80,50,20,0.12), 0 4px 0 ${g.color}`,
            cursor: 'pointer', padding: 28, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center', gap: 16, position: 'relative',
            transition: 'transform 150ms'
          }}
          onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-6px)'}
          onMouseLeave={e => e.currentTarget.style.transform = ''}
          >
            <div style={{ width: 140, height: 140, borderRadius: 70, background: g.color + '22', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 80 }}>
              {g.icon}
            </div>
            <div style={{ fontSize: 32, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-0.5px' }}>{g.title}</div>
            <div style={{ fontSize: 16, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.2 }}>{g.sub}</div>
            <div style={{ marginTop: 8, padding: '10px 20px', background: g.color, color: '#FFFFFF', borderRadius: 999, fontSize: 16, fontWeight: 900, letterSpacing: 1 }}>JUGAR ▶</div>
          </button>
        ))}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 9. ADIVINAR
// ──────────────────────────────────────────────────────
function GuessScreen({ palette, onBack }) {
  const correct = CAMI_DATA.TEAMS.arg[0]; // Boca
  const wrong = CAMI_DATA.TEAMS.arg[1]; // River
  const [picked, setPicked] = React.useState(null);
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <BackButton onClick={onBack} />
        <div style={{ fontSize: 44, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>¿CUÁL ES?</div>
        <ProgressStars count={2} total={5} size={28} />
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '0 0 12px' }}>
        <div style={{ background: '#FFFFFF', borderRadius: 32, padding: 24, boxShadow: '0 12px 32px rgba(80,50,20,0.10)' }}>
          <Shirt team={correct} kit="home" size={220} mode="partial" revealPct={45} idSuffix="guess" />
        </div>
        <div style={{ display: 'flex', gap: 32 }}>
          {[correct, wrong].map((t, i) => {
            const isCorrect = t.id === correct.id;
            const isPicked = picked === t.id;
            const reveal = picked !== null;
            return (
              <button key={t.id} onClick={() => setPicked(t.id)} disabled={picked!==null} style={{
                background: '#FFFFFF', border: 'none', borderRadius: 28,
                boxShadow: reveal && isPicked ? (isCorrect?'0 0 0 6px #7DDB8B, 0 12px 28px rgba(0,0,0,0.1)':'0 0 0 6px #FF7B6B, 0 12px 28px rgba(0,0,0,0.1)') : '0 8px 22px rgba(80,50,20,0.12)',
                cursor: picked===null?'pointer':'default', padding: 18,
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
                minWidth: 240, transition: 'all 200ms',
                animation: reveal && isPicked && !isCorrect ? 'shake 400ms' : 'none'
              }}>
                <Crest crest={t.crest} size={56} />
                <Shirt team={t} kit="home" size={100} mode={reveal?'color':'gray'} idSuffix={`opt${i}`} />
                <div style={{ fontSize: 22, fontWeight: 900, color: '#3D2A1F', letterSpacing: '0.5px' }}>{t.short}</div>
                {reveal && isPicked && (
                  <div style={{ fontSize: 36 }}>{isCorrect?'⭐':'🔁'}</div>
                )}
              </button>
            );
          })}
        </div>
      </div>
      <style>{`@keyframes shake{0%,100%{transform:translateX(0)}25%{transform:translateX(-8px)}75%{transform:translateX(8px)}}`}</style>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 10. MEMORIA
// ──────────────────────────────────────────────────────
function MemoryScreen({ palette, onBack }) {
  const teams = [CAMI_DATA.TEAMS.arg[0], CAMI_DATA.TEAMS.esp[1], CAMI_DATA.TEAMS.eng[2]];
  // 6 cards: 3 pairs (shirt + crest)
  const cards = [
    { id: 0, kind: 'shirt', team: teams[0] },
    { id: 1, kind: 'crest', team: teams[0] },
    { id: 2, kind: 'shirt', team: teams[1] },
    { id: 3, kind: 'crest', team: teams[1] },
    { id: 4, kind: 'shirt', team: teams[2] },
    { id: 5, kind: 'crest', team: teams[2] },
  ];
  // Demo state: card 0 and 1 matched, 2 flipped
  const flipped = new Set([0, 1, 2]);
  const matched = new Set([0, 1]);
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <BackButton onClick={onBack} />
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 40, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>MEMORIA</div>
          <div style={{ fontSize: 16, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.5 }}>BUSCA LOS PARES</div>
        </div>
        <ProgressStars count={1} total={3} size={28} />
      </div>
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gridTemplateRows: 'repeat(2, 1fr)', gap: 16 }}>
        {cards.map(card => {
          const isFlipped = flipped.has(card.id);
          const isMatched = matched.has(card.id);
          return (
            <div key={card.id} style={{
              background: isFlipped ? '#FFFFFF' : '#FF7B3D',
              borderRadius: 24,
              boxShadow: isMatched ? '0 0 0 4px #7DDB8B, 0 8px 22px rgba(80,50,20,0.10)' : '0 8px 22px rgba(80,50,20,0.10)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'all 300ms',
            }}>
              {isFlipped ? (
                card.kind === 'shirt'
                  ? <Shirt team={card.team} kit="home" size={130} mode="color" idSuffix={`m${card.id}`} />
                  : <Crest crest={card.team.crest} size={110} />
              ) : (
                <div style={{ fontSize: 64, color: '#FFFFFF', fontWeight: 900, opacity: 0.6 }}>?</div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────
// 11. PREMIOS
// ──────────────────────────────────────────────────────
function RewardsScreen({ palette, onBack }) {
  return (
    <div style={{ width: '100%', height: '100%', background: palette.bg, padding: '20px 28px 28px', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 16 }}>
        <BackButton onClick={onBack} />
        <div style={{ fontSize: 44, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-1px' }}>PREMIOS</div>
      </div>

      {/* Stars big card */}
      <div style={{ background: 'linear-gradient(135deg, #FFC93C, #FF9F40)', borderRadius: 32, padding: 28, marginBottom: 20, display: 'flex', alignItems: 'center', justifyContent: 'space-between', boxShadow: '0 12px 32px rgba(232,159,0,0.3)' }}>
        <div>
          <div style={{ fontSize: 16, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.5 }}>TUS ESTRELLAS</div>
          <div style={{ fontSize: 72, fontWeight: 900, color: '#3D2A1F', letterSpacing: '-2px', lineHeight: 1 }}>12 ⭐</div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {[1,2,3,4,5].map(i => <div key={i} style={{ fontSize: 48 + i*4, transform: `rotate(${(i-3)*8}deg)` }}>⭐</div>)}
        </div>
      </div>

      {/* Trophies + stickers grid */}
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        {[
          { type: 'trophy', label: 'ARGENTINA', got: true, country: CAMI_DATA.COUNTRIES[0] },
          { type: 'trophy', label: 'ESPAÑA', got: true, country: CAMI_DATA.COUNTRIES[2] },
          { type: 'trophy', label: 'INGLATERRA', got: false, country: CAMI_DATA.COUNTRIES[1] },
          { type: 'trophy', label: 'ITALIA', got: false, country: CAMI_DATA.COUNTRIES[3] },
          { type: 'sticker', team: CAMI_DATA.TEAMS.arg[0], label: '¡NUEVO!' },
          { type: 'sticker', team: CAMI_DATA.TEAMS.esp[1], label: '¡NUEVO!' },
          { type: 'sticker', team: CAMI_DATA.TEAMS.eng[2] },
          { type: 'sticker', team: CAMI_DATA.TEAMS.ger[0] },
        ].map((r, i) => (
          <div key={i} style={{ background: '#FFFFFF', borderRadius: 24, padding: 18, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8, boxShadow: '0 8px 22px rgba(80,50,20,0.08)', position: 'relative', opacity: r.got===false?0.5:1 }}>
            {r.label==='¡NUEVO!' && <div style={{ position: 'absolute', top: 8, right: 8, padding: '3px 8px', background: '#FF7B3D', color: '#FFFFFF', borderRadius: 999, fontSize: 9, fontWeight: 900, letterSpacing: 0.8 }}>¡NUEVO!</div>}
            {r.type === 'trophy' ? (
              <>
                <div style={{ fontSize: 64, filter: r.got?'none':'grayscale(1)' }}>🏆</div>
                <Flag country={r.country} w={56} h={38} rounded={6} />
                <div style={{ fontSize: 14, fontWeight: 900, color: '#3D2A1F', letterSpacing: 0.5 }}>{r.label}</div>
              </>
            ) : (
              <>
                <Shirt team={r.team} kit="home" size={90} mode="color" idSuffix={`r${i}`} />
                <div style={{ fontSize: 13, fontWeight: 900, color: '#3D2A1F', letterSpacing: 0.5 }}>{r.team.short}</div>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { BackButton, BigKidButton, ProgressStars, HomeScreen, CountriesScreen, TeamsScreen, TeamDetailScreen, FichaScreen, AlbumScreen, GamesScreen, GuessScreen, MemoryScreen, RewardsScreen });

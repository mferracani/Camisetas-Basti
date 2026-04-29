// PaintScreen — la pantalla más importante.
// Canvas overlay sobre la camiseta; el dedo borra el "rasguño" gris para revelar.

function PaintScreen({ team, kit, onDone, onBack, revealSpeed = 1, palette }) {
  const containerRef = React.useRef(null);
  const canvasRef = React.useRef(null);
  const [pct, setPct] = React.useState(0);
  const [done, setDone] = React.useState(false);
  const [showHelp, setShowHelp] = React.useState(false);
  const [confetti, setConfetti] = React.useState(false);
  const drawingRef = React.useRef(false);
  const lastPtRef = React.useRef(null);

  const SHIRT_DISPLAY = 460; // px

  // Initialize canvas: fill with gray "scratch" layer.
  React.useEffect(() => {
    const c = canvasRef.current;
    if (!c) return;
    const dpr = window.devicePixelRatio || 1;
    c.width = SHIRT_DISPLAY * dpr;
    c.height = (SHIRT_DISPLAY * 280 / 240) * dpr;
    c.style.width = SHIRT_DISPLAY + 'px';
    c.style.height = (SHIRT_DISPLAY * 280 / 240) + 'px';
    const ctx = c.getContext('2d');
    ctx.scale(dpr, dpr);
    // Gray scratch
    ctx.fillStyle = '#D9D5CE';
    ctx.fillRect(0, 0, c.width, c.height);
    // Light texture
    for (let i = 0; i < 200; i++) {
      ctx.fillStyle = `rgba(255,255,255,${Math.random() * 0.08})`;
      ctx.fillRect(Math.random() * SHIRT_DISPLAY, Math.random() * SHIRT_DISPLAY * 280/240, 2, 2);
    }
    // Hint texture: a "?" in faint
    ctx.fillStyle = 'rgba(0,0,0,0.08)';
    ctx.font = 'bold 110px system-ui';
    ctx.textAlign = 'center';
    ctx.fillText('?', SHIRT_DISPLAY/2, SHIRT_DISPLAY*280/240/2 + 30);
  }, [team?.id, kit]);

  const computeRevealPct = () => {
    const c = canvasRef.current;
    if (!c) return 0;
    const ctx = c.getContext('2d');
    const w = c.width, h = c.height;
    const data = ctx.getImageData(0, 0, w, h).data;
    let cleared = 0, total = 0;
    // Sample stride for perf
    const stride = 8;
    for (let i = 0; i < data.length; i += 4 * stride) {
      total++;
      if (data[i + 3] < 100) cleared++;
    }
    return Math.round((cleared / total) * 100);
  };

  const erase = (x, y) => {
    const c = canvasRef.current;
    if (!c) return;
    const ctx = c.getContext('2d');
    ctx.globalCompositeOperation = 'destination-out';
    const radius = 36 * revealSpeed;

    if (lastPtRef.current) {
      const lp = lastPtRef.current;
      // Draw a smooth line of erase circles
      const dx = x - lp.x, dy = y - lp.y;
      const dist = Math.sqrt(dx*dx + dy*dy);
      const steps = Math.max(1, Math.floor(dist / 6));
      for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const px = lp.x + dx * t, py = lp.y + dy * t;
        ctx.beginPath();
        ctx.arc(px, py, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    } else {
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.fill();
    }
    lastPtRef.current = { x, y };
  };

  const getPos = (e) => {
    const c = canvasRef.current;
    const rect = c.getBoundingClientRect();
    const t = e.touches ? e.touches[0] : e;
    return {
      x: (t.clientX - rect.left),
      y: (t.clientY - rect.top),
    };
  };

  const onStart = (e) => {
    e.preventDefault();
    if (done) return;
    drawingRef.current = true;
    lastPtRef.current = null;
    const p = getPos(e);
    erase(p.x, p.y);
  };
  const onMove = (e) => {
    if (!drawingRef.current || done) return;
    e.preventDefault();
    const p = getPos(e);
    erase(p.x, p.y);
  };
  const onEnd = () => {
    drawingRef.current = false;
    lastPtRef.current = null;
    const p = computeRevealPct();
    setPct(p);
    if (p >= 85 && !done) {
      setDone(true);
      setConfetti(true);
      setTimeout(() => setConfetti(false), 2500);
      // Auto-clear remaining after a moment
      setTimeout(() => {
        const c = canvasRef.current;
        if (!c) return;
        const ctx = c.getContext('2d');
        ctx.clearRect(0, 0, c.width, c.height);
        setPct(100);
      }, 600);
    }
  };

  // Stars: 5 dots, fill based on pct in 20% increments
  const stars = Math.min(5, Math.floor(pct / 20));

  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', background: palette.bg, position: 'relative', overflow: 'hidden' }}>
      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 28px' }}>
        <BackButton onClick={onBack} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <BigCrest crest={team.crest} size={44} />
          <div style={{ fontSize: 26, fontWeight: 800, color: '#3D2A1F', letterSpacing: '-0.5px' }}>{team.name}</div>
          <div style={{ padding: '6px 14px', background: '#FFE9C7', borderRadius: 999, fontSize: 14, fontWeight: 800, color: '#7A4E1B', letterSpacing: 1.2 }}>
            {kit === 'home' ? 'TITULAR' : 'SUPLENTE'}
          </div>
        </div>
        <button onClick={() => setShowHelp(!showHelp)} style={{ width: 64, height: 64, borderRadius: 32, border: 'none', background: '#FFFFFF', boxShadow: '0 4px 12px rgba(80,50,20,0.10)', fontSize: 28, fontWeight: 900, color: '#7A4E1B', cursor: 'pointer' }}>?</button>
      </div>

      {/* Big PINTA label */}
      <div style={{ textAlign: 'center', marginTop: 4 }}>
        <div style={{ fontSize: 56, fontWeight: 900, color: '#3D2A1F', letterSpacing: '2px', lineHeight: 1 }}>
          {done ? '¡MUY BIEN!' : 'PINTA'}
        </div>
      </div>

      {/* Shirt area */}
      <div ref={containerRef} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
        <div style={{ position: 'relative', width: SHIRT_DISPLAY, height: SHIRT_DISPLAY * 280/240, transform: done ? 'scale(1.05)' : 'scale(1)', transition: 'transform 600ms cubic-bezier(.2,1.4,.4,1)' }}>
          {/* Real shirt underneath */}
          <div style={{ position: 'absolute', inset: 0 }}>
            <Shirt team={team} kit={kit} size={SHIRT_DISPLAY} mode="color" />
          </div>
          {/* Canvas scratch overlay, clipped to shirt path */}
          <svg width={SHIRT_DISPLAY} height={SHIRT_DISPLAY * 280/240} viewBox="0 0 240 280" style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
            <defs>
              <clipPath id="paint-clip">
                <path d="M 60 28 L 92 14 C 100 30 140 30 148 14 L 180 28 L 220 56 L 200 96 L 178 86 L 178 252 C 178 262 172 268 162 268 L 78 268 C 68 268 62 262 62 252 L 62 86 L 40 96 L 20 56 Z" />
              </clipPath>
            </defs>
          </svg>
          <div style={{ position: 'absolute', inset: 0, clipPath: "path('M 115 28 L 175 0 C 188 32 268 32 285 0 L 345 28 L 422 56 L 384 96 L 343 86 L 343 484 C 343 502 332 514 312 514 L 152 514 C 132 514 119 502 119 484 L 119 86 L 79 96 L 40 56 Z')" }}>
            <canvas
              ref={canvasRef}
              onMouseDown={onStart}
              onMouseMove={onMove}
              onMouseUp={onEnd}
              onMouseLeave={onEnd}
              onTouchStart={onStart}
              onTouchMove={onMove}
              onTouchEnd={onEnd}
              style={{ display: 'block', cursor: 'crosshair', touchAction: 'none' }}
            />
          </div>

          {/* Ghost finger hint when no progress */}
          {pct < 5 && !done && (
            <div style={{ position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)', fontSize: 80, animation: 'ghostmove 2s ease-in-out infinite', pointerEvents: 'none' }}>
              👆
            </div>
          )}
        </div>
      </div>

      {/* Stars */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: 14, padding: '16px 0 32px' }}>
        {[0,1,2,3,4].map(i => (
          <div key={i} style={{
            width: 44, height: 44, borderRadius: 22,
            background: i < stars ? '#FFC93C' : '#FFFFFF',
            border: i < stars ? '3px solid #E89F00' : '3px solid #EBE3D2',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 24, transform: i < stars ? 'scale(1)' : 'scale(0.85)',
            transition: 'all 300ms cubic-bezier(.2,1.5,.4,1)',
            boxShadow: i < stars ? '0 4px 12px rgba(232,159,0,0.3)' : 'none'
          }}>
            {i < stars ? '⭐' : ''}
          </div>
        ))}
      </div>

      {done && (
        <div style={{ position: 'absolute', bottom: 32, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 16 }}>
          <BigKidButton onClick={onDone} variant="primary">VER FICHA →</BigKidButton>
        </div>
      )}

      {confetti && <Confetti />}
      {showHelp && <HelpOverlay onClose={() => setShowHelp(false)} />}

      <style>{`
        @keyframes ghostmove {
          0%, 100% { transform: translate(-50%, -50%) rotate(-15deg); }
          50% { transform: translate(-30%, -40%) rotate(10deg); }
        }
      `}</style>
    </div>
  );
}

function Confetti() {
  const pieces = React.useMemo(() => Array.from({ length: 60 }, (_, i) => ({
    left: Math.random() * 100,
    delay: Math.random() * 0.4,
    duration: 1.5 + Math.random() * 1,
    color: ['#FFC93C', '#FF7B6B', '#6BCBFF', '#7DDB8B', '#C77DFF'][i % 5],
    rot: Math.random() * 360,
    size: 8 + Math.random() * 8,
  })), []);
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden' }}>
      {pieces.map((p, i) => (
        <div key={i} style={{
          position: 'absolute',
          left: p.left + '%', top: -20,
          width: p.size, height: p.size, background: p.color,
          borderRadius: i % 3 === 0 ? '50%' : 2,
          animation: `confetti-fall ${p.duration}s ease-in ${p.delay}s forwards`,
          transform: `rotate(${p.rot}deg)`,
        }} />
      ))}
      <style>{`
        @keyframes confetti-fall {
          to { transform: translateY(700px) rotate(720deg); opacity: 0; }
        }
      `}</style>
    </div>
  );
}

function HelpOverlay({ onClose }) {
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, background: 'rgba(40,30,20,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
      <div style={{ background: '#FFF7EC', borderRadius: 32, padding: 40, maxWidth: 500, textAlign: 'center', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
        <div style={{ fontSize: 64, marginBottom: 16 }}>👆</div>
        <div style={{ fontSize: 28, fontWeight: 900, color: '#3D2A1F', marginBottom: 12 }}>PASA EL DEDO</div>
        <div style={{ fontSize: 18, color: '#7A4E1B', lineHeight: 1.4 }}>POR LA CAMISETA<br/>PARA DESCUBRIRLA</div>
      </div>
    </div>
  );
}

Object.assign(window, { PaintScreen });

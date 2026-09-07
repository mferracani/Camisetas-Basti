# Agent Kit — Camisetas Basti

> Framework multi-agente para construir la app **Camisetas Basti**: iOS/macOS nativa (SwiftUI), offline-first, para niños de 4 años.

Este proyecto usa un framework de **3 Gates y 6 Agentes**. Cada agente tiene un rol definido, no se saltan gates, y todos leen/escriben `.project/state.md` como fuente de verdad.

---

## 3 Gates

| Gate | Requisito | Owner | Output |
|---|---|---|---|
| 1 | PRD | Product Manager | `PRD.md` |
| 2 | UX Spec | UX Designer | `.project/ux-spec.md` |
| 3 | Build (Local Data → SwiftUI → Security → QA) | Secuencia de agentes | código + specs/tests |

El estado y las aprobaciones vigentes de cada gate se consultan en
`.project/state.md`.

## 6 Agentes

| # | Agente | Cuándo entra | Output principal |
|---|--------|-------------|------------------|
| 1 | **Product Manager** | Validar decisiones, cambios de alcance | Decisiones en `state.md` |
| 2 | **UX Designer** | Después de PRD aprobado | `.project/ux-spec.md` |
| 3 | **Local Data Designer** | Después de UX aprobado | `.project/backend-spec.md` |
| 4 | **SwiftUI Engineer** | Después de contrato de datos | Vistas Swift + lógica |
| 5 | **Security Reviewer** | Post backend-spec y pre-merge | `.project/security-review.md` |
| 6 | **QA Engineer** | Final de cada fase | Tests + `.project/qa-checklist.md` |

## Stack del proyecto

- **Plataforma:** iOS 16+, iPadOS 16+, macOS 13+
- **Framework:** Swift nativo, SwiftUI (UIKit donde haga falta)
- **Persistencia:** UserDefaults Codable (local, offline)
- **Sonidos:** AVAudioPlayer con archivos .m4a embebidos
- **Assets:** Vectores nativos Swift (Shapes/Path), fuente Nunito local
- **Sin backend remoto, sin auth, sin login, sin analytics, sin ads.**

## Cómo usar los agentes

### En Claude Code
Invocá por nombre con `@`:
```
@product-manager — revisar alcance de feature X
@ux-designer — generar ux-spec.md desde PRD.md
@backend-designer — definir modelo de datos local
@swiftui-engineer — implementar PaintView
@security-reviewer — auditar privacidad infantil
@qa-engineer — generar tests y checklist
```

Los archivos de agentes viven en `.claude/agents/*.md`.

### En Cursor
Pedí en el chat:
```
"Actuá como el UX Designer del kit y generá el ux-spec.md"
"Actuá como el SwiftUI Engineer del kit e implementá la PaintView"
```

Los rules viven en `.cursor/rules/*.mdc`.

### Manual (cualquier otro tool)
Leé el archivo del agente que necesites en `.claude/agents/` y seguí su system prompt.

---

## Reglas globales (válidas para todos)

1. **Leer state antes de actuar.** Siempre. `.project/state.md` es la fuente de verdad.
2. **No saltar gates.** Si el usuario pide algo de una fase posterior sin cerrar la anterior, avisá y ofrecé cerrar la actual primero.
3. **Handoffs explícitos.** Dejá documentado qué rol corresponde actuar después.
4. **Sin drift de rol.** PM no escribe código. SwiftUI Engineer no diseña pantallas.
5. **State es verdad.** Si hay contradicción entre el state y tu memoria, gana el state.
6. **Aprobación viene del usuario.** Ningún agente se auto-aprueba.

Las aprobaciones registradas se reutilizan dentro del alcance que cubren. Si una
tarea solicita completar varias etapas y los gates aplicables están aprobados,
continuá dentro de ese alcance y dejá el handoff documentado. El handoff no exige
una nueva invocación del usuario; no crear subagentes sin autorización aplicable.

---

## Archivos del proyecto

```
.
├── AGENTS.md                          ← este archivo (índice)
├── PRD.md                             ← especificación completa
├── README.md                          ← guía de implementación
├── .project/
│   └── state.md                       ← estado actual del proyecto
├── .claude/agents/                    ← agentes para Claude Code
│   ├── product-manager.md
│   ├── ux-designer.md
│   ├── backend-designer.md
│   ├── swiftui-engineer.md
│   ├── security-reviewer.md
│   └── qa-engineer.md
├── .cursor/rules/                     ← rules para Cursor
│   ├── 00-framework.mdc
│   ├── 01-product-manager.mdc
│   ├── 02-ux-designer.mdc
│   ├── 03-backend-designer.mdc
│   ├── 04-frontend-engineer.mdc
│   ├── 05-security-reviewer.mdc
│   └── 06-qa-engineer.mdc
└── DISEÑO CAMISETAS/                  ← prototipo original
    ├── screens.jsx
    ├── paint-screen.jsx
    ├── shirts.jsx
    ├── data.jsx
    └── ...
```

## Estado y siguiente acción

Consultar `.project/state.md` para el estado vigente y la siguiente acción. Este
`AGENTS.md` define el proceso y los requisitos de aprobación; este índice no duplica
el estado de las fases. Reutilizar las aprobaciones registradas dentro de su
alcance. Si falta procedencia de una aprobación necesaria para la acción actual,
buscar primero la decisión o evidencia asociada.

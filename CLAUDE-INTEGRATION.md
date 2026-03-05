# CLAUDE-INTEGRATION.md
# Instrucciones para integrar el SDD Custom Kit en CLAUDE.md

Este archivo contiene el bloque de configuración que debe agregarse al CLAUDE.md
del usuario (global o de proyecto) para activar el SDD Custom Kit.

---

## BLOQUE A AGREGAR EN CLAUDE.md

Copiar el contenido entre las líneas de separación:

---

```markdown
## SDD Custom Kit — Orchestrator

Eres el orquestador del SDD Custom Kit. Coordinas el workflow SDD lanzando sub-agentes
especializados vía el Task tool. Tu trabajo es mantenerte liviano — delegar todo el
trabajo pesado a los sub-agentes y solo trackear estado y decisiones del usuario.

### Directorio base del kit
~/.claude/skills/custom-sdd-kit/

### Reglas del orquestador
1. NUNCA leas código fuente directamente — los sub-agentes hacen eso
2. NUNCA escribas código de implementación — los sub-agentes hacen eso
3. NUNCA escribas specs/proposals/design — los sub-agentes hacen eso
4. SOLO: trackear estado, presentar resúmenes, pedir aprobación, lanzar sub-agentes
5. Lee el protocolo de invocación: ~/.claude/skills/custom-sdd-kit/_shared/agent-invocation-protocol.md

### Triggers SDD
- `/sdd.init` → sdd-explorer (detecta stack, crea PROJECT.md)
- `/sdd.new <nombre>` → sdd-explorer → sdd-proposer
- `/sdd.ff [slug]` → sdd-spec-writer(func) → sdd-designer → sdd-spec-writer(tech) → sdd-task-planner
- `/sdd.spec [slug]` → sdd-spec-writer
- `/sdd.design [slug]` → sdd-designer
- `/sdd.plan [slug]` → sdd-task-planner
- `/sdd.build [slug]` → sdd-implementer + gates opcionales + sdd-tdd-runner
- `/sdd.verify [slug]` → sdd-tdd-runner → sdd-verifier
- `/sdd.git [slug]` → sdd-code-reviewer → sdd-security-scanner → sdd-git-manager
- `/sdd.finish [slug]` → flujo completo: verify + git + archive
- `/sdd.go <nombre>` → todo en secuencia express (sin pausa)
- `/sdd.check [slug]` → sdd-checker
- `/sdd.fix [slug] <desc>` → sdd-debugger
- `/sdd.reverse-eng [path]` → sdd-reverse-engineer
- `/sdd.backlog [add|list|done|remove]` → sdd-backlog-manager
- `/sdd.compact` → sdd-context-compactor
- `/sdd.archive [slug]` → sdd-archiver
- `/sdd.list` → inline (orquestador lee sdd/wip/ y sdd/features/ directamente)
- `/sdd.cancel [slug]` → inline (orquestador actualiza meta.md)
- `/sdd.rollback [slug]` → inline (orquestador ejecuta git operations)
- `/sdd.help [comando]` → inline (orquestador muestra ayuda)

### Expert mode
Agregar `--expert` a cualquier comando escala el modelo del agente.
NO disponible en /sdd.go (modo express).

### Artefactos: siempre en archivos
Todos los artefactos SDD se escriben en sdd/ del proyecto.
No hay modo engram-only ni none. La persistencia en archivos es mandatoria.
```

---

## INSTALACIÓN

### Opción A: Global (todos los proyectos)

Agregar el bloque al final de `~/.claude/CLAUDE.md`.

El kit estará disponible en cualquier proyecto donde abras Claude Code.

### Opción B: Por proyecto

Agregar el bloque al `CLAUDE.md` en la raíz del proyecto específico.

---

## VERIFICACIÓN

Después de agregar el bloque, verificar que el kit funciona:

```
/sdd.help
```

Deberías ver la tabla de comandos disponibles.

```
/sdd.init
```

Deberías ver el agente sdd-explorer analizando el proyecto.

---

## ESTRUCTURA DE ARCHIVOS DEL KIT

```
~/.claude/skills/custom-sdd-kit/
├── CLAUDE-INTEGRATION.md        ← Este archivo
├── README.md                    ← Documentación del kit
│
├── _shared/                     ← Contratos compartidos (L1)
│   ├── persistence-contract.md
│   ├── directory-convention.md
│   ├── conventional-commits.md
│   ├── quality-gates-protocol.md
│   └── agent-invocation-protocol.md
│
├── agents/                      ← Specs de sub-agentes (L2-L6)
│   ├── sdd-explorer.md
│   ├── sdd-proposer.md
│   ├── sdd-spec-writer.md
│   ├── sdd-designer.md
│   ├── sdd-task-planner.md
│   ├── sdd-implementer.md
│   ├── sdd-tdd-runner.md
│   ├── sdd-code-reviewer.md
│   ├── sdd-security-scanner.md
│   ├── sdd-verifier.md
│   ├── sdd-checker.md
│   ├── sdd-git-manager.md
│   ├── sdd-archiver.md
│   ├── sdd-debugger.md
│   ├── sdd-reverse-engineer.md
│   ├── sdd-backlog-manager.md
│   └── sdd-context-compactor.md
│
└── skills/                      ← Routing skills (L7)
    ├── sdd.init.md
    ├── sdd.new.md
    ├── sdd.ff.md
    ├── sdd.spec.md
    ├── sdd.design.md
    ├── sdd.plan.md
    ├── sdd.build.md
    ├── sdd.verify.md
    ├── sdd.git.md
    ├── sdd.finish.md
    ├── sdd.go.md
    ├── sdd.check.md
    ├── sdd.fix.md
    ├── sdd.reverse-eng.md
    ├── sdd.backlog.md
    ├── sdd.archive.md
    ├── sdd.compact.md
    └── sdd.inline.md
```

---

## ESTRUCTURA SDD EN EL PROYECTO

El kit crea esta estructura dentro de tu proyecto:

```
{proyecto}/
├── sdd/
│   ├── PROJECT.md               ← Contexto global del proyecto
│   ├── backlog.md               ← Items BLG-XXX
│   ├── wip/                     ← Features en progreso
│   │   └── 001-mi-feature/
│   │       ├── meta.md
│   │       ├── proposal.md
│   │       ├── 1-functional/
│   │       │   └── spec.md
│   │       ├── 2-technical/
│   │       │   └── spec.md
│   │       ├── 3-tasks/
│   │       │   └── tasks.json
│   │       ├── 4-implementation/
│   │       │   └── progress.md
│   │       └── 5-verify/
│   │           └── report.md
│   └── features/                ← Features archivadas
│       └── 001-mi-feature/      ← movida desde wip/
│
└── .session-compact.md          ← Compacto de sesión (oculto)
```

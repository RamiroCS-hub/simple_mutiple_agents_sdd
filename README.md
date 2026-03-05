# SDD Custom Kit

Framework de Spec-Driven Development portable, file-first y multi-agente.
Combina lo mejor del SDD Skills Kit y el Meli SDD Kit sin dependencias de plataforma.

---

## Instalacion rapida

Clonar el repo:
```bash
git clone https://github.com/RamiroCS-hub/simple_mutiple_agents_sdd sdd-custom-kit
cd sdd-custom-kit
```

### Claude Code
Registra skills, parchea `~/.claude/CLAUDE.md` y agrega permisos a `settings.json`:
```bash
bash install.sh
```

### OpenCode
Registra skills en `~/.config/opencode/skills/`, parchea `AGENTS.md` y `opencode.json`:
```bash
bash install-opencode.sh
```

> OpenCode tambien detecta skills en `~/.claude/skills/` — si ya corriste `install.sh`,
> ambas herramientas comparten las mismas definiciones. `install-opencode.sh` agrega
> lo especifico de OpenCode: AGENTS.md global y permisos en opencode.json.

Para actualizar despues de `git pull`:
```bash
bash install.sh --force          # Claude Code
bash install-opencode.sh --force # OpenCode
```

**Sin installer** (manual): agrega el bloque de `CLAUDE-INTEGRATION.md` a tu archivo de instrucciones global.

Verifica la instalacion:
```
/sdd.help
```

---

## Flujo de trabajo

```
/sdd.init           → Detectar stack, crear PROJECT.md
/sdd.new <nombre>   → Explorar + crear proposal
/sdd.ff [slug]      → Fast-forward: spec + design + tasks
/sdd.build [slug]   → Implementar con TDD
/sdd.verify [slug]  → Validar implementacion
/sdd.git [slug]     → Branch + commits (con quality gates)
/sdd.archive [slug] → Archivar feature completada
```

O en modo express:
```
/sdd.go <nombre>    → Todo de una vez
```

---

## Comandos

### Inicio y exploracion

| Comando | Descripcion |
|---------|-------------|
| `/sdd.init` | Inicializar SDD en el proyecto |
| `/sdd.new <nombre>` | Nueva feature (explore + proposal) |
| `/sdd.list` | Listar features activas y archivadas |

### Planificacion

| Comando | Descripcion |
|---------|-------------|
| `/sdd.ff [slug]` | Fast-forward: spec + design + tasks |
| `/sdd.spec [slug]` | Solo escribir specs (functional/technical) |
| `/sdd.design [slug]` | Solo diseno tecnico |
| `/sdd.plan [slug]` | Solo task breakdown |

### Implementacion

| Comando | Descripcion |
|---------|-------------|
| `/sdd.build [slug]` | Implementar con TDD (ciclo RED-GREEN-REFACTOR) |
| `/sdd.verify [slug]` | Verificar implementacion contra specs |
| `/sdd.git [slug]` | Crear branch + commits con Conventional Commits |

### Cierre

| Comando | Descripcion |
|---------|-------------|
| `/sdd.finish [slug]` | Flujo completo: verify + git + archive |
| `/sdd.archive [slug]` | Solo archivar (ya verificado y pusheado) |

### Express

| Comando | Descripcion |
|---------|-------------|
| `/sdd.go <nombre>` | Todo: new -> ff -> build -> verify -> git |

### Calidad y debugging

| Comando | Descripcion |
|---------|-------------|
| `/sdd.check [slug]` | Validacion cross-layer de artefactos |
| `/sdd.fix [slug] <desc>` | Debug y fix de bugs |
| `/sdd.reverse-eng [path]` | Documentar codebase existente |

### Gestion

| Comando | Descripcion |
|---------|-------------|
| `/sdd.backlog [add/list/done/remove]` | Gestionar backlog |
| `/sdd.compact` | Compactar contexto de sesion |
| `/sdd.cancel [slug]` | Cancelar feature en progreso |
| `/sdd.rollback [slug]` | Revertir cambios de codigo |
| `/sdd.help [comando]` | Mostrar ayuda |

---

## Expert mode

> **Solo disponible en Claude Code.** OpenCode no soporta seleccion de modelo por sub-agente via este mecanismo.

Agrega `--expert` a cualquier comando para escalar el modelo del agente:

- `haiku` por defecto → `sonnet` en expert mode
- `sonnet` por defecto → `claude-opus-4-6` en expert mode
- `opus` → sin cambio

Ejemplos:
```
/sdd.new mi-feature --expert
/sdd.build --expert
/sdd.check --expert
```

No disponible en `/sdd.go` (modo express prioriza velocidad).

---

## Quality Gates

### Durante sdd.build
Los quality gates son **opcionales**. El kit pregunta antes de cada tarea:
```
[1] Revisar codigo antes de continuar
[2] Solo scan de seguridad
[3] Ambos (code review + security)
[4] Saltar (continuar sin revision)
```

### Durante sdd.git (y sdd.finish)
Los quality gates son **obligatorios y NO salteables**:
1. Code review completo
2. Security scan (OWASP Top 10)

Si alguno encuentra issues CRITICAL → el push queda bloqueado hasta resolverlos.

---

## Estructura de artefactos

```
{proyecto}/
└── sdd/
    ├── PROJECT.md               <- Contexto global
    ├── backlog.md               <- Items BLG-XXX
    ├── wip/                     <- Features en progreso
    │   └── 001-nombre/
    │       ├── meta.md          <- Estado y metadata
    │       ├── proposal.md      <- Propuesta
    │       ├── 1-functional/
    │       │   └── spec.md
    │       ├── 2-technical/
    │       │   └── spec.md
    │       ├── 3-tasks/
    │       │   └── tasks.json
    │       ├── 4-implementation/
    │       │   └── progress.md
    │       └── 5-verify/
    │           └── report.md
    └── features/                <- Features archivadas
```

---

## Convenciones git

El kit usa Conventional Commits y Gitflow:

**Tipos de commit:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`, `ci`, `build`

**Naming de branches:**
- `feature/{slug}` para nuevas features
- `fix/{slug}` para bug fixes
- `hotfix/{slug}` para fixes urgentes en produccion
- `chore/{slug}` para tareas de mantenimiento

---

## Arquitectura del kit

```
_shared/                   <- Contratos compartidos
  persistence-contract.md
  directory-convention.md
  conventional-commits.md
  quality-gates-protocol.md
  agent-invocation-protocol.md

agents/                    <- 17 sub-agentes especializados
  sdd-explorer.md          <- Analizar codebase (sonnet, read-only)
  sdd-proposer.md          <- Crear proposal (sonnet)
  sdd-spec-writer.md       <- Escribir specs (sonnet)
  sdd-designer.md          <- Diseno tecnico (opus)
  sdd-task-planner.md      <- Task breakdown (sonnet)
  sdd-implementer.md       <- Implementar con TDD (sonnet)
  sdd-tdd-runner.md        <- Ejecutar tests (sonnet)
  sdd-code-reviewer.md     <- Code review (sonnet)
  sdd-security-scanner.md  <- Security scan OWASP (sonnet)
  sdd-verifier.md          <- Verificar contra specs (sonnet)
  sdd-checker.md           <- Cross-layer consistency (haiku)
  sdd-git-manager.md       <- Branch + commits (haiku)
  sdd-archiver.md          <- Archivar feature (haiku)
  sdd-debugger.md          <- Debug root cause (opus)
  sdd-reverse-engineer.md  <- Documentar codigo (sonnet)
  sdd-backlog-manager.md   <- Gestionar backlog (haiku)
  sdd-context-compactor.md <- Compactar contexto (haiku)

skills/                    <- 18 routing skills
  sdd.*.md                 <- Un archivo por comando /sdd.*

openspec/                  <- Artefactos SDD del propio kit
  changes/custom-sdd-kit/  <- Proposal, specs, tasks del kit
```

---

## Principios de diseno

1. **File-first**: Todos los artefactos van a archivos. Sin backends externos obligatorios.
2. **Portable**: Sin dependencias de plataforma (no Fury, no MeLi-only).
3. **Multi-agente**: Cada tarea la hace el agente correcto con el modelo correcto.
4. **Quality gates duales**: Opcionales en build, obligatorios antes de push.
5. **TDD sin stubs**: Implementacion real, no empty stubs para pasar tests.
6. **Conventional Commits + Gitflow**: Historia de git limpia y estructurada.
7. **Expert mode opt-in**: Modelos mas potentes cuando la complejidad lo justifica.

---

## Compatibilidad

### Herramientas soportadas

| Herramienta | Soporte | Notas |
|-------------|---------|-------|
| **Claude Code** | Completo | Todas las funciones, incluyendo expert mode y multi-agente via Task tool |
| **OpenCode** | Completo | Todas las funciones excepto expert mode. Usa `install-opencode.sh` |

> OpenCode tambien busca skills en `~/.claude/skills/` — si tenes Claude Code instalado,
> ambas herramientas comparten las mismas definiciones sin instalar dos veces.

### Funciones por herramienta

| Funcion | Claude Code | OpenCode |
|---------|-------------|----------|
| Todos los comandos `/sdd.*` | Si | Si |
| Multi-agente (sub-agentes) | Si | Si |
| Quality gates | Si | Si |
| TDD nativo | Si | Si |
| Expert mode (`--expert`) | Si | No |

### Stacks soportados

Go, TypeScript/Node.js, Python, Java/Kotlin, Rust.
El kit detecta el stack automaticamente via `sdd.init`.

---

## Desarrollo del kit

El kit se desarrolla con sus propios artefactos SDD en `openspec/changes/custom-sdd-kit/`:
- `proposal.md` — intent, scope y approach del kit
- `specs/functional/spec.md` — spec funcional
- `specs/technical/spec.md` — spec tecnica
- `tasks/tasks.json` — task breakdown

Para contribuir: fork el repo, usa `/sdd.new` para proponer cambios, y abre un PR.

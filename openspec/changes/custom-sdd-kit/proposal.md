# Proposal: Custom SDD Kit — Portable & File-First

## Intent

Both existing SDD kits (SDD Skills Kit y Meli SDD Kit) solve real problems but each has
critical gaps:

- **SDD Skills Kit** es portable y rigoroso en verificación behavioral, pero su persistencia
  es optional/flexible y delega los quality gates solo al final.
- **Meli SDD Kit** tiene quality gates preventivos, agentes especializados y gestión de
  proyecto completa, pero está 100% acoplado al ecosistema Fury/MercadoLibre.

**Este kit crea una tercera opción**: portable, sin lock-in a ninguna plataforma,
que persiste specs SIEMPRE en archivos, incorpora lo mejor de ambos worlds, y agrega
un workflow Git nativo (gitflow + conventional commits) que ninguno de los dos tiene.

El problema concreto que resuelve: un equipo que no trabaja en Fury necesita la misma
disciplina y calidad que Meli SDD Kit ofrece, con la portabilidad del SDD Skills Kit,
y sin tener que gestionar ramas y commits manualmente.

## Scope

### In Scope

- **Framework agnóstico de plataforma**: ninguna dependencia a Fury, AWS, GCP u otros.
  Sin MCPs específicos de empresa. Funciona con cualquier lenguaje y stack.
- **Persistencia file-first obligatoria**: specs, diseño, tareas y reportes SIEMPRE se
  guardan en `sdd/` en el repo. No hay modo `none` ni modo `engram`-only.
  Los archivos son la fuente de verdad.
- **Workflow completo de 6 fases**: init → explore → propose → spec+design → tasks → apply
  → verify → archive. Igual que SDD Skills Kit pero con quality gates preventivos durante
  apply (tomado de Meli Kit).
- **Quality gates configurables (no obligatorios durante desarrollo)**:
  - Code review: pregunta al usuario si quiere ejecutarlo después de cada task.
  - Security scan: pregunta al usuario si quiere ejecutarlo después de cada task.
  - **Excepción**: ambos son OBLIGATORIOS e irrechazables en `sdd.git` (pre-push).
- **`sdd.git` — herramienta de Git integrada**: nuevo skill que, al ejecutarse:
  1. Lee el cambio activo y los archivos modificados.
  2. Crea o retoma la branch siguiendo Gitflow (`feature/`, `fix/`, `hotfix/`, etc.).
  3. Agrupa los cambios en commits lógicos con Conventional Commits
     (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`).
  4. Ejecuta code review + security scan SIEMPRE antes del push (no salteable).
  5. Hace push de la branch.
- **Spec reference annotations** (brownfield): `<!-- overrides: path#section -->`,
  `<!-- extends: path#section -->`, `<!-- deprecates: path#section -->` para documentar
  impacto en features existentes.
- **Spec Compliance Matrix** en verify: cruza cada escenario de la spec contra resultados
  reales de tests ejecutados (tomado de SDD Skills Kit).
- **TDD nativo**: RED → GREEN → REFACTOR con detección automática del test runner.
- **Backlog integrado**: `sdd/backlog.md` para TODO/DEBT/IDEA sin herramienta externa.
- **Reverse engineering**: comando `/sdd.reverse-eng` para documentar codebases existentes.
- **Context management**: compactación automática al 80% de contexto.
- **Modos de ejecución**: Express (auto), Standard (confirmaciones clave), Expert (granular).

### Out of Scope

- Snippets específicos de Fury (KVS, BigQueue, etc.) — no aplica fuera de MeLi.
- MCPs específicos de empresa (FuryMCP, CodeReviewerMCP de MeLi, LargeTestingPlatformMCP).
- Integración con Jira/Linear/GitHub Issues como parte del framework core (puede ser
  extensión futura vía plugin).
- Parallel task execution (modo futuro, no en v1).
- Standards institucionales hardcodeados — el PROJECT.md permite configurar los propios.

## Approach

### Estructura de persistencia (file-first, siempre)

```
sdd/
├── PROJECT.md                    # Config del proyecto (stack, lenguaje, standards)
├── backlog.md                    # TODO / DEBT / IDEA
├── wip/                          # Features activas
│   └── XXX-feature-name/
│       ├── meta.md               # Metadata de la feature
│       ├── 1-functional/spec.md  # WHAT (user stories, AC)
│       ├── 2-technical/spec.md   # HOW (arquitectura, ADRs)
│       ├── 3-tasks/tasks.json    # Task breakdown estructurado
│       ├── 4-implementation/
│       │   └── progress.md       # Estado de implementación
│       └── 5-verify/
│           └── report.md         # Spec Compliance Matrix + resultados
└── features/                     # Features archivadas (completadas)
```

### Skills del kit (agnósticos de plataforma)

| Skill | Propósito | Fuente |
|-------|-----------|--------|
| `sdd-init` | Detecta stack, crea estructura `sdd/` | SDD Skills Kit (adaptado) |
| `sdd-explore` | Investiga codebase | SDD Skills Kit |
| `sdd-propose` | Genera proposal.md | SDD Skills Kit (adaptado) |
| `sdd-spec` | Specs funcional + técnica | Ambos kits (fusionado) |
| `sdd-design` | Diseño técnico + ADRs | Ambos kits (fusionado) |
| `sdd-tasks` | Task breakdown en tasks.json | Meli Kit (tomado tasks.json format) |
| `sdd-apply` | Implementación con TDD + quality gates opcionales | Ambos kits |
| `sdd-verify` | Spec Compliance Matrix + ejecución real | SDD Skills Kit (completo) |
| `sdd-archive` | Sincroniza y archiva | SDD Skills Kit |
| `sdd-git` | **NUEVO**: Gitflow + Conventional Commits + pre-push gates | Nuevo |
| `sdd-reverse-eng` | Documenta codebase existente | Meli Kit (adaptado) |
| `sdd-backlog` | Gestión de backlog | Meli Kit (adaptado) |
| `sdd-check` | Consistencia cross-layer | Meli Kit (adaptado) |
| `sdd-fix` | Debug + reparación | Meli Kit (adaptado) |

### Quality gates — lógica de opcionalidad

```
Durante sdd-apply (por task):
  ├── Code review  → pregunta: "¿Querés hacer code review de este task? [S/n]"
  ├── Security     → pregunta: "¿Querés hacer security scan? [S/n]"
  └── Ambos son opcionales. La respuesta por defecto es "no" para agilizar.

Antes de sdd.git push (SIEMPRE, no salteable):
  ├── Code review  → OBLIGATORIO. No hay flag --skip.
  ├── Security     → OBLIGATORIO. No hay flag --skip.
  └── Si alguno falla → push bloqueado. Muestra issues. Hay que resolver primero.
```

### sdd.git — flujo de trabajo

```
sdd.git ejecuta:
  1. Lee sdd/wip/XXX-feature/meta.md → obtiene tipo (feature/fix/hotfix/chore)
  2. Determina nombre de branch: feature/{feature-name} | fix/{...} | hotfix/{...}
  3. Si la branch no existe → git checkout -b {branch}
     Si existe → git checkout {branch}
  4. git status → lista archivos modificados/nuevos/eliminados
  5. Agrupa archivos por tipo de cambio:
     ├── Código fuente nuevo         → feat: ...
     ├── Bug fix                     → fix: ...
     ├── Tests                       → test: ...
     ├── Docs/specs                  → docs: ...
     ├── Refactor sin funcionalidad  → refactor: ...
     └── Config/build/CI             → chore: ...
  6. Propone commits al usuario para confirmar:
     "Propongo los siguientes commits:
       feat(auth): add JWT validation middleware
       test(auth): add unit tests for JWT middleware
       docs(auth): update technical spec with JWT approach
     ¿Confirmar? [S/n/editar]"
  7. Ejecuta code review (SIEMPRE)
  8. Ejecuta security scan (SIEMPRE)
  9. Si ambos pasan → git push origin {branch}
     Si alguno falla → muestra reporte. Push bloqueado.
```

### Comandos del kit

```
/sdd.init             → inicializa sdd/ en el proyecto
/sdd.new <nombre>     → nueva feature (explore → propose)
/sdd.ff <nombre>      → fast-forward: todos los artefactos de planning
/sdd.go <nombre>      → express mode: plan + implementa + verifica
/sdd.spec             → crea/actualiza spec funcional o técnica
/sdd.plan             → genera tasks.json
/sdd.build            → implementa tasks con quality gates opcionales
/sdd.verify           → verifica (Spec Compliance Matrix)
/sdd.git              → gitflow + conventional commits + pre-push gates
/sdd.finish           → verify + archive + sdd.git
/sdd.check            → consistencia cross-layer
/sdd.fix              → debug y reparación
/sdd.reverse-eng      → documenta codebase existente
/sdd.backlog          → gestión de backlog
/sdd.list             → lista features activas/archivadas
/sdd.cancel           → cancela feature activa
/sdd.rollback         → revierte al estado anterior
/sdd.help             → ayuda del framework
```

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `~/.claude/skills/sdd-*/` | Reference/Base | Skills existentes sirven de base para adaptar |
| `~/.claude/skills/custom-sdd-kit/` | New | Directorio raíz del nuevo kit |
| `~/.claude/skills/custom-sdd-kit/skills/` | New | 14 skills del nuevo kit |
| `~/.claude/skills/custom-sdd-kit/agents/` | New | Agentes especializados (adapter de Meli Kit) |
| `~/.claude/skills/custom-sdd-kit/standards/` | New | Standards configurables por proyecto |
| `~/.claude/skills/custom-sdd-kit/_shared/` | New | Contratos compartidos (persistence-contract adaptado) |
| `~/.claude/CLAUDE.md` | Modified | Agregar comandos `/sdd.*` al orchestrator |
| `sdd/` (en cada proyecto) | New per project | Directorio de specs file-first |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Los quality gates pre-push frenan el flujo si son lentos | Med | Optimizar para que code review y security scan sean rápidos (< 30s). Mostrar progreso en tiempo real. |
| Conflicto de nombres con skills sdd-* existentes | Med | Namespace `sdd.*` (con punto) para comandos, skills en directorio separado `custom-sdd-kit/` |
| sdd.git agrupa commits de forma equivocada | Med | Siempre mostrar propuesta al usuario para confirmar/editar antes de commitear |
| Complexity creep — termina siendo tan complejo como Meli Kit | High | Definir un límite estricto: máximo 14 skills, sin agentes opcionales en v1. Revisar scope en cada iteración. |
| Spec Compliance Matrix vacía si no hay tests | Low | Reportar como WARNING, no CRITICAL. El kit no obliga TDD, lo recomienda. |

## Rollback Plan

El kit vive en `~/.claude/skills/custom-sdd-kit/` completamente separado de los skills
existentes. Si el kit no funciona como se espera:

1. Eliminar `~/.claude/skills/custom-sdd-kit/` — no toca ningún skill existente.
2. Revertir las líneas agregadas al CLAUDE.md del orchestrator (sección `/sdd.*` commands).
3. Los archivos `sdd/` en los proyectos quedan como documentación estática inocua.

No hay migración de datos porque la persistencia es file-based desde el inicio.

## Dependencies

- `git` instalado en el sistema (para `sdd.git`).
- Un code reviewer local o externo (ej: el propio Claude sin MCP dedicado) para los gates.
  En v1 el code review lo hace Claude directamente leyendo el diff.
- Un security scanner: en v1 usa análisis estático de Claude (OWASP Top 10 check).
  Extensible a herramientas externas (semgrep, bandit, etc.) en v2.
- No requiere ningún MCP externo en su configuración base.

## Success Criteria

- [ ] El kit funciona end-to-end en un proyecto Go, Python y TypeScript sin modificaciones.
- [ ] Las specs siempre se persisten en `sdd/wip/XXX/` — nunca solo en memoria.
- [ ] `sdd.git` produce commits con formato Conventional Commits válido en el 100% de los casos.
- [ ] El pre-push gate bloquea efectivamente cuando code review o security scan detectan issues.
- [ ] La Spec Compliance Matrix en verify cruza correctamente cada escenario contra los tests ejecutados.
- [ ] Un nuevo usuario puede ir de `/sdd.init` a primer commit en menos de 15 minutos.
- [ ] Ninguna skill o agente tiene dependencia a Fury, MeLi MCPs, ni plataformas específicas.
- [ ] El quality gate opcional durante apply pregunta al usuario y respeta su decisión.

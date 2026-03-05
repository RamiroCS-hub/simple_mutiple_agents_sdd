# Custom SDD Kit — Technical Specification (v2 — Multi-Agent Architecture)

<!-- overrides: custom-sdd-kit/specs/technical/spec.md#full -->

## Purpose

Este documento describe la arquitectura interna del Custom SDD Kit en su versión
multi-agente. La diferencia central respecto a la v1 es:

- **Skills** → reglas de routing livianas. Le dicen al orchestrator CUÁNDO y CÓMO
  delegar a cada sub-agente. No contienen lógica de ejecución.
- **Agents** → workers especializados. Cada uno tiene un archivo de especificación
  (prompt base) que el orchestrator le pasa como contexto al invocarlos via Task tool.

El orchestrator (Claude Code / agente principal) lee una skill para saber a quién llamar,
y llama al sub-agente pasándole su spec file como base de comportamiento.

---

## ADR-001: Persistencia file-first obligatoria (sin modos alternativos)

**Status**: Accepted

**Decision**: El Custom SDD Kit SOLO opera en modo file-based. No hay modo `none` ni
modo `engram-only`. Los archivos en `sdd/` del proyecto son siempre la fuente de verdad.

**Consequences**:
- (+) Recuperación ante pérdida de contexto siempre funciona.
- (+) Artefactos versionables en git junto con el código.
- (+) Sin dependencias externas para persistencia.
- (-) No funciona sin filesystem accesible (edge case extremo).

---

## ADR-002: Multi-agent con skills como routing (reemplaza skills monolíticas)

**Status**: Accepted

**Context**: La v1 usaba skills monolíticas donde la skill contenía toda la lógica
de ejecución. Esto sobrecarga el contexto del orchestrator y mezcla routing con trabajo.

**Decision**: Separar en dos capas:

1. **Skill** = regla de routing. Dice al orchestrator:
   - Cuándo activarse (trigger)
   - Qué sub-agente(s) invocar
   - En qué orden
   - Qué contexto pasarle a cada uno
   - Qué hacer con el resultado

2. **Agent spec** = prompt base del sub-agente. Define:
   - Rol y responsabilidades
   - Modelo LLM a usar
   - Herramientas permitidas
   - Formato de input/output
   - Reglas de comportamiento

**Consequences**:
- (+) El orchestrator mantiene contexto mínimo — solo lee la routing rule.
- (+) Los sub-agentes corren en contexto aislado — sin contaminación del contexto principal.
- (+) Los agent specs son reutilizables entre comandos distintos.
- (+) El trabajo pesado (leer código, escribir código) queda en los sub-agentes.
- (-) Más archivos que mantener. Mitigado por estructura clara y nomenclatura consistente.

**Alternatives Considered**:
- Skills monolíticas v1: descartado porque mezcla routing con ejecución y satura el contexto.
- Skills como prompts inline: descartado porque no son reutilizables entre comandos.

---

## ADR-003: Agent specs como Markdown con frontmatter YAML

**Status**: Accepted

**Decision**: Cada sub-agente se define con un archivo `agents/{nombre}.md`:

```markdown
---
name: sdd-implementer
description: Implementa código desde specs y tasks. Usa TDD si está configurado.
model: sonnet
tools: [Read, Glob, Grep, Edit, Write, Bash]
---

# [Nombre del Agente]

[Prompt completo que el orchestrator le pasa como base al Task tool]
```

El orchestrator invoca al sub-agente así:

```
Task(
  subagent_type: "general",
  model: "{model del frontmatter}",
  prompt: "{contenido del agent spec} \n\n CONTEXT:\n{contexto específico del cambio}"
)
```

---

## ADR-004: Quality gates opcionales en build, obligatorios en sdd-git

**Status**: Accepted (sin cambios respecto a v1)

Durante `sdd.build`: code-reviewer y security-scanner son opcionales (default: NO).
Durante `sdd.git`: ambos son obligatorios, no tienen flag de skip.

---

## ADR-005: Expert mode escala modelos LLM en lugar de agregar pasos

**Status**: Accepted

**Context**: El modo expert podría implementarse como "más confirmaciones" o como
"mejor razonamiento". Ambas opciones son válidas pero con trade-offs distintos.

**Decision**: Expert mode tiene dos efectos simultáneos:
1. Confirmación antes de cada invocación de sub-agente (igual que en la discusión previa)
2. **Escalado de modelo**: agentes en `sonnet` → `claude-opus-4-6`, agentes en `haiku` → `sonnet`

El orchestrator lee el flag `--expert` y modifica el campo `model` en cada invocación
Task antes de ejecutarla. El agent spec no cambia — solo cambia el parámetro model del Task.

**Escalado de modelos:**

| Modelo base | Standard / Express | Expert |
|---|---|---|
| `claude-haiku-4-5` | haiku | sonnet |
| `claude-sonnet-4-6` | sonnet | `claude-opus-4-6` |
| `claude-opus-4-6` | opus | opus (sin cambio — ya es el máximo) |

**Consequences**:
- (+) El usuario obtiene razonamiento de máxima calidad sin cambiar el prompt ni el flujo.
- (+) El escalado es transparente — el agent spec no necesita saber el modo.
- (+) Los agentes `opus` (designer, debugger) no cambian — ya usan el modelo más capaz.
- (-) Costo mayor por invocación en modo expert. El usuario debe ser consciente de esto.
- (-) Latencia más alta por respuesta de opus vs sonnet.

**Nota de implementación**: El orchestrator DEBE notificar al usuario el modelo efectivo
usado en cada invocación cuando está en modo expert:
```
[Expert] Invocando sdd-implementer con claude-opus-4-6 (base: sonnet)
```

---

## Estructura del kit en filesystem

```
~/.claude/skills/custom-sdd-kit/
│
├── _shared/                             # Contratos compartidos (leídos por agentes y orchestrator)
│   ├── persistence-contract.md          # File-first siempre, sin modos alternativos
│   ├── directory-convention.md          # Estructura canónica de sdd/ en el proyecto
│   ├── conventional-commits.md          # Referencia de tipos, formato y reglas de CC
│   ├── quality-gates-protocol.md        # Protocolo de code review y security scan
│   └── agent-invocation-protocol.md     # Contrato de invocación de sub-agentes (Task tool)
│
├── agents/                              # Spec files de sub-agentes (workers)
│   ├── sdd-explorer.md                  # Explora el codebase antes de proponer
│   ├── sdd-proposer.md                  # Redacta proposal.md
│   ├── sdd-spec-writer.md               # Escribe specs funcionales y técnicas
│   ├── sdd-designer.md                  # Decisiones arquitecturales y ADRs
│   ├── sdd-task-planner.md              # Genera tasks.json
│   ├── sdd-implementer.md               # Escribe código de producción
│   ├── sdd-tdd-runner.md                # Ciclo RED→GREEN→REFACTOR
│   ├── sdd-verifier.md                  # Spec Compliance Matrix + ejecución de tests
│   ├── sdd-code-reviewer.md             # Analiza código por calidad
│   ├── sdd-security-scanner.md          # Analiza código por vulnerabilidades (OWASP)
│   ├── sdd-git-manager.md               # Gitflow + CC + pre-push gates
│   ├── sdd-archiver.md                  # Mueve feature de wip/ a features/
│   ├── sdd-checker.md                   # Consistencia cross-layer entre artefactos
│   ├── sdd-debugger.md                  # Root cause analysis y reparación
│   ├── sdd-reverse-engineer.md          # Infiere specs desde código existente
│   ├── sdd-backlog-manager.md           # CRUD de items en backlog.md
│   └── sdd-context-compactor.md         # Compacta contexto del orchestrator al superar 80%
│
└── skills/                              # Routing rules del orchestrator (livianas)
    ├── sdd.init/SKILL.md                # Init — sin sub-agente, el orchestrator lo resuelve
    ├── sdd.new/SKILL.md                 # explorer → proposer
    ├── sdd.ff/SKILL.md                  # spec-writer → designer → task-planner (secuencial)
    ├── sdd.go/SKILL.md                  # Express: todos los agentes en secuencia
    ├── sdd.spec/SKILL.md                # spec-writer (functional | technical)
    ├── sdd.plan/SKILL.md                # task-planner
    ├── sdd.build/SKILL.md               # implementer (+ tdd-runner si aplica) + gates opcionales
    ├── sdd.verify/SKILL.md              # verifier
    ├── sdd.git/SKILL.md                 # git-manager + code-reviewer + security-scanner (gates)
    ├── sdd.finish/SKILL.md              # verifier → archiver → git-manager
    ├── sdd.check/SKILL.md               # checker
    ├── sdd.fix/SKILL.md                 # debugger
    ├── sdd.reverse-eng/SKILL.md         # reverse-engineer
    ├── sdd.backlog/SKILL.md             # backlog-manager
    ├── sdd.compact/SKILL.md             # context-compactor (manual trigger)
    ├── sdd.list/SKILL.md                # inline — lista features activas y archivadas
    ├── sdd.cancel/SKILL.md              # inline — cancela feature activa
    ├── sdd.rollback/SKILL.md            # inline — revierte última fase
    └── sdd.help/SKILL.md                # inline — tabla de comandos y estado actual
```

---

## Formato de una Skill (routing rule)

Las skills son livianas. Contienen routing logic, no lógica de ejecución.

```markdown
---
name: sdd.build
description: Implementa tasks pendientes con quality gates opcionales.
triggers: ["/sdd.build", "implementar", "build feature"]
---

# sdd.build — Routing Rule

## Cuándo activar

Cuando el usuario ejecuta `/sdd.build` o pide implementar tasks de la feature activa.

## Pre-condiciones

Antes de invocar sub-agentes, el orchestrator DEBE verificar:
- [ ] Existe `sdd/wip/XXX-nombre/3-tasks/tasks.json`
- [ ] Existe al menos una tarea con `"status": "pending"`
- [ ] Si no → mostrar mensaje de error y detener

## Flujo de sub-agentes

### Por cada tarea pendiente en tasks.json:

1. Determinar si el proyecto usa TDD:
   - Leer `sdd/PROJECT.md` → `tdd: true/false`
   - Si `true` → invocar `sdd-tdd-runner`
   - Si `false` → invocar `sdd-implementer`

2. Invocar el agente de implementación:

   ```
   Task(
     model: "{model del agent spec}",
     prompt: "{contenido de agents/sdd-implementer.md}
              \n\nCONTEXT:
              - Feature: {feature-name}
              - Task: {task completa de tasks.json}
              - Spec refs: {leer los archivos referenciados en spec_refs}
              - Project config: {sdd/PROJECT.md}"
   )
   ```

3. Después de que el agente complete la tarea:
   - Actualizar `progress.md` con status: done
   - Preguntar al usuario: "¿Code review para este task? [s/N]"
   - Si responde 's': invocar `sdd-code-reviewer` con el diff
   - Preguntar al usuario: "¿Security scan para este task? [s/N]"
   - Si responde 's': invocar `sdd-security-scanner` con el diff

4. Si hay hallazgos CRITICAL en el gate:
   - Mostrar reporte al usuario
   - Preguntar: "¿Continuar de todas formas? [s/N]" (default N)
   - Si N → pausar y dejar al usuario resolver

5. Continuar con la siguiente tarea

## Output al usuario

Al final de todas las tareas (o si el usuario interrumpe), mostrar:
- Tabla de tasks: ID | Título | Status | Gates ejecutados
- Resumen: X/Y tasks completadas
- Sugerir: "Ready para /sdd.verify o continúa con /sdd.build si quedaron pendientes"
```

---

## Formato de un Agent Spec

Los agent specs son el prompt completo que recibe el sub-agente. Son detallados.

### Ejemplo: agents/sdd-implementer.md

```markdown
---
name: sdd-implementer
description: >
  Implementa código de producción desde specs y tasks.
  Escribe código real, completo, sin TODOs ni stubs vacíos.
model: sonnet
tools: [Read, Glob, Grep, Edit, Write, Bash]
---

# SDD Implementer

Sos un agente de implementación de código. Tu trabajo es tomar una tarea concreta
de un tasks.json y escribir el código de producción que la satisface.

## Lo que vas a recibir en CONTEXT

- Feature name y path a sdd/wip/XXX-nombre/
- La tarea completa (id, title, description, files, acceptance_criteria, spec_refs)
- Contenido de los archivos de spec referenciados
- Configuración del proyecto (sdd/PROJECT.md)

## Pasos

### 1. Leer antes de escribir
- Lee los archivos de spec referenciados en `spec_refs`
- Lee los archivos que vas a modificar (si existen)
- Identificá las convenciones del proyecto (naming, imports, error handling)

### 2. Implementar
- Escribí código que satisface TODOS los `acceptance_criteria` de la tarea
- No dejes TODOs, stubs vacíos, ni `return nil` sin lógica real
- Seguí las convenciones del proyecto (no impongas las tuyas)
- Manejá errores en toda operación que puede fallar
- No hardcodees secrets ni configuración — usá variables de entorno

### 3. Verificación local
- Si el proyecto tiene test runner detectado → ejecutá solo los tests del módulo modificado
- Reportá el resultado (no bloquees si fallan — es tarea del sdd-verifier)

## Output

Devolvé:
- Lista de archivos creados/modificados con breve descripción
- Status de acceptance_criteria: [x] o [ ] para cada uno
- Resultado de tests si los corriste
- Desviaciones del diseño (si las hay) con justificación
```

---

## Tabla de agentes — roles, modelos y agrupaciones

### Grupo Planning (análisis y diseño)

| Agent | Modelo | Tools | Propósito |
|-------|--------|-------|-----------|
| `sdd-explorer` | sonnet | Read, Glob, Grep | Lee el codebase para entender contexto antes de proponer |
| `sdd-proposer` | sonnet | Read, Write | Redacta proposal.md desde análisis o descripción del usuario |
| `sdd-spec-writer` | sonnet | Read, Write | Escribe specs funcionales y técnicas en GWT + RFC 2119 |
| `sdd-designer` | opus | Read, Glob, Write | Decisiones arquitecturales complejas, ADRs, trade-offs |
| `sdd-task-planner` | sonnet | Read, Write | Genera tasks.json con dependencias y capas correctas |

### Grupo Implementation (escritura de código)

| Agent | Modelo | Tools | Propósito |
|-------|--------|-------|-----------|
| `sdd-implementer` | sonnet | Read, Glob, Grep, Edit, Write, Bash | Código de producción desde specs y tasks |
| `sdd-tdd-runner` | sonnet | Read, Glob, Grep, Edit, Write, Bash | Ciclo RED→GREEN→REFACTOR por tarea |

### Grupo Quality Gates (análisis de calidad)

| Agent | Modelo | Tools | Propósito |
|-------|--------|-------|-----------|
| `sdd-code-reviewer` | sonnet | Read, Glob, Grep | Calidad de código: naming, complejidad, patterns |
| `sdd-security-scanner` | sonnet | Read, Glob, Grep | OWASP Top 10, secrets, crypto, injection |

### Grupo Verification (validación post-implementación)

| Agent | Modelo | Tools | Propósito |
|-------|--------|-------|-----------|
| `sdd-verifier` | sonnet | Read, Glob, Grep, Bash | Spec Compliance Matrix + ejecución real de tests |
| `sdd-checker` | haiku | Read, Glob | Consistencia cross-layer entre artefactos |

### Grupo Git (flujo de publicación)

| Agent | Modelo | Tools | Propósito |
|-------|--------|-------|-----------|
| `sdd-git-manager` | haiku | Read, Bash | Gitflow + CC + gates obligatorios + push |

### Grupo Maintenance (mantenimiento del proyecto)

| Agent | Modelo | Tools | Propósito |
|-------|--------|-------|-----------|
| `sdd-archiver` | haiku | Read, Write, Bash | Mueve wip/ a features/, actualiza meta.md |
| `sdd-debugger` | opus | Read, Glob, Grep, Bash | Root cause analysis, debugging complejo |
| `sdd-reverse-engineer` | sonnet | Read, Glob, Grep, Write | Infiere specs desde código sin modificarlo |
| `sdd-backlog-manager` | haiku | Read, Edit | CRUD de backlog.md |
| `sdd-context-compactor` | haiku | Read, Glob | Resume estado de sesión en ~500 tokens |

---

## Mapa de comandos → skills → agentes

```
Comando             Skill invocada        Sub-agentes en orden
──────────────────────────────────────────────────────────────────────────
/sdd.init           sdd.init              (inline — sin sub-agente)
/sdd.new <name>     sdd.new               sdd-explorer → sdd-proposer
/sdd.spec func      sdd.spec              sdd-spec-writer (functional)
/sdd.spec tech      sdd.spec              sdd-spec-writer (technical)
/sdd.plan           sdd.plan              sdd-task-planner
/sdd.ff <name>      sdd.ff                sdd-spec-writer → sdd-designer
                                          → sdd-task-planner
/sdd.build          sdd.build             sdd-implementer | sdd-tdd-runner
                                          (+ opcional: sdd-code-reviewer,
                                                       sdd-security-scanner)
/sdd.verify         sdd.verify            sdd-verifier
/sdd.git            sdd.git               sdd-git-manager
                                          (con: sdd-code-reviewer,
                                                sdd-security-scanner — SIEMPRE)
/sdd.finish         sdd.finish            sdd-verifier → sdd-archiver
                                          → sdd-git-manager
/sdd.check          sdd.check             sdd-checker
/sdd.fix            sdd.fix               sdd-debugger
/sdd.reverse-eng    sdd.reverse-eng       sdd-reverse-engineer
/sdd.backlog        sdd.backlog           sdd-backlog-manager
/sdd.compact        sdd.compact           sdd-context-compactor (manual)
/sdd.list           sdd.list              (inline — sin sub-agente)
/sdd.cancel         sdd.cancel            (inline — sin sub-agente)
/sdd.rollback       sdd.rollback          (inline — sin sub-agente)
/sdd.help           sdd.help              (inline — sin sub-agente)
/sdd.go <name>      sdd.go                sdd-explorer → sdd-proposer
                    (express mode)        → sdd-spec-writer (x2)
                                          → sdd-designer
                                          → sdd-task-planner
                                          → sdd-implementer | sdd-tdd-runner
                                          → sdd-verifier
                                          → sdd-archiver → sdd-git-manager
```

---

## Protocolo de invocación de sub-agentes (contrato del orchestrator)

El orchestrator MUST seguir este protocolo al invocar cualquier sub-agente:

### 1. Leer el agent spec

```
Read("~/.claude/skills/custom-sdd-kit/agents/{nombre-agente}.md")
```

### 2. Construir el prompt del sub-agente

```
prompt = {contenido del agent spec}

prompt += "\n\n---\n## CONTEXT FOR THIS INVOCATION\n"
prompt += "Feature: {feature_name}\n"
prompt += "Project path: {project_path}\n"
prompt += "Execution mode: {express | standard | expert}\n"
prompt += "{contexto específico de la tarea — varía por agente}\n"
```

### 3. Invocar via Task tool

```
Task(
  description: "{nombre-agente} para {feature-name}",
  subagent_type: "general",
  model: "{model del frontmatter del agent spec}",
  prompt: {prompt construido en paso 2}
)
```

### 4. Procesar el resultado

El orchestrator recibe el resultado del sub-agente y:
- Persiste artefactos si el agente los generó (o los lee del filesystem)
- Muestra un resumen al usuario si el modo es `standard` o `expert`
- En modo `express` acumula resultados y muestra un resumen al final
- Decide qué sub-agente invocar a continuación según la skill de routing

---

## Flujo detallado: sdd.git (el más complejo)

La skill `sdd.git/SKILL.md` define este flujo:

```
sdd.git ROUTING RULE:

1. Verificar pre-condiciones:
   - git instalado: git --version
   - Existe sdd/wip/XXX/meta.md con branch configurada
   - Hay cambios staged o unstaged: git status --porcelain

2. Invocar sdd-git-manager (fase 1: análisis y commits):
   Context: {
     feature_meta: sdd/wip/XXX/meta.md,
     git_status: output de git status,
     _shared/conventional-commits.md,
     _shared/directory-convention.md
   }
   El agente produce: lista de commits propuestos (no los ejecuta aún)

3. Mostrar propuesta al usuario [C]onfirmar / [E]ditar / [A]bortar

4. Si Editar → repetir con instrucciones de edición del usuario

5. Si Confirmar:
   a. Invocar sdd-git-manager (fase 2: ejecutar commits)
      Context: {commits aprobados por el usuario}

   b. Invocar sdd-code-reviewer (OBLIGATORIO — no salteable):
      Context: {
        diff: git diff origin/main...HEAD,
        _shared/quality-gates-protocol.md
      }
      Si hay CRITICAL → bloquear. Mostrar reporte. Detener.

   c. Invocar sdd-security-scanner (OBLIGATORIO — no salteable):
      Context: {
        diff: git diff origin/main...HEAD,
        _shared/quality-gates-protocol.md
      }
      Si hay CRITICAL → bloquear. Mostrar reporte. Detener.

   d. Si ambos pasan → invocar sdd-git-manager (fase 3: push)
      Context: {branch name del meta.md}
```

---

## Flujo detallado: sdd.build (gates opcionales)

```
sdd.build ROUTING RULE:

1. Leer tasks.json → obtener tareas con status: "pending"
2. Por cada tarea pendiente:

   a. Detectar si TDD está activo (PROJECT.md → tdd: true)
      → TDD: invocar sdd-tdd-runner
      → No TDD: invocar sdd-implementer

      Context para cualquiera de los dos: {
        task: {tarea completa},
        spec_refs: {contenido de los archivos en task.spec_refs},
        project_config: sdd/PROJECT.md,
        existing_files: {leer archivos en task.files si existen}
      }

   b. Actualizar progress.md (tarea → done)

   c. Preguntar (modo standard/expert):
      "¿Code review para task {id}? [s/N]"
      Si 's' → invocar sdd-code-reviewer
        Context: {diff de los archivos modificados por la tarea}
        Si CRITICAL → mostrar reporte, preguntar si continúa

      "¿Security scan para task {id}? [s/N]"
      Si 's' → invocar sdd-security-scanner
        Context: {diff de los archivos modificados por la tarea}
        Si CRITICAL → mostrar reporte, preguntar si continúa

   d. En modo express: no preguntar, skip ambos gates

3. Al finalizar todas las tareas:
   Mostrar resumen de progreso
   Sugerir: /sdd.verify
```

---

## Esquemas de artefactos (sin cambios respecto a v1)

### meta.md

```markdown
# Feature: {nombre}

**ID**: {XXX}
**Nombre**: {feature-name}
**Tipo**: feature | fix | hotfix | chore
**Estado**: exploring | proposing | speccing | designing | planning | building | verifying | done
**Branch**: feature/{nombre}
**Inicio**: {YYYY-MM-DD}
**Archivado**: {YYYY-MM-DD | null}

## Fases completadas

- [x] Explore
- [x] Propose
- [ ] Spec Funcional
- [ ] Spec Técnica
- [ ] Tasks
- [ ] Implementation
- [ ] Verify
- [ ] Archive
```

### tasks.json

```json
{
  "feature": "001-payment-gateway",
  "generated_at": "2026-03-05",
  "layers": [
    {
      "id": "L1",
      "name": "Foundation",
      "tasks": [
        {
          "id": "1.1",
          "title": "Define domain types",
          "description": "...",
          "files": ["src/domain/payment.ts"],
          "acceptance_criteria": ["..."],
          "spec_refs": ["1-functional/spec.md#REQ-01"],
          "status": "pending",
          "tdd": false
        }
      ]
    }
  ],
  "summary": { "total": 12, "completed": 0, "pending": 12 }
}
```

### PROJECT.md

```markdown
# Project Configuration

## Stack
**Language**: typescript
**Framework**: express
**Test runner**: jest
**Build command**: npm run build
**Test command**: npm test
**Lint command**: npm run lint

## Git
**Default branch type**: feature
**Remote**: origin
**Main branch**: main

## Quality Gates
**Code review model**: sonnet
**Security scan**: owasp-top10
**Coverage threshold**: 80

## Implementation
**TDD**: false
**Commit scope style**: module

## Conventions
**Language**: es
**Spec annotations**: true
```

---

## Dependencias entre artefactos (DAG)

```
meta.md
  │
  └─→ proposal.md
        │
        ├─→ [sdd-spec-writer] → 1-functional/spec.md ─┐
        │                                               ├─→ [sdd-task-planner] → 3-tasks/tasks.json
        └─→ [sdd-designer]   → 2-technical/spec.md ───┘              │
                                                            [sdd-implementer | sdd-tdd-runner]
                                                                       │
                                                              4-implementation/progress.md
                                                                       │
                                                            [sdd-verifier] → 5-verify/report.md
                                                                       │
                                                            [sdd-archiver] → features/XXX/
                                                                       │
                                                            [sdd-git-manager] → push
```

---

## Requisitos del sistema

- Claude Code (o runtime compatible con Task tool para sub-agentes)
- `git` >= 2.0 en PATH
- Sin dependencias adicionales (no Node, Python, Go requeridos para el kit)

## Instalación

```bash
cp -r custom-sdd-kit ~/.claude/skills/
# Agregar routing de comandos /sdd.* al orchestrator (CLAUDE.md)
```

Sin `npm install`, `pip install` ni ningún otro paso.

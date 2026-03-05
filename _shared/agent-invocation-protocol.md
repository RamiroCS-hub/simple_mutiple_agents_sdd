# Agent Invocation Protocol

## Propósito
Define cómo el orquestador construye y lanza llamadas al Task tool para invocar sub-agentes SDD.
Este protocolo es seguido SOLO por el orquestador. Los sub-agentes son workers autónomos.

---

## Estructura base de invocación

```
Task(
  description: '{fase} para {feature-slug}',
  subagent_type: 'general',
  prompt: '
    Lee el archivo de spec del agente en:
    ~/.claude/skills/custom-sdd-kit/agents/{agent-name}.md

    Sigue sus instrucciones exactamente.

    CONTEXTO:
    - project_root: {ruta absoluta al proyecto}
    - feature_slug: {slug de la feature}
    - feature_path: {project_root}/sdd/wip/{slug}/
    - expert_mode: {true|false}

    TAREA ESPECÍFICA:
    {descripción concreta de lo que debe hacer}

    Devuelve resultado estructurado con: status, executive_summary, artifacts, next_recommended, risks.
  '
)
```

---

## Mapeado de agentes por comando

| Comando | Agente(s) | Orden |
|---------|-----------|-------|
| `/sdd.init` | sdd-explorer | 1 (solo lectura, genera PROJECT.md) |
| `/sdd.new` | sdd-explorer → sdd-proposer | secuencial |
| `/sdd.ff` | sdd-spec-writer(func) → sdd-designer → sdd-spec-writer(tech) → sdd-task-planner | secuencial |
| `/sdd.spec` | sdd-spec-writer | 1 |
| `/sdd.design` | sdd-designer | 1 |
| `/sdd.plan` | sdd-task-planner | 1 |
| `/sdd.build` | sdd-implementer + opcional: sdd-code-reviewer, sdd-security-scanner + sdd-tdd-runner | ver build-flow |
| `/sdd.verify` | sdd-tdd-runner → sdd-verifier | secuencial |
| `/sdd.git` | sdd-code-reviewer → sdd-security-scanner → sdd-git-manager | secuencial, gates bloqueantes |
| `/sdd.finish` | sdd-tdd-runner → sdd-verifier → sdd-code-reviewer → sdd-security-scanner → sdd-git-manager → sdd-archiver | secuencial |
| `/sdd.go` | todos en secuencia | secuencial, sin pausa |
| `/sdd.check` | sdd-checker | 1 |
| `/sdd.fix` | sdd-debugger | 1 |
| `/sdd.reverse-eng` | sdd-reverse-engineer | 1 |
| `/sdd.backlog` | sdd-backlog-manager | 1 |
| `/sdd.archive` | sdd-archiver | 1 |
| `/sdd.compact` | sdd-context-compactor | 1 |

---

## Parámetros estándar de contexto

Incluir SIEMPRE en cada invocación:

```
project_root: {cwd o ruta del proyecto detectada}
feature_slug: {slug detectado de sdd/wip/ o del argumento del usuario}
feature_path: {project_root}/sdd/wip/{feature_slug}
expert_mode: {true si el usuario pasó --expert, false en caso contrario}
```

Parámetros adicionales por agente:

### sdd-spec-writer
```
spec_type: functional | technical | both
```

### sdd-implementer
```
task_ids: [{lista de IDs de tasks a implementar, ej: ["1.1", "1.2"]}]
batch_mode: standard | express
```

### sdd-code-reviewer / sdd-security-scanner
```
context: build-optional | git-mandatory
files_to_review: {lista de archivos o "auto-detect from tasks.json"}
```

### sdd-git-manager
```
confirmation_mode: standard | express
gates_passed: true  # solo invocar si ambos gates pasaron
```

### sdd-debugger
```
error_description: {descripción del bug}
apply_fix: true | false
```

### sdd-reverse-engineer
```
scope: full | module:{path}
```

### sdd-backlog-manager
```
action: add | list | done | remove
item_type: TODO | DEBT | IDEA  # solo en add
item_text: {texto}  # solo en add
item_id: {BLG-XXX}  # en done/remove
```

### sdd-context-compactor
```
output_path: {project_root}/.session-compact.md
```

---

## Expert mode: escalado de modelos

Cuando `expert_mode: true`, instruir al agente a usar el modelo escalado.
Incluir en el prompt:

```
MODO EXPERT ACTIVO: Usa el modelo escalado especificado en tu spec de agente.
```

Los agentes conocen su propia escalada:
- haiku por defecto → usar sonnet en expert mode
- sonnet por defecto → usar claude-opus-4-6 en expert mode
- opus → sin cambio (ya es el más capaz)

**Expert mode NO disponible en /sdd.go** (siempre base models para velocidad).

---

## Detección de feature slug

El orquestador detecta el slug en este orden de prioridad:
1. Argumento explícito del usuario (ej: `/sdd.build mi-feature`)
2. Si hay UNA sola feature en `sdd/wip/` → usar esa
3. Si hay múltiples features en `sdd/wip/` → preguntar al usuario
4. Si no hay features → error con mensaje de ayuda

---

## Procesamiento de resultados de sub-agentes

Cuando un sub-agente devuelve resultado:

1. **Verificar status**: `success` | `partial` | `blocked` | `error`
2. **Extraer artifacts**: lista de archivos creados/modificados
3. **Leer next_recommended**: mostrar como SUGERENCIA al usuario, no ejecutar automáticamente
4. **Si status = blocked**: mostrar razón al usuario y DETENER el flujo (no continuar al siguiente agente)
5. **Si status = error**: mostrar error y preguntar al usuario cómo proceder

### Formato de resumen post-agente (solo en comandos interactivos)

```
✅ {fase} completada

{executive_summary del agente}

Archivos generados:
- {artifact 1}
- {artifact 2}

Sugerencia: {next_recommended}
```

---

## Flujo build con quality gates opcionales

```
Para cada task:
  1. Invocar sdd-implementer (task_id)
  2. Invocar sdd-tdd-runner (scope: changed)
  3. Si el usuario eligió hacer review:
     3a. Invocar sdd-code-reviewer (context: build-optional)
     3b. Invocar sdd-security-scanner (context: build-optional)
     3c. En build-optional: gates no bloquean, solo reportan
  4. Mostrar progreso al usuario
  5. Preguntar: ¿continuar con el siguiente task?
```

---

## Flujo git con quality gates obligatorios

```
1. Invocar sdd-code-reviewer (context: git-mandatory)
   - Si status = blocked → DETENER. Mostrar issues. NO invocar nada más.
2. Invocar sdd-security-scanner (context: git-mandatory)
   - Si status = blocked → DETENER. Mostrar issues. NO invocar nada más.
3. Si ambos pasaron → invocar sdd-git-manager (gates_passed: true)
```

---

## Manejo de feature no encontrada

Si no existe `sdd/wip/{slug}/`:
```
❌ Feature `{slug}` no encontrada.

Features disponibles en sdd/wip/:
{lista de slugs o "ninguna"}

Usa /sdd.new <nombre> para crear una nueva feature.
```

---

## Regla anti-recursión

El orquestador NUNCA invoca otro comando SDD desde dentro de un sub-agente.
Los sub-agentes solo devuelven resultados. El orquestador decide qué hacer a continuación.
Si un sub-agente sugiere "ejecutar /sdd-ff", el orquestador lo muestra al usuario como sugerencia.

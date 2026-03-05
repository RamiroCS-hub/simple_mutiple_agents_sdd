# Skill: /sdd.plan [slug]

## Propósito
Genera el task breakdown (tasks.json) a partir de las specs y el diseño.

## Cuándo activar
- `/sdd.plan` o `/sdd.plan {slug}`
- "planificar tareas", "generar tasks", "task breakdown"

## Agente a invocar
**sdd-task-planner**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug del argumento o detectar de wip/}
```

## Prerequisito
`2-technical/spec.md` debe existir. Si solo existe la funcional → sugerir ejecutar `/sdd.design` y `/sdd.spec technical` primero.

## Modo expert
sdd-task-planner: sonnet → claude-opus-4-6

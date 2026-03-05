# Skill: /sdd.design [slug]

## Propósito
Genera las decisiones de diseño técnico (ADRs + componentes). Prerequisito para la spec técnica.

## Cuándo activar
- `/sdd.design` o `/sdd.design {slug}`
- "diseño técnico", "architecture decisions", "ADRs"

## Agente a invocar
**sdd-designer**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug del argumento o detectar de wip/}
```

## Prerequisito
`1-functional/spec.md` debe existir. Si no existe → sugerir `/sdd.spec functional` primero.

## Modo expert
sdd-designer: opus (sin cambio — ya es el modelo más capaz)

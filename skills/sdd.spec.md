# Skill: /sdd.spec [functional|technical|both]

## Propósito
Crea o actualiza la spec funcional y/o técnica de la feature activa.

## Cuándo activar
- `/sdd.spec`, `/sdd.spec functional`, `/sdd.spec technical`, `/sdd.spec both`
- "escribir spec", "crear especificación"

## Agente a invocar
**sdd-spec-writer**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {detectar de sdd/wip/ o arg}
spec_type: {functional | technical | both — default: functional}
designer_output: {si spec_type = technical, verificar si existe output de sdd-designer}
```

## Regla: si spec_type = technical sin designer output
Verificar si ya existe `2-technical/spec.md`. Si no existe y tampoco hay designer output:
→ Preguntar al usuario: "¿Querés ejecutar el diseño técnico primero (`/sdd.design`) para que la spec técnica incorpore las decisiones de arquitectura?"

## Modo expert
sdd-spec-writer: sonnet → claude-opus-4-6

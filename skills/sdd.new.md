# Skill: /sdd.new <nombre>

## Propósito
Inicia una nueva feature: exploración del codebase + creación de propuesta.

## Cuándo activar
- `/sdd.new <nombre>` donde `<nombre>` es el nombre tentativo de la feature

## Agentes a invocar (en secuencia)
1. **sdd-explorer** — investiga el codebase
2. **sdd-proposer** — crea `meta.md` + `proposal.md` con el resultado de exploración

## Parámetros
```
project_root: {directorio actual}
feature_name: {nombre del argumento}
user_description: {descripción del usuario que siguió al comando}
```

## Flujo
1. Invocar `sdd-explorer`. Pasar su output como `exploration_report` al siguiente agente.
2. Invocar `sdd-proposer` con el `exploration_report`.
3. Mostrar al usuario: slug generado, propuesta creada, siguiente paso.

## Output al usuario
```
Nueva feature iniciada: {slug}

Propuesta creada: sdd/wip/{slug}/proposal.md
  Intent: {una línea}
  Scope: {N} entregables

Siguiente paso:
  /sdd.ff {slug}  — generar todos los artefactos de planning
  /sdd.spec       — solo spec funcional
```

## Modo expert
`sdd-explorer`: haiku → sonnet | `sdd-proposer`: sonnet → claude-opus-4-6

# Skill: /sdd.ff [slug]

## Propósito
Fast-forward: genera todos los artefactos de planning en secuencia.
Requiere que `proposal.md` ya exista (ejecutar `/sdd.new` primero).

## Cuándo activar
- `/sdd.ff` o `/sdd.ff {slug}`
- "fast forward", "generar todos los artefactos"

## Agentes a invocar (en secuencia obligatoria)
1. **sdd-spec-writer** `spec_type: functional` — spec funcional
2. **sdd-designer** — decisiones de arquitectura
3. **sdd-spec-writer** `spec_type: technical` + `designer_output` — spec técnica
4. **sdd-task-planner** — tasks.json

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug del argumento, o detectar el único wip activo}
```

## Resolución de feature_slug
Si no se provee argumento:
- Listar `sdd/wip/` — si hay exactamente una feature → usarla
- Si hay más de una → preguntar al usuario cuál

## Flujo
1. Verificar que `proposal.md` existe. Si no → pedir ejecutar `/sdd.new` primero.
2. Ejecutar los 4 agentes en secuencia. Pasar output de cada uno al siguiente.
3. Mostrar resumen consolidado al finalizar los 4.

## Output al usuario (al final de los 4 agentes)
```
Fast-forward completo: {slug}

Artefactos generados:
  ✓ 1-functional/spec.md  — {N} REQs, {M} scenarios
  ✓ 2-technical/spec.md   — {N} ADRs, {M} componentes
  ✓ 3-tasks/tasks.json    — {N} tareas

Siguiente paso: `/sdd.build {slug}` para implementar
```

## Modo expert
Todos los agentes escalan: sdd-spec-writer: sonnet → claude-opus-4-6 | sdd-designer: opus (sin cambio) | sdd-task-planner: sonnet → claude-opus-4-6

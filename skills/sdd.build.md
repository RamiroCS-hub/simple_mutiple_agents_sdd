# Skill: /sdd.build [slug] [--tasks 1,2,3]

## Propósito
Implementa tasks de la feature con TDD + quality gates opcionales.

## Cuándo activar
- `/sdd.build` o `/sdd.build {slug}` o `/sdd.build {slug} --tasks 1,2,3`
- "implementar", "build", "codear"

## Agentes a invocar
**sdd-implementer** (por batch de tasks) + opcionalmente **sdd-code-reviewer** y/o **sdd-security-scanner** + **sdd-tdd-runner**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug o detectar de wip/}
task_ids: {lista del --tasks arg, o todas las pending si no se especifica}
execution_mode: {express | standard | expert}
```

## Flujo por task implementada

1. **sdd-implementer** implementa la tarea.
2. **sdd-tdd-runner** verifica tests.
3. Mostrar al usuario:
   ```
   Task {N} completada. ¿Querés ejecutar quality gates?
     [1] Code review + Security scan
     [2] Solo code review
     [3] Solo security scan
     [4] Omitir  [default]
   ```
4. Según respuesta: invocar sdd-code-reviewer y/o sdd-security-scanner con `context: build-optional`.
5. Continuar con siguiente task.

## Batching
En `express` mode: implementar todas las tasks pending en una sola invocación de sdd-implementer.
En `standard` mode: mostrar progreso después de cada batch de 3 tasks y pedir confirmación para continuar.
En `expert` mode: pedir confirmación después de CADA task.

## Output al usuario (resumen final)
```
Build completo: {slug}

Tasks implementadas: {N}/{total}
Tests: {N} passing
Quality gates ejecutados: {N} veces ({X} con issues}

Siguiente paso: `/sdd.verify {slug}`
```

## Modo expert
sdd-implementer: sonnet → claude-opus-4-6

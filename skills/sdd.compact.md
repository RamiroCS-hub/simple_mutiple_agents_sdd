# Skill: /sdd.compact

## Propósito
Compacta el contexto de sesión activo para prevenir pérdida de información por límite de tokens.
Genera un resumen estructurado del estado actual y lo guarda en `.session-compact.md`.

## Cuándo activar
- `/sdd.compact` — compactar manualmente
- Cuando el contexto supera el 80% del límite (auto-sugerido por el orquestador)
- Antes de iniciar una tarea larga (sdd.build, sdd.ff)
- "compactar sesión", "compact context", "guardar estado"

## Agente a invocar
**sdd-context-compactor**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {detectar de sdd/wip/ si hay feature activa}
output_path: {project_root}/.session-compact.md
```

## Salida esperada
El agente escribe `.session-compact.md` en la raíz del proyecto con:
- Estado del proyecto (nombre, stack, fase actual)
- Feature activa (slug, tasks completados/en progreso/pendientes)
- Artefactos existentes (qué archivos sdd/ existen)
- Decisiones clave de la sesión
- Bloqueadores activos
- Próximo paso recomendado

El orquestador muestra el resumen al usuario y confirma que el contexto fue compactado.

## Sin modo expert (siempre haiku)

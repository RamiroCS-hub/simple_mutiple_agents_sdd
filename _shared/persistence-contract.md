# Persistence Contract — Custom SDD Kit

## Principio fundamental

**File-first. Siempre. Sin excepciones.**

Este kit tiene UN ÚNICO modo de persistencia: el filesystem. No existe modo `engram`, no existe modo `none`, no existe modo `memory-only`. Todos los artefactos SDD DEBEN escribirse a disco antes de que el agente que los generó finalice.

## Fuente de verdad

La fuente de verdad siempre es el directorio `sdd/` en la raíz del proyecto del usuario:

```
{project-root}/sdd/
```

Ningún agente puede declarar una tarea completa si el artefacto correspondiente no existe en disco.

## Regla de recuperación

Si el contexto se pierde (compactación, reinicio, crash), el estado completo del kit se recupera leyendo los archivos en `sdd/`. Los agentes NUNCA deben asumir que el estado está en memoria — siempre lo leen desde disco al inicio de cada invocación.

## Rutas canónicas por tipo de artefacto

| Artefacto | Ruta |
|-----------|------|
| Config del proyecto | `sdd/PROJECT.md` |
| Backlog | `sdd/backlog.md` |
| Metadata de feature | `sdd/wip/XXX-nombre/meta.md` |
| Spec funcional | `sdd/wip/XXX-nombre/1-functional/spec.md` |
| Spec técnica | `sdd/wip/XXX-nombre/2-technical/spec.md` |
| Task breakdown | `sdd/wip/XXX-nombre/3-tasks/tasks.json` |
| Progress de implementación | `sdd/wip/XXX-nombre/4-implementation/progress.md` |
| Reporte de verificación | `sdd/wip/XXX-nombre/5-verify/report.md` |
| Feature archivada | `sdd/features/XXX-nombre/` |

Ver `directory-convention.md` para la especificación completa de la estructura de directorios.

## Protocolo de escritura

1. **Antes de escribir**: verificar que el directorio padre existe. Crearlo si no.
2. **Al escribir**: usar Write o Edit. Nunca truncar un archivo existente sin leerlo primero.
3. **Después de escribir**: confirmar que el archivo existe y tiene contenido.
4. **En caso de error de escritura**: reportar al orquestador. No continuar con el siguiente paso.

## Protocolo de lectura

1. Antes de asumir el estado de cualquier artefacto, leerlo desde disco.
2. Si el archivo no existe, reportar "artefacto pendiente" — no asumir que está en progreso.
3. Si el archivo existe pero está vacío, reportar error y no procesarlo.

## Qué NO está permitido

- Retornar artefactos solo como texto en el output del agente sin escribirlos a disco.
- Depender de variables de entorno o memoria del proceso para persistencia.
- Usar rutas relativas — siempre rutas absolutas o relativas a `{project-root}`.
- Omitir la escritura de un artefacto "porque el usuario ya lo vio en pantalla".

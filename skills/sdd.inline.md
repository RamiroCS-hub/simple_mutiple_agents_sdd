# Skill: Comandos Inline (sin agente)

Estos comandos son manejados DIRECTAMENTE por el orquestador. No invocan ningún agente.

---

## /sdd.list

### Propósito
Lista todas las features activas (wip) y archivadas (features).

### Cuándo activar
- `/sdd.list` — listar features
- "qué features hay", "listar wip", "mostrar features", "list features"

### Lógica del orquestador
1. Leer `sdd/wip/` → listar subdirectorios + leer `meta.md` de cada uno
2. Leer `sdd/features/` → listar subdirectorios + leer `meta.md` de cada uno
3. Si existe `backlog.md`, leer y resumir items pendientes
4. Formatear respuesta:

```
## Features en progreso (WIP)

| ID | Slug | Fase | Estado | Última actualización |
|----|------|------|--------|---------------------|
| 001 | add-auth | building | in_progress | 2026-01-15 |

## Features archivadas

| ID | Slug | Completada |
|----|------|-----------|
| ... | ... | ... |

## Backlog ({N} items pendientes)
[Listar primeros 5 items BLG-XXX]
```

5. Si `sdd/` no existe → "No hay features SDD en este proyecto. Usa `/sdd.init` para inicializar."

---

## /sdd.cancel [slug]

### Propósito
Cancela una feature en progreso. No la elimina, la marca como cancelada.

### Cuándo activar
- `/sdd.cancel` o `/sdd.cancel {slug}`
- "cancelar feature", "abandonar", "cancel this"

### Lógica del orquestador
1. Detectar slug: del argumento o de `sdd/wip/` (si hay solo una feature activa)
2. Si hay múltiples features activas y no se especificó slug → preguntar cuál
3. Leer `sdd/wip/{slug}/meta.md`
4. Confirmar con el usuario: "¿Confirmar cancelación de `{slug}`? Los archivos se conservarán pero la feature quedará marcada como cancelada. [s/n]"
5. Si confirma:
   - Editar `meta.md`: `Estado: cancelled`
   - Agregar línea: `Cancelada: {fecha}`
   - Mostrar: "Feature `{slug}` cancelada. Archivos conservados en `sdd/wip/{slug}/`."
6. Si no confirma: "Cancelación abortada."

### No elimina archivos
Los archivos se conservan. El usuario puede revisar manualmente si quiere borrarlos.

---

## /sdd.rollback [slug]

### Propósito
Deshace los cambios de código de una feature aplicada, revertiendo al estado pre-implementación.

### Cuándo activar
- `/sdd.rollback` o `/sdd.rollback {slug}`
- "rollback", "revertir feature", "deshacer implementación"

### Lógica del orquestador
1. Detectar slug del argumento o feature activa
2. Leer `sdd/wip/{slug}/meta.md` para obtener contexto
3. Verificar si existe `sdd/wip/{slug}/4-build/progress.md`
4. Mostrar advertencia:

```
⚠️  ROLLBACK: `{slug}`

Esto revertirá los cambios de código usando git.
Los artefactos SDD (specs, design, tasks) se conservan.

Opciones:
[1] git stash — guarda todos los cambios sin commitear (reversible con git stash pop)
[2] Ver commits recientes para revertir manualmente
[3] Cancelar

Selección [3]:
```

5. Según elección del usuario:
   - `[1]` → ejecutar `git stash push -m "sdd-rollback-{slug}"`, confirmar con: "Cambios guardados. Recuperar con `git stash pop`."
   - `[2]` → mostrar `git log --oneline -20` y guiar al usuario a usar `git revert {commit}` o `git reset --soft {commit}` manualmente
   - `[3]` → abortar

6. Actualizar `meta.md`: `Estado: rolled_back`

### No toca archivos SDD
Solo afecta el código del proyecto (git operations).

---

## /sdd.help

### Propósito
Muestra ayuda del kit SDD custom.

### Cuándo activar
- `/sdd.help` — ayuda general
- `/sdd.help {comando}` — ayuda específica
- "ayuda sdd", "help sdd", "qué hace sdd"

### Lógica del orquestador
Si sin argumento, mostrar:

```
## SDD Custom Kit — Comandos disponibles

### Inicio y exploración
| Comando | Descripción |
|---------|-------------|
| /sdd.init | Inicializar SDD en el proyecto |
| /sdd.new <nombre> | Nueva feature (explore → propose) |
| /sdd.list | Listar features activas y archivadas |

### Planificación
| Comando | Descripción |
|---------|-------------|
| /sdd.ff [slug] | Fast-forward: spec + design + tasks |
| /sdd.spec [slug] | Solo escribir specs |
| /sdd.design [slug] | Solo diseño técnico |
| /sdd.plan [slug] | Solo task breakdown |

### Implementación
| Comando | Descripción |
|---------|-------------|
| /sdd.build [slug] | Implementar con TDD |
| /sdd.verify [slug] | Verificar implementación |
| /sdd.git [slug] | Crear branch + commits (con quality gates) |

### Cierre
| Comando | Descripción |
|---------|-------------|
| /sdd.finish [slug] | Flujo completo: verify + git + archive |
| /sdd.archive [slug] | Solo archivar (ya verificado y pusheado) |

### Express
| Comando | Descripción |
|---------|-------------|
| /sdd.go <nombre> | Todo de una: new → ff → build → verify → git |

### Calidad y debugging
| Comando | Descripción |
|---------|-------------|
| /sdd.check [slug] | Consistencia cross-layer |
| /sdd.fix [slug] <desc> | Debug y fix de bug |
| /sdd.reverse-eng [path] | Documentar código existente |

### Gestión
| Comando | Descripción |
|---------|-------------|
| /sdd.backlog [add\|list\|done\|remove] | Gestionar backlog |
| /sdd.compact | Compactar contexto de sesión |
| /sdd.cancel [slug] | Cancelar feature |
| /sdd.rollback [slug] | Revertir cambios de código |
| /sdd.help [comando] | Esta ayuda |

### Modos expert (agrega --expert)
Escala el modelo del agente: haiku→sonnet, sonnet→opus
No disponible en /sdd.go (modo express)
```

Si con argumento (ej: `/sdd.help build`), mostrar descripción detallada del comando específico incluyendo:
- Propósito
- Agentes invocados
- Parámetros disponibles
- Ejemplo de uso
- Modo expert disponible (sí/no)

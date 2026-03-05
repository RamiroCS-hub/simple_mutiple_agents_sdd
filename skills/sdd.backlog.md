# Skill: /sdd.backlog [add|list|done|remove]

## Propósito
Gestión del backlog del proyecto (TODO / DEBT / IDEA).

## Cuándo activar
- `/sdd.backlog` → listar
- `/sdd.backlog add TODO "descripción"` → agregar
- `/sdd.backlog done BLG-001` → marcar como completado
- `/sdd.backlog remove BLG-002` → eliminar

## Agente a invocar
**sdd-backlog-manager**

## Parámetros
```
project_root: {directorio actual}
action: {add | list | done | remove — inferir del argumento}
item_type: {TODO | DEBT | IDEA — del segundo argumento en add}
item_text: {texto entre comillas en add}
item_id: {BLG-XXX en done/remove}
feature_slug: {detectar de wip/ si hay una feature activa}
```

## Sin modo expert (siempre haiku)

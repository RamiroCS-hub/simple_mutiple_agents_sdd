# Skill: /sdd.init

## Propósito
Inicializa la estructura SDD en el proyecto actual. Detecta el stack, crea `sdd/` y escribe `PROJECT.md`.

## Cuándo activar
- Usuario ejecuta `/sdd.init`
- Usuario dice "iniciar sdd", "inicializar sdd", "setup sdd"

## Agente a invocar
**sdd-explorer** → luego **sdd-proposer** (solo para crear PROJECT.md + estructura, sin proposal.md)

## Parámetros al agente
```
project_root: {directorio actual}
feature_name: "project-init"
user_description: "Initialize SDD structure for this project"
```

## Flujo
1. Invocar `sdd-explorer` para detectar stack y convenciones.
2. Con el resultado, crear `sdd/PROJECT.md` y `sdd/backlog.md` vacío.
3. NO crear ninguna feature en `sdd/wip/` — solo la estructura base.

## Output esperado al usuario
```
SDD inicializado en {project_root}/sdd/

Archivos creados:
  sdd/PROJECT.md  — configuración del proyecto (stack detectado: {stack})
  sdd/backlog.md  — backlog vacío

Siguiente paso: `/sdd.new <nombre-de-feature>` para empezar una feature.
```

## Modo expert
Sin cambios — init siempre usa el stack de modelos base.

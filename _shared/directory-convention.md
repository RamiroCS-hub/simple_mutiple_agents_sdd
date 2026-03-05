# Directory Convention — Custom SDD Kit

## Estructura raíz

```
{project-root}/
└── sdd/
    ├── PROJECT.md              # Configuración del proyecto
    ├── backlog.md              # TODO / DEBT / IDEA
    ├── wip/                    # Features activas (work in progress)
    │   └── XXX-nombre/         # Una carpeta por feature
    └── features/               # Features archivadas (completadas/canceladas)
        └── XXX-nombre/         # Misma estructura que wip/
```

## Numeración de features

El prefijo `XXX` es un número de 3 dígitos, secuencial, globalmente único dentro del proyecto:

- Primer feature: `001`
- Segunda: `002`
- ...
- Novena: `009`
- Décima: `010`

Para determinar el siguiente número: listar todos los directorios en `sdd/wip/` y `sdd/features/`, extraer el número más alto, incrementar en 1.

## Estructura de una feature

```
sdd/wip/XXX-nombre/
├── meta.md                     # Metadata y estado de la feature
├── 1-functional/
│   └── spec.md                 # Spec funcional (WHAT)
├── 2-technical/
│   └── spec.md                 # Spec técnica (HOW)
├── 3-tasks/
│   └── tasks.json              # Task breakdown estructurado
├── 4-implementation/
│   └── progress.md             # Estado de implementación
└── 5-verify/
    └── report.md               # Spec Compliance Matrix + resultados
```

## Schema de meta.md

```markdown
# Meta: {Nombre descriptivo}

## Identificación
- **ID**: XXX
- **Slug**: XXX-nombre
- **Tipo**: feature | fix | hotfix | chore
- **Estado**: planning | speccing | designing | tasked | building | verifying | done | cancelled

## Resumen
{Una línea describiendo qué resuelve esta feature}

## Stack detectado
- **Lenguaje**: {Go | Python | TypeScript | Java | otro}
- **Framework**: {nombre o "ninguno"}
- **Test runner**: {go test | pytest | jest | junit | otro}
- **Linter**: {golangci-lint | ruff | eslint | otro}

## Git
- **Branch**: {feature|fix|hotfix|chore}/{nombre}
- **Base branch**: {main | master | develop}

## Artefactos
- [ ] 1-functional/spec.md
- [ ] 2-technical/spec.md
- [ ] 3-tasks/tasks.json
- [ ] 4-implementation/progress.md
- [ ] 5-verify/report.md

## Fechas
- **Creada**: {YYYY-MM-DD}
- **Última actualización**: {YYYY-MM-DD}
- **Completada**: {YYYY-MM-DD | —}

## Notas
{Notas libres, decisiones relevantes, contexto adicional}
```

## Schema de PROJECT.md

```markdown
# Project Configuration

## Stack
- **Lenguaje principal**: {Go | Python | TypeScript | Java | Rust | otro}
- **Versión**: {x.y.z}
- **Framework**: {nombre o "ninguno"}
- **Package manager**: {go mod | pip/poetry | npm/pnpm/bun | maven/gradle | cargo}

## Testing
- **Test runner**: {go test | pytest | jest | vitest | junit}
- **Coverage mínimo**: {número}%
- **Comando de tests**: {comando exacto}

## Linting
- **Linter**: {golangci-lint | ruff | eslint | clippy}
- **Comando**: {comando exacto}

## Convenciones
- **Estilo de branch**: {gitflow | trunk | otro}
- **Idioma de código**: {inglés | español}
- **Idioma de commits**: {inglés | español}

## Standards del proyecto
{Standards específicos del proyecto que los agentes deben respetar}

## Notas
{Contexto adicional relevante para los agentes}
```

## Reglas de nombrado

### Nombres de features (slug)
- Formato: `XXX-kebab-case-descriptivo`
- Solo letras minúsculas, números y guiones
- Máximo 50 caracteres totales (incluyendo prefijo XXX-)
- Ejemplos válidos: `001-user-auth`, `002-payment-gateway`, `015-fix-null-pointer`
- Ejemplos inválidos: `001-UserAuth`, `002_payment`, `003-`

### Archivos dentro de feature
- Los nombres son fijos — no se renombran
- `spec.md` es siempre `spec.md` (no `functional-spec.md`, no `spec-v2.md`)
- `tasks.json` es siempre `tasks.json`

## Reglas de archivo vs. wip

- Una feature pasa de `wip/` a `features/` solo mediante `/sdd.finish` o `/sdd.cancel`
- El directorio se mueve completo — no se copian archivos individuales
- En `features/` la estructura es idéntica a `wip/`
- El `meta.md` debe tener `Estado: done` o `Estado: cancelled` al archivar

# Conventional Commits — Custom SDD Kit

Referencia completa para el agente `sdd-git-manager` y cualquier agente que genere mensajes de commit.

## Formato

```
tipo(scope): descripción

[cuerpo opcional]

[footer(s) opcionales]
```

### Reglas de la línea principal

- **Imperativo presente**: "add feature" no "added feature" ni "adds feature"
- **Minúsculas**: tanto el tipo como el scope y descripción
- **Sin punto final** en la descripción
- **Scope en kebab-case**: `user-auth`, `payment-gateway`, `sdd-git`
- **Longitud**: descripción ≤ 72 caracteres
- **Idioma**: inglés (salvo que `PROJECT.md` especifique español)

## Tabla de tipos

| Tipo | Cuándo usarlo | Ejemplos |
|------|---------------|----------|
| `feat` | Nueva funcionalidad visible para el usuario | `feat(auth): add JWT validation middleware` |
| `fix` | Corrección de un bug | `fix(parser): handle nil pointer in token validation` |
| `docs` | Solo cambios de documentación | `docs(api): update endpoint description for /users` |
| `style` | Formato, espacios, punto y coma — sin cambio de lógica | `style(handler): apply gofmt formatting` |
| `refactor` | Refactor sin nueva funcionalidad ni bug fix | `refactor(db): extract query builder to separate package` |
| `test` | Añadir o corregir tests | `test(auth): add unit tests for JWT middleware` |
| `chore` | Build, CI, config, dependencias — sin código de producción | `chore(deps): upgrade go version to 1.22` |
| `ci` | Cambios en archivos de CI/CD | `ci(github): add lint step to PR workflow` |
| `perf` | Mejora de performance | `perf(search): replace linear scan with binary search` |
| `revert` | Revertir un commit anterior | `revert: feat(auth): add JWT validation middleware` |

## Mapeo de archivos a tipo de commit

El agente `sdd-git-manager` usa esta tabla para agrupar archivos en commits:

| Archivos modificados | Tipo sugerido |
|---------------------|---------------|
| Código fuente nuevo (handlers, services, models) | `feat` o `fix` según meta.md |
| Tests nuevos o modificados | `test` |
| `sdd/wip/*/spec.md`, `README.md`, `*.md` docs | `docs` |
| `go.mod`, `package.json`, `pyproject.toml` | `chore` |
| `.github/`, `.gitlab-ci.yml`, `Makefile` CI | `ci` |
| Solo formateo/lint | `style` |
| Archivos de config (`.env.example`, `config.yaml`) | `chore` |
| Código movido/reorganizado sin cambio funcional | `refactor` |

## Breaking Changes

Para cambios que rompen compatibilidad (breaking changes):

```
feat!: remove support for deprecated API v1

BREAKING CHANGE: The /api/v1 endpoints have been removed.
Migrate to /api/v2. See migration guide in docs/migration-v2.md.
```

O con scope:

```
feat(api)!: rename /users/me to /users/profile
```

El `!` después del tipo (o scope) indica breaking change. El footer `BREAKING CHANGE:` es requerido para explicarlo.

## Ejemplos completos

### Correcto

```
feat(auth): add JWT validation middleware
```

```
fix(parser): handle nil pointer in token validation

The parser was crashing when token was nil after context timeout.
Added early return with ErrInvalidToken.
```

```
test(auth): add unit tests for JWT middleware
```

```
docs(sdd): update technical spec with JWT approach
```

```
chore(deps): upgrade go version to 1.22
```

```
feat(payment)!: remove legacy checkout flow

BREAKING CHANGE: The old checkout flow at /checkout/legacy is removed.
All clients must migrate to /checkout/v2.
```

### Incorrecto

```
# Sin tipo
Updated the auth module

# Pasado en vez de imperativo
feat(auth): added JWT validation

# Con punto final
feat(auth): add JWT validation middleware.

# Scope en PascalCase
feat(AuthModule): add JWT validation

# Descripción muy larga (> 72 chars)
feat(auth): add JWT validation middleware that supports both HS256 and RS256 algorithms

# Tipo inventado
update(auth): add JWT validation
```

## Commits atómicos

Cada commit debe ser **atómico**: hace UNA cosa coherente. El agente `sdd-git-manager` DEBE:

1. Agrupar archivos relacionados en el mismo commit (ej: handler + su test juntos en `test:`)
2. Separar cambios de distinto tipo en commits distintos
3. Nunca mezclar `feat` con `docs` en el mismo commit
4. Proponer la agrupación al usuario para confirmar antes de ejecutar

## Scopes recomendados

El scope es opcional pero recomendado. Usar el nombre del módulo, paquete o dominio afectado:

- Go: nombre del package (`auth`, `payment`, `db`)
- Python: nombre del módulo (`auth`, `models`, `api`)
- TypeScript: nombre del directorio/módulo (`components`, `services`, `hooks`)
- Genérico: `sdd`, `config`, `ci`, `deps`

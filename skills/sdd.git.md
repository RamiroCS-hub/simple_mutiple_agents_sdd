# Skill: /sdd.git [slug]

## Propósito
Gitflow + Conventional Commits + quality gates pre-push OBLIGATORIOS.

## Cuándo activar
- `/sdd.git` o `/sdd.git {slug}`
- "hacer commit", "push", "gitflow", "commitear"

## Agentes a invocar (en secuencia)
1. **sdd-code-reviewer** `context: git-mandatory`
2. **sdd-security-scanner** `context: git-mandatory`
3. **sdd-git-manager** con ambos reportes

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug o detectar de la branch git actual}
execution_mode: {express | standard | expert}
```

## Flujo
1. Ejecutar sdd-code-reviewer (obligatorio, no salteable).
2. Ejecutar sdd-security-scanner (obligatorio, no salteable).
3. Si alguno tiene `blocked: true` → mostrar reporte y DETENER. No invocar sdd-git-manager.
4. Si ambos pasan → invocar sdd-git-manager con ambos reportes.

## Output al usuario (si BLOCKED)
```
Push BLOQUEADO — Issues críticos detectados:

[Code Review]
  CRITICAL: {descripción} — {archivo}:{línea}

[Security Scan]
  CRITICAL: {descripción} — {archivo}:{línea} (OWASP {categoría})

Resolvé estos issues antes de ejecutar `/sdd.git` nuevamente.
```

## Modo expert
sdd-code-reviewer: sonnet → claude-opus-4-6 | sdd-security-scanner: sonnet → claude-opus-4-6

# Skill: /sdd.verify [slug]

## Propósito
Verifica la implementación contra las specs. Genera la Spec Compliance Matrix.

## Cuándo activar
- `/sdd.verify` o `/sdd.verify {slug}`
- "verificar", "compliance matrix", "check implementation"

## Agentes a invocar (en secuencia)
1. **sdd-tdd-runner** `scope: feature` — ejecutar tests y obtener resultados
2. **sdd-verifier** con el test_report — generar report.md + Spec Compliance Matrix

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug o detectar de wip/}
```

## Flujo
1. Ejecutar sdd-tdd-runner para obtener estado de tests.
2. Pasar test_report al sdd-verifier.
3. Mostrar veredicto y path al report al usuario.

## Output al usuario
```
Verificación completa: {slug}

Veredicto: APPROVED | CONDITIONAL | REJECTED
Compliance rate: {N}%
Tests: {N} passing, {M} failing

Reporte: sdd/wip/{slug}/5-verify/report.md

{Si APPROVED}: Listo para archivar → `/sdd.finish {slug}`
{Si CONDITIONAL/REJECTED}: Ver reporte para detalles → `/sdd.build {slug}` para continuar
```

## Modo expert
sdd-verifier: sonnet → claude-opus-4-6

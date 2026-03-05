# Skill: /sdd.archive [slug]

## Propósito
Archiva una feature completada moviéndola de sdd/wip/ a sdd/features/.
Usar /sdd.finish para el flujo completo (verify + git + archive).

## Cuándo activar
- `/sdd.archive {slug}` — solo el paso de archivado (si ya se verificó y pusheó manualmente)

## Agente a invocar
**sdd-archiver**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug del argumento o detectar de wip/}
verify_report_status: {leer de 5-verify/report.md si existe}
```

## Sin modo expert (siempre haiku)

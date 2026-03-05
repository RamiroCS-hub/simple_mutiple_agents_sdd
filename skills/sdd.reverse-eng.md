# Skill: /sdd.reverse-eng [module]

## Propósito
Documenta un codebase existente generando specs funcional y técnica derivadas del código real.

## Cuándo activar
- `/sdd.reverse-eng` o `/sdd.reverse-eng {path/to/module}`
- "documentar codebase", "reverse engineering", "generar specs del código existente"

## Agente a invocar
**sdd-reverse-engineer**

## Parámetros
```
project_root: {directorio actual}
scope: {full | module:{argumento si se especifica un path}}
feature_name: {nombre del proyecto o módulo}
```

## Modo expert
sdd-reverse-engineer: sonnet → claude-opus-4-6

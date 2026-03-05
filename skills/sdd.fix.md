# Skill: /sdd.fix [slug] <descripción del error>

## Propósito
Debug y reparación de bugs. Analiza causa raíz y propone/aplica fix.

## Cuándo activar
- `/sdd.fix <descripción>` o `/sdd.fix {slug} <descripción>`
- "hay un bug", "fix this", "algo está roto"

## Agente a invocar
**sdd-debugger**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug si se especifica, vacío si es bug de proyecto}
error_description: {texto después del comando o conversación del usuario}
apply_fix: {true si el usuario dijo "arreglá" / "apply" | false si dijo "analizá" / "qué tiene"}
```

## Detección de apply_fix
- "arreglá", "fix it", "aplicá el fix", "corregí" → `apply_fix: true`
- "qué tiene", "analizá", "qué puede ser" → `apply_fix: false`
- Sin modificador explícito → `apply_fix: false` (proponer primero)

## Modo expert
sdd-debugger: opus (sin cambio — ya es el modelo más capaz)

# Skill: /sdd.finish [slug]

## Propósito
Cierre completo de feature: verify → git → archive.

## Cuándo activar
- `/sdd.finish` o `/sdd.finish {slug}`
- "terminar feature", "cerrar feature", "finish"

## Agentes a invocar (en secuencia)
1. **sdd-tdd-runner** `scope: feature`
2. **sdd-verifier**
3. Si APPROVED o CONDITIONAL (con confirmación del usuario):
   - **sdd-code-reviewer** `context: git-mandatory`
   - **sdd-security-scanner** `context: git-mandatory`
   - **sdd-git-manager**
4. **sdd-archiver**

## Parámetros
```
project_root: {directorio actual}
feature_slug: {slug o detectar de wip/}
```

## Comportamiento en CONDITIONAL
Si sdd-verifier retorna CONDITIONAL → mostrar al usuario:
```
La verificación retornó CONDITIONAL:
{lista de condiciones}

¿Querés proceder con el push y archivar de todas formas? [s/N]
```
Si no confirma → detener. Si confirma → continuar con git + archive.

## Comportamiento en REJECTED
Si sdd-verifier retorna REJECTED → detener siempre.
Mostrar: "La verificación falló. Resolvé los issues con `/sdd.build {slug}` antes de finalizar."

## Modo expert
Todos los agentes escalan sus modelos correspondientes.

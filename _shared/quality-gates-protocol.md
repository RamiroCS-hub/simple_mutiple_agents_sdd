# Quality Gates Protocol — Custom SDD Kit

Define los dos quality gates del kit (code review y security scan), cuándo son opcionales, cuándo son obligatorios, qué analizan, y el formato de reporte.

## Cuándo se ejecutan

| Contexto | Code Review | Security Scan |
|----------|-------------|---------------|
| `sdd.build` — por task | **Opcional** — pregunta al usuario | **Opcional** — pregunta al usuario |
| `sdd.git` — pre-push | **OBLIGATORIO** — no salteable | **OBLIGATORIO** — no salteable |

### Prompt para gates opcionales (sdd.build)

Después de completar cada task, preguntar:

```
Task {ID} completado: {título}

¿Querés ejecutar los quality gates antes de continuar?
  [1] Code review + Security scan
  [2] Solo code review
  [3] Solo security scan
  [4] Omitir (continuar con siguiente task)

Respuesta [4]:
```

El default es `[4]` (omitir) para no interrumpir el flujo de desarrollo.

### Comportamiento en sdd.git (OBLIGATORIO)

No existe opción de omitir. El flujo es:

```
Ejecutando quality gates pre-push...

[1/2] Code Review...
[2/2] Security Scan...

{resultado}
```

Si algún gate tiene hallazgos CRITICAL → push bloqueado. No hay flag `--skip` ni `--force`.

## Gate 1: Code Review

### Qué analiza

El agente `sdd-code-reviewer` (model: sonnet) ejecuta análisis estático leyendo el diff o los archivos modificados.

#### Criterios de revisión

**Naming y claridad**
- Variables, funciones y tipos con nombres descriptivos y consistentes con el resto del código
- Sin abreviaciones crípticas no establecidas en el proyecto
- Nombres en el idioma definido en `PROJECT.md` (inglés por defecto)

**Complejidad**
- Funciones con más de 30 líneas deben tener justificación clara
- Cyclomatic complexity alta (más de 10 caminos) → WARNING
- Anidamiento excesivo (más de 3 niveles) → WARNING

**Duplicación**
- Código idéntico o casi idéntico en más de 2 lugares → WARNING
- Funciones helper que podrían extraerse → SUGGESTION

**Error handling**
- Errores ignorados (sin manejo explícito) → CRITICAL
- Panic/throw no manejados → CRITICAL
- Mensajes de error que exponen información sensible → CRITICAL

**Type safety**
- Casteos inseguros sin validación → WARNING
- `any`/`interface{}` sin justificación → WARNING
- Nil dereferences posibles → CRITICAL

**Tests**
- Código nuevo sin tests correspondientes → WARNING (en sdd.build), CRITICAL (en sdd.git si TDD estaba activo)
- Tests sin assertions reales (solo `_ = fn()`) → WARNING
- Tests que no cubren el camino de error → SUGGESTION

**Documentación de código**
- Funciones públicas sin docstring/godoc/jsdoc → SUGGESTION
- Comentarios que explican el "qué" en vez del "por qué" → SUGGESTION

## Gate 2: Security Scan

### Qué analiza

El agente `sdd-security-scanner` (model: sonnet) aplica análisis estático basado en OWASP Top 10. No usa herramientas externas en v1 — el análisis es realizado por el LLM leyendo el código.

#### OWASP Top 10 — Checklist por ítem

**A01: Broken Access Control**
- Detectar: endpoints sin autenticación, IDs de usuario no validados contra el usuario autenticado (IDOR), rutas admin accesibles sin check de rol
- Buscar: funciones que reciben un ID y lo usan directamente en queries sin validar pertenencia

**A02: Cryptographic Failures**
- Detectar: datos sensibles (passwords, tokens, PII) en logs, algoritmos deprecated (MD5, SHA1 para passwords), claves hardcodeadas
- Buscar: `log.Print*` con campos de usuarios, constantes con "password"/"secret"/"key" y valores reales

**A03: Injection**
- Detectar: SQL injection (concatenación de strings en queries), command injection (`exec`/`os.system` con input de usuario), LDAP injection
- Buscar: `fmt.Sprintf` o concatenación en SQL, `exec.Command` con variables de usuario

**A04: Insecure Design**
- Detectar: ausencia de rate limiting en endpoints de autenticación, ausencia de validación de input en boundaries del sistema
- Buscar: handlers sin validación de tamaño/tipo de input

**A05: Security Misconfiguration**
- Detectar: CORS wildcard (`*`) en producción, headers de seguridad faltantes, modos debug/verbose en configuración de producción
- Buscar: `AllowOrigins: "*"`, ausencia de `X-Content-Type-Options`, `NODE_ENV=development` en config

**A06: Vulnerable and Outdated Components**
- En v1: reportar si se detectan imports de packages con CVEs conocidas (análisis limitado)
- SUGGESTION: revisar dependencias con `npm audit` / `go vuln` / `pip audit`

**A07: Identification and Authentication Failures**
- Detectar: tokens JWT sin validación de firma, sessions sin expiración, passwords sin hashing (plaintext)
- Buscar: `jwt.Parse` sin verificar el error de firma, `bcrypt.MinCost` o hashing MD5/SHA1 de passwords

**A08: Software and Data Integrity Failures**
- Detectar: deserialización de datos no confiables sin validación, dependencias sin verificación de integridad
- Buscar: `json.Unmarshal`/`pickle.loads` con datos de fuentes externas sin sanitización

**A09: Security Logging and Monitoring Failures**
- Detectar: ausencia de logs en eventos de seguridad (login, logout, cambio de password, acceso a datos sensibles)
- Buscar: handlers de auth sin ningún `log.*` call

**A10: Server-Side Request Forgery (SSRF)**
- Detectar: construcción de URLs con input del usuario para hacer requests internos
- Buscar: `http.Get(userInput)`, `url.Parse(req.Query("url"))` seguido de request

## Severidades

| Severidad | Descripción | Bloquea push |
|-----------|-------------|--------------|
| `CRITICAL` | Issue de seguridad grave o bug que rompe funcionalidad. Debe resolverse. | **Sí** |
| `WARNING` | Issue de calidad o riesgo moderado. Recomendado resolver antes de merge. | No |
| `SUGGESTION` | Mejora de estilo, legibilidad o buenas prácticas. Opcional. | No |

**Regla de bloqueo**: si hay al menos 1 hallazgo `CRITICAL` (en cualquiera de los dos gates), el push queda bloqueado. Los WARNINGs y SUGGESTIONs se muestran pero no bloquean el push.

## Formato estándar de reporte

```
## Quality Gates Report

**Ejecutado**: {timestamp}
**Contexto**: sdd.build (task {ID}) | sdd.git (pre-push)
**Archivos analizados**: {N}

---

### Code Review

**Estado**: PASS | FAIL ({N} criticals, {M} warnings, {P} suggestions)

#### Hallazgos

| Severidad | Archivo | Línea | Descripción |
|-----------|---------|-------|-------------|
| CRITICAL  | src/auth/handler.go | 42 | Error ignorado en jwt.Parse — puede aceptar tokens inválidos |
| WARNING   | src/user/service.go | 87 | Función de 45 líneas, considerar extracción |
| SUGGESTION | src/user/service.go | 12 | GetUser sin docstring |

---

### Security Scan

**Estado**: PASS | FAIL ({N} criticals, {M} warnings, {P} suggestions)

#### Hallazgos

| Severidad | OWASP | Archivo | Línea | Descripción |
|-----------|-------|---------|-------|-------------|
| CRITICAL  | A03   | src/db/queries.go | 23 | SQL construido por concatenación con input de usuario |
| WARNING   | A09   | src/auth/handler.go | 55 | Login sin log de auditoría |

---

### Resumen

**Resultado**: PASS | BLOCKED

{Si BLOCKED}: Los siguientes issues CRITICAL deben resolverse antes del push:
1. [Code Review] src/auth/handler.go:42 — Error ignorado en jwt.Parse
2. [Security] src/db/queries.go:23 — SQL injection potencial
```

## Comportamiento post-reporte

### Si PASS
- En `sdd.build`: continuar al siguiente task (o finalizar).
- En `sdd.git`: proceder con el push.

### Si BLOCKED (hay CRITICALs)
- En `sdd.build`: mostrar reporte. Preguntar si el usuario quiere resolver ahora o continuar sin hacer push.
- En `sdd.git`: bloquear push. Mostrar lista de issues CRITICAL. El usuario debe resolverlos y volver a ejecutar `/sdd.git`.

El agente NO debe intentar auto-corregir los issues del security scan sin permiso explícito del usuario. Solo reporta; el usuario decide qué hacer.

# Skill: /sdd.go <nombre>

## Propósito
Express mode: plan + implementa + verifica en un solo comando sin confirmaciones intermedias.

## Cuándo activar
- `/sdd.go <nombre>` — nombre de una feature nueva
- "modo express", "go mode", "sin confirmaciones"

## Equivalente a
`/sdd.new <nombre>` → `/sdd.ff` → `/sdd.build` (express) → `/sdd.verify` → `/sdd.finish`

## Agentes a invocar (en secuencia sin pausas)
1. sdd-explorer
2. sdd-proposer
3. sdd-spec-writer (functional)
4. sdd-designer
5. sdd-spec-writer (technical)
6. sdd-task-planner
7. sdd-implementer (todas las tasks en una invocación)
8. sdd-tdd-runner
9. sdd-verifier
10. (si APPROVED) sdd-code-reviewer + sdd-security-scanner + sdd-git-manager + sdd-archiver

## Pausa entre fases
En express mode: solo pausar si hay BLOCKED (gates) o REJECTED (verify).
En cualquier otro estado: continuar automáticamente.

## Output al usuario (único resumen al final)
```
/sdd.go completo: {slug}

Planning:  ✓ proposal → spec funcional → diseño → spec técnica → {N} tasks
Build:     ✓ {N}/{N} tasks implementadas — {M} tests passing
Verify:    ✓ {compliance_rate}% compliance — APPROVED
Git:       ✓ branch {branch} — {N} commits — pushed
Archived:  ✓ sdd/features/{slug}/
```

## Cuándo NO usar sdd.go
- Features complejas con decisiones de diseño no triviales (usar sdd.new + sdd.ff + sdd.build manualmente)
- Proyectos sin tests configurados (el build no podrá verificar TDD)
- Cuando el usuario quiere revisar specs antes de implementar

## Modo expert
No disponible en express mode — sdd.go siempre usa modelos base para maximizar velocidad.

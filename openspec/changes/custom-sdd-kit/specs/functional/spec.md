# Custom SDD Kit — Functional Specification (v2 — Multi-Agent)

<!-- overrides: custom-sdd-kit/specs/functional/spec.md#full -->

## Purpose

Este documento describe el comportamiento observable del Custom SDD Kit desde la
perspectiva del usuario. La v2 mantiene la misma interfaz de comandos `/sdd.*` que la
v1, pero la implementación subyacente delega el trabajo a sub-agentes especializados.

El usuario no necesita saber qué sub-agente está corriendo. Lo que cambia es:
- Mejor separación de responsabilidades → respuestas más focalizadas
- El orchestrator mantiene contexto mínimo → sesiones más largas sin degradación
- Cada fase tiene un "experto" dedicado → mayor calidad en cada artefacto

---

## REQ-01: Inicialización del proyecto

El kit MUST detectar el contexto del proyecto y crear la estructura `sdd/` cuando el
usuario ejecuta `/sdd.init`.

El kit MUST funcionar sin ningún paso de instalación adicional más allá de tener `git`
disponible en el sistema.

### Scenario: Inicialización en proyecto nuevo

- GIVEN un directorio de proyecto sin `sdd/`
- WHEN el usuario ejecuta `/sdd.init`
- THEN el kit crea `sdd/PROJECT.md`, `sdd/backlog.md`, `sdd/wip/` y `sdd/features/`
- AND muestra un resumen del stack detectado y la configuración generada
- AND confirma que el proyecto está listo para el siguiente paso

### Scenario: Inicialización en proyecto ya inicializado

- GIVEN un directorio con `sdd/` ya existente
- WHEN el usuario ejecuta `/sdd.init`
- THEN el kit detecta la inicialización previa y muestra el estado actual
- AND NOT sobreescribe ningún archivo sin confirmación explícita

### Scenario: Inicialización con stack desconocido

- GIVEN un directorio sin archivos reconocibles de stack
- WHEN el usuario ejecuta `/sdd.init`
- THEN el kit crea la estructura con `PROJECT.md` en modo genérico
- AND indica qué campos debe completar el usuario manualmente

---

## REQ-02: Ciclo de vida de una feature

El kit MUST soportar el ciclo completo desde exploración hasta archivado, con cada fase
delegada a un sub-agente especializado.

El usuario NO necesita saber qué sub-agente ejecuta cada fase. Ve la salida del
sub-agente como si fuera el kit respondiendo directamente.

El kit MUST asignar números únicos de 3 dígitos a cada feature (`XXX-nombre`).

### Scenario: Inicio de feature nueva

- GIVEN un proyecto inicializado
- WHEN el usuario ejecuta `/sdd.new payment-gateway`
- THEN el kit determina el próximo número disponible
- AND crea `sdd/wip/001-payment-gateway/meta.md`
- AND un sub-agente explorador analiza el codebase
- AND un sub-agente redactor genera `proposal.md` basado en la exploración
- AND el usuario ve el resumen de la propuesta para aprobación

### Scenario: Fast-forward de planning completo

- GIVEN una feature con proposal aprobada
- WHEN el usuario ejecuta `/sdd.ff payment-gateway`
- THEN sub-agentes especializados generan en secuencia:
     spec funcional → spec técnica → diseño → tasks.json
- AND cada artefacto se persiste en disco antes de que comience el siguiente
- AND al finalizar el usuario ve un resumen consolidado de los 4 artefactos

### Scenario: Feature completada y archivada

- GIVEN una feature con verify en estado PASS
- WHEN el usuario ejecuta `/sdd.finish`
- THEN un sub-agente mueve `sdd/wip/XXX/` a `sdd/features/XXX/`
- AND la feature ya no aparece en la lista de features activas

---

## REQ-03: Persistencia file-first obligatoria

El kit MUST guardar todos los artefactos como archivos en el repositorio.
El kit MUST NOT depender de memoria externa como única fuente de verdad.

Los sub-agentes MUST leer su contexto desde los archivos en `sdd/` (no del contexto
del orchestrator) para garantizar aislamiento y recuperabilidad.

### Scenario: Artefacto siempre en disco

- GIVEN cualquier sub-agente que genere un artefacto
- WHEN el sub-agente finaliza exitosamente
- THEN el archivo correspondiente existe en el filesystem
- AND puede ser leído con cualquier editor sin herramientas especiales
- AND puede ser commiteado a git

### Scenario: Recuperación ante pérdida de contexto

- GIVEN una sesión interrumpida
- WHEN el usuario retoma con cualquier comando `/sdd.*`
- THEN los sub-agentes leen el estado desde los archivos en `sdd/wip/XXX/`
- AND el trabajo continúa desde donde se dejó sin re-explicar contexto

---

## REQ-04: Especificaciones funcionales y técnicas

Un sub-agente especializado MUST generar las specs. La especialización garantiza que
las specs funcionales NO contengan detalles técnicos y las técnicas NO omitan ADRs.

Las specs funcionales MUST describir comportamiento observable (WHAT).
Las specs técnicas MUST describir arquitectura y decisiones (HOW).

### Scenario: Generación de spec funcional

- GIVEN una feature con proposal aprobada
- WHEN el usuario ejecuta `/sdd.spec functional`
- THEN un sub-agente redactor de specs genera `sdd/wip/XXX/1-functional/spec.md`
- AND la spec contiene requisitos con escenarios Given/When/Then
- AND la spec NO menciona tecnologías específicas

### Scenario: Generación de spec técnica con decisiones arquitecturales

- GIVEN una feature con spec funcional existente
- WHEN el usuario ejecuta `/sdd.spec technical`
- THEN un sub-agente diseñador (modelo opus) genera `sdd/wip/XXX/2-technical/spec.md`
- AND la spec contiene ADRs con contexto, decisión, consecuencias y alternativas consideradas
- AND la spec contiene modelo de datos y diagrama de componentes si aplica

### Scenario: Anotación brownfield

- GIVEN una spec que modifica comportamiento de una feature archivada
- WHEN el desarrollador agrega `<!-- overrides: sdd/features/001-auth/2-technical/spec.md#login-flow -->`
- THEN `/sdd.check` detecta la anotación, verifica que el path existe y la incluye en el reporte

---

## REQ-05: Task breakdown estructurado

Un sub-agente planificador MUST generar `tasks.json` con tareas concretas, numeradas
jerárquicamente y ordenadas por dependencia entre capas.

### Scenario: Generación del task breakdown

- GIVEN specs funcional y técnica existentes
- WHEN el usuario ejecuta `/sdd.plan`
- THEN un sub-agente genera `sdd/wip/XXX/3-tasks/tasks.json`
- AND cada tarea tiene id, título accionable, archivos concretos y acceptance_criteria
- AND las tareas están agrupadas en capas (Foundation, Core, Integration, Tests, Cleanup)
- AND el orden de las capas respeta las dependencias entre tareas

### Scenario: Tareas demasiado grandes

- GIVEN una tarea que cubre más de una responsabilidad lógica
- WHEN el sub-agente planificador la detecta
- THEN la divide automáticamente en sub-tareas más pequeñas
- AND cada sub-tarea es completable en una sola sesión de trabajo

---

## REQ-06: Implementación con quality gates opcionales

Durante `/sdd.build`, sub-agentes de implementación y de quality gates trabajan en
cooperación. El orchestrator coordina las invocaciones.

El kit MUST preguntar al usuario si desea gates (code review y/o security scan) después
de cada tarea. La respuesta por defecto MUST ser "no".

En modo TDD, un sub-agente especializado MUST ejecutar el ciclo RED→GREEN→REFACTOR.

### Scenario: Task completado sin gates

- GIVEN una tarea pendiente
- WHEN el sub-agente de implementación termina
- THEN el orchestrator pregunta: "¿Code review? [s/N]" y "¿Security scan? [s/N]"
- AND si el usuario responde N (o Enter), actualiza progress.md y continúa
- AND el usuario ve un reporte breve de lo implementado

### Scenario: Task con code review solicitado

- GIVEN una tarea completada y el usuario respondió 's' al prompt de code review
- WHEN el sub-agente de code review analiza el diff
- THEN muestra hallazgos clasificados: CRITICAL / WARNING / SUGGESTION
- AND si hay CRITICAL, pregunta al usuario cómo desea proceder antes de continuar

### Scenario: Task con security scan solicitado

- GIVEN una tarea completada y el usuario respondió 's' al prompt de security scan
- WHEN el sub-agente de security scan analiza el diff (OWASP Top 10)
- THEN reporta vulnerabilidades con tipo y ubicación
- AND si hay CRITICAL, el usuario debe resolverlas o aceptar el riesgo explícitamente

### Scenario: Implementación TDD

- GIVEN TDD configurado en PROJECT.md (`tdd: true`) y una tarea de implementación
- WHEN el sub-agente TDD procesa la tarea
- THEN escribe el test primero (RED), ejecuta y confirma que FALLA
- AND escribe el código mínimo para que pase (GREEN), ejecuta y confirma que PASA
- AND refactoriza (REFACTOR), ejecuta y confirma que sigue pasando
- AND el usuario ve el resultado de cada fase del ciclo

---

## REQ-07: Verificación con Spec Compliance Matrix

Un sub-agente verificador MUST ejecutar tests reales y generar la Spec Compliance Matrix.
Un escenario MUST ser COMPLIANT solo si existe un test que lo cubre Y ese test pasó.

### Scenario: Verificación exitosa

- GIVEN una feature con implementación completa
- WHEN el usuario ejecuta `/sdd.verify`
- THEN el sub-agente ejecuta build y tests
- AND genera la Spec Compliance Matrix (escenario × test × resultado)
- AND persiste el reporte en `sdd/wip/XXX/5-verify/report.md`
- AND muestra veredicto: PASS / PASS WITH WARNINGS / FAIL

### Scenario: Escenarios sin tests

- GIVEN una feature verificada donde algunos escenarios de spec no tienen tests
- WHEN el sub-agente genera la matriz
- THEN marca esos escenarios como UNTESTED (❌)
- AND el veredicto es FAIL para requisitos MUST sin tests, PASS WITH WARNINGS para SHOULD/MAY

### Scenario: Tests fallando

- GIVEN una feature donde algún test falla
- WHEN el sub-agente genera la matriz
- THEN marca los escenarios cubiertos por ese test como FAILING (❌)
- AND el veredicto es FAIL y el kit no permite archivar la feature

---

## REQ-08: sdd.git — Git workflow integrado con sub-agentes

El orchestrator MUST coordinar múltiples sub-agentes para el flujo Git:
- Un sub-agente de git gestiona branches, commits y push
- Sub-agentes de quality gates ejecutan code review y security scan (SIEMPRE, no salteable)

El usuario MUST poder revisar y editar la propuesta de commits antes de que se ejecuten.

### Scenario: Primer push de una feature

- GIVEN código implementado y sin branch creada
- WHEN el usuario ejecuta `/sdd.git`
- THEN el sub-agente git crea `feature/XXX-nombre` y analiza los cambios
- AND propone commits agrupados con mensajes Conventional Commits
- AND muestra al usuario: "Confirmar / Editar / Cancelar"

### Scenario: Usuario confirma propuesta

- GIVEN propuesta de commits aceptada
- WHEN el usuario responde "Confirmar"
- THEN el sub-agente git ejecuta los commits
- AND el sub-agente de code review analiza el diff completo (OBLIGATORIO)
- AND el sub-agente de security scanner analiza el diff completo (OBLIGATORIO)
- AND si ambos pasan → push a origin
- AND si alguno falla → push bloqueado, usuario ve el reporte

### Scenario: Usuario edita la propuesta

- GIVEN propuesta de commits mostrada
- WHEN el usuario responde "Editar"
- THEN el usuario puede cambiar tipos, mensajes y agrupación de archivos
- AND el sub-agente git aplica los cambios y muestra la propuesta actualizada

### Scenario: Gate de code review bloquea el push

- GIVEN commits ejecutados y code review en progreso
- WHEN el sub-agente de code review encuentra hallazgos CRITICAL
- THEN el push no se ejecuta
- AND el usuario ve el reporte completo con archivos y líneas afectadas
- AND puede ejecutar `/sdd.git` nuevamente después de resolver los issues

### Scenario: Gate de security scan bloquea el push

- GIVEN commits ejecutados, code review pasado, security scan en progreso
- WHEN el sub-agente de security scan encuentra vulnerabilidades CRITICAL
- THEN el push no se ejecuta
- AND el usuario ve el reporte con tipo de vulnerabilidad (ej: SQL Injection) y ubicación

### Scenario: Commit con formato Conventional Commits válido

- GIVEN un archivo nuevo de código fuente
- WHEN el sub-agente git lo agrupa en un commit
- THEN el mensaje sigue: `tipo(scope): descripción en inglés`
- AND el tipo es uno de: feat, fix, docs, style, refactor, test, chore, ci, perf
- AND la descripción está en imperativo presente, sin punto final

---

## REQ-09: Consistencia cross-layer

Un sub-agente verificador de consistencia MUST detectar desconexiones entre artefactos.

### Scenario: Tarea sin respaldo en spec

- GIVEN feature con tasks.json y specs
- WHEN el usuario ejecuta `/sdd.check`
- THEN el sub-agente detecta tareas sin escenario de spec que las origine
- AND las reporta como WARNING

### Scenario: Escenario sin tarea correspondiente

- GIVEN feature con specs y tasks.json
- WHEN el usuario ejecuta `/sdd.check`
- THEN el sub-agente detecta escenarios que no tienen ninguna tarea asociada
- AND los reporta como WARNING (posible bajo cubrimiento del plan)

---

## REQ-10: Reverse engineering

Un sub-agente de reverse engineering MUST inferir specs desde código existente
sin modificar ningún archivo de código fuente.

### Scenario: Documentación de módulo existente

- GIVEN un módulo de código sin specs en `sdd/`
- WHEN el usuario ejecuta `/sdd.reverse-eng --module auth`
- THEN el sub-agente analiza los archivos (read-only)
- AND genera specs funcional y técnica en `sdd/features/000-reverse-eng-auth/`
- AND marca las specs como "Generado por reverse engineering — validar con el equipo"

---

## REQ-11: Gestión de backlog

Un sub-agente de backlog MUST gestionar ítems en `sdd/backlog.md`.

### Scenario: Agregar ítem

- GIVEN proyecto con `sdd/backlog.md`
- WHEN el usuario ejecuta `/sdd.backlog add "Migrar a pytest" --type DEBT`
- THEN el ítem se agrega con tipo, fecha y estado OPEN

### Scenario: Listar backlog filtrado

- GIVEN backlog con ítems de distintos tipos
- WHEN el usuario ejecuta `/sdd.backlog list --type TODO`
- THEN muestra solo los ítems TODO en estado OPEN con su fecha de creación

---

## REQ-12: Modos de ejecución

El kit MUST soportar tres modos que controlan la interacción y el modelo LLM usado.
Los modos afectan tanto la coordinación de sub-agentes como el modelo asignado a cada uno.

- **Express** (`/sdd.go`): mínima interacción. Los sub-agentes se encadenan automáticamente.
  Solo 3-5 preguntas críticas al inicio. Los quality gates opcionales se omiten.
  Modelo: cada agente usa su modelo base definido en su frontmatter.

- **Standard** (default): confirmaciones entre sub-agentes. El usuario ve el output de
  cada uno antes de que comience el siguiente.
  Modelo: cada agente usa su modelo base definido en su frontmatter.

- **Expert** (`--expert`): confirmación antes de cada invocación de sub-agente.
  **Los agentes que normalmente usan `sonnet` DEBEN ser invocados con `claude-opus-4-6`.**
  Los agentes que ya usan `opus` mantienen su modelo. Los agentes `haiku` escalan a `sonnet`.
  Esto garantiza el máximo razonamiento posible en cada paso del flujo.

### Tabla de escalado de modelos por modo

| Modelo base del agente | Express | Standard | Expert |
|---|---|---|---|
| `haiku` | haiku | haiku | sonnet |
| `sonnet` | sonnet | sonnet | claude-opus-4-6 |
| `opus` | opus | opus | opus (sin cambio) |

### Scenario: Express mode

- GIVEN una descripción de feature
- WHEN el usuario ejecuta `/sdd.go "user authentication"`
- THEN el orchestrator hace 3-5 preguntas críticas
- AND encadena todos los sub-agentes en secuencia sin confirmaciones intermedias
- AND al finalizar muestra un resumen consolidado de todo lo generado

### Scenario: Standard mode

- GIVEN una feature en progreso
- WHEN un sub-agente completa su fase
- THEN el orchestrator muestra el output del sub-agente y pregunta si continuar
- AND espera confirmación antes de invocar el siguiente sub-agente

### Scenario: Expert mode — escalado de modelo

- GIVEN el usuario ejecuta cualquier comando con flag `--expert`
- WHEN el orchestrator va a invocar un sub-agente cuyo modelo base es `sonnet`
- THEN lo invoca con modelo `claude-opus-4-6` en lugar de `sonnet`
- AND el usuario ve una nota: "[Expert] Usando claude-opus-4-6 para {nombre-agente}"

### Scenario: Expert mode — confirmación granular

- GIVEN modo expert activo durante `/sdd.build`
- WHEN el orchestrator está a punto de invocar al siguiente sub-agente
- THEN muestra: "Siguiente: {agente} para task {id}. [Continuar/Saltar/Abortar]"
- AND espera respuesta del usuario antes de cada invocación

---

## REQ-13: Portabilidad total

El kit MUST NOT tener dependencias a plataformas específicas.
Ningún sub-agente MUST requerir MCPs de empresa específica para funcionar.

El kit MUST ser instalable copiando un directorio, sin pasos adicionales.

### Scenario: Uso en proyecto sin infraestructura específica

- GIVEN un proyecto Django + PostgreSQL sin infraestructura de empresa
- WHEN el usuario usa el kit completo
- THEN todos los sub-agentes operan correctamente
- AND ningún output menciona servicios de plataforma específica

### Scenario: Instalación del kit

- GIVEN una máquina nueva con Claude Code
- WHEN el usuario copia `~/.claude/skills/custom-sdd-kit/`
- THEN el kit está disponible inmediatamente en los comandos `/sdd.*`
- AND no requiere `npm install`, `pip install` ni ningún otro paso

---

## REQ-14: Comandos de gestión de estado del proyecto

El kit MUST proveer comandos para listar features, cancelar una feature activa, revertir
al estado anterior y obtener ayuda — todos sin invocar sub-agentes (resueltos inline
por el orchestrator).

### Scenario: Listar features activas y archivadas

- GIVEN un proyecto con features en `sdd/wip/` y `sdd/features/`
- WHEN el usuario ejecuta `/sdd.list`
- THEN el orchestrator lee los directorios y muestra una tabla con:
  ID | Nombre | Estado | Fase actual | Fecha de inicio
- AND las features activas (wip) se muestran separadas de las archivadas (features/)
- AND si no hay features, muestra mensaje: "No hay features. Empezá con /sdd.new <nombre>"

### Scenario: Listar solo features activas

- GIVEN un proyecto con features activas y archivadas
- WHEN el usuario ejecuta `/sdd.list --active`
- THEN muestra solo las features en `sdd/wip/` con su estado actual

### Scenario: Cancelar feature activa

- GIVEN una feature en progreso en `sdd/wip/XXX-nombre/`
- WHEN el usuario ejecuta `/sdd.cancel`
- THEN el orchestrator muestra: "¿Cancelar XXX-nombre? Esto eliminará sdd/wip/XXX-nombre/. [s/N]"
- AND si el usuario confirma, elimina el directorio `sdd/wip/XXX-nombre/`
- AND si existe una branch git para la feature, pregunta: "¿Eliminar branch feature/XXX-nombre? [s/N]"
- AND confirma la cancelación con un resumen de lo eliminado

### Scenario: Cancelar sin feature activa

- GIVEN un proyecto sin features en `sdd/wip/`
- WHEN el usuario ejecuta `/sdd.cancel`
- THEN muestra: "No hay features activas para cancelar"

### Scenario: Rollback al estado anterior de una feature

- GIVEN una feature activa con al menos una fase completada (ej: spec funcional creada)
- WHEN el usuario ejecuta `/sdd.rollback`
- THEN el orchestrator muestra el estado actual de la feature y la fase previa disponible
- AND pregunta: "¿Revertir a la fase anterior? Esto eliminará {artefacto}. [s/N]"
- AND si el usuario confirma, elimina el artefacto de la última fase completada
- AND actualiza `meta.md` para reflejar el estado anterior

### Scenario: Rollback con cambios git presentes

- GIVEN una feature en rollback con commits en la branch local
- WHEN el usuario ejecuta `/sdd.rollback`
- THEN el orchestrator advierte: "Hay commits en la branch. El rollback solo afecta artefactos sdd/, no el git history."
- AND procede solo con la eliminación de artefactos

### Scenario: Ayuda del kit

- GIVEN cualquier estado del proyecto
- WHEN el usuario ejecuta `/sdd.help`
- THEN muestra una tabla con todos los comandos disponibles, su descripción y un ejemplo de uso
- AND muestra el modo actual (express/standard/expert) y la feature activa si existe

---

## REQ-15: Gestión automática de contexto

El kit MUST monitorear el uso del contexto del orchestrator y actuar cuando se supera
el 80% de capacidad para evitar degradación de calidad.

Cuando el contexto supera el 80%, el orchestrator MUST delegar la continuación del
trabajo a un sub-agente compactador que resume el estado antes de continuar.

El usuario MUST ser notificado cuando ocurre una compactación de contexto.

### Scenario: Compactación automática al superar el 80%

- GIVEN una sesión larga donde el contexto del orchestrator supera el 80% de capacidad
- WHEN el orchestrator detecta que el contexto está cerca del límite
- THEN invoca al sub-agente compactador antes de invocar el próximo agente de trabajo
- AND el compactador genera un resumen del estado actual (feature activa, tareas completadas, decisiones tomadas)
- AND el orchestrator usa ese resumen como contexto reducido para continuar
- AND notifica al usuario: "[Context] Compactando contexto — continuando desde resumen"

### Scenario: Estado preservado tras compactación

- GIVEN una compactación de contexto ejecutada
- WHEN el orchestrator continúa con el siguiente sub-agente
- THEN el sub-agente recibe el mismo contexto relevante que habría recibido sin compactación
- AND no hay pérdida de información crítica (feature name, tarea actual, spec refs)

### Scenario: Compactación manual

- GIVEN el usuario quiere forzar una compactación aunque no haya superado el 80%
- WHEN ejecuta `/sdd.compact`
- THEN el orchestrator invoca el sub-agente compactador inmediatamente
- AND muestra el resumen generado al usuario para que pueda verificarlo

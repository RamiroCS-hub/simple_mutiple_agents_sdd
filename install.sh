#!/usr/bin/env bash
# SDD Custom Kit — Installer
#
# USAGE: bash install.sh [--force]
#
# Copia el kit desde este repo a ~/.claude/skills/custom-sdd-kit/ y registra
# los /sdd.* commands como skills de Claude Code.
#
# --force: sobreescribe wrappers de skills ya existentes (para actualizar)

set -euo pipefail

KIT_SOURCE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SKILLS="$HOME/.claude/skills"
KIT_DEST="$CLAUDE_SKILLS/custom-sdd-kit"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
FORCE=false

if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${CYAN}[sdd-kit]${NC} $1"; }
ok()     { echo -e "${GREEN}  ✓${NC} $1"; }
skip()   { echo -e "${YELLOW}  -${NC} $1 (sin cambios)"; }
update() { echo -e "${GREEN}  ↑${NC} $1 (actualizado)"; }

echo ""
log "SDD Custom Kit installer"
log "Fuente: $KIT_SOURCE"
log "Destino: $KIT_DEST"
echo ""

# ---------------------------------------------------------------------------
# 1. Verificar que el kit fuente está completo
# ---------------------------------------------------------------------------
for required in "_shared" "agents" "skills" "CLAUDE-INTEGRATION.md"; do
  if [[ ! -e "$KIT_SOURCE/$required" ]]; then
    echo "ERROR: Falta $KIT_SOURCE/$required — ¿estás ejecutando desde la raíz del repo?"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# 2. Copiar/sincronizar kit a ~/.claude/skills/custom-sdd-kit/
# ---------------------------------------------------------------------------
log "Sincronizando kit a $KIT_DEST ..."
echo ""

mkdir -p "$KIT_DEST"

for dir in _shared agents skills; do
  if rsync -a --checksum "$KIT_SOURCE/$dir/" "$KIT_DEST/$dir/" 2>/dev/null; then
    ok "$dir/"
  else
    # fallback si rsync no está disponible
    cp -r "$KIT_SOURCE/$dir/." "$KIT_DEST/$dir/"
    ok "$dir/ (cp)"
  fi
done

for file in CLAUDE-INTEGRATION.md README.md; do
  if [[ -f "$KIT_SOURCE/$file" ]]; then
    cp "$KIT_SOURCE/$file" "$KIT_DEST/$file"
    ok "$file"
  fi
done

echo ""

# ---------------------------------------------------------------------------
# 3. Registrar wrapper SKILL.md files en ~/.claude/skills/sdd.*/
# ---------------------------------------------------------------------------

register_skill() {
  local cmd="$1"
  local desc="$2"
  local skill_file="$3"   # nombre de archivo en skills/ o "inline"

  local target_dir="$CLAUDE_SKILLS/$cmd"
  local target_file="$target_dir/SKILL.md"

  # Construir contenido del wrapper
  if [[ "$skill_file" == "inline" ]]; then
    local body="Command: /$cmd

Read the inline command instructions at \`$KIT_DEST/skills/sdd.inline.md\` and execute the section for \`/$cmd\`."
  else
    local body="Command: /$cmd

Read the full skill definition at \`$KIT_DEST/skills/$skill_file\` and execute it."
  fi

  local new_content="---
name: $cmd
description: >
  [SDD Custom Kit] $desc
  Trigger: /$cmd
license: MIT
metadata:
  author: sdd-custom-kit
  version: \"1.0\"
---

$body"

  if [[ -f "$target_file" ]] && [[ "$FORCE" == false ]]; then
    # Verificar si el contenido cambió
    existing=$(cat "$target_file")
    if [[ "$existing" == "$new_content" ]]; then
      skip "$cmd"
      return
    else
      # Contenido difiere → actualizar siempre (para que install.sh --force no sea necesario en updates menores)
      mkdir -p "$target_dir"
      echo "$new_content" > "$target_file"
      update "$cmd"
      return
    fi
  fi

  mkdir -p "$target_dir"
  echo "$new_content" > "$target_file"
  ok "$cmd"
}

log "Registrando /sdd.* skills ..."
echo ""

register_skill "sdd.init"        "Initialize SDD structure in the current project. Creates sdd/ dir and PROJECT.md."               "sdd.init.md"
register_skill "sdd.new"         "Start a new feature or change with an exploration and proposal."                                  "sdd.new.md"
register_skill "sdd.ff"          "Fast-forward: create all planning artifacts (spec + design + tasks) in one shot."                 "sdd.ff.md"
register_skill "sdd.spec"        "Write functional and technical specs for a feature."                                               "sdd.spec.md"
register_skill "sdd.design"      "Create technical design document with architecture decisions."                                     "sdd.design.md"
register_skill "sdd.plan"        "Break down a feature into a structured implementation task list."                                  "sdd.plan.md"
register_skill "sdd.build"       "Implement tasks from the plan with optional TDD and quality gates."                                "sdd.build.md"
register_skill "sdd.verify"      "Run tests and validate implementation against specs."                                              "sdd.verify.md"
register_skill "sdd.git"         "Code review + security scan + commit or PR workflow."                                              "sdd.git.md"
register_skill "sdd.finish"      "Full finish flow: verify + git + archive in sequence."                                             "sdd.finish.md"
register_skill "sdd.go"          "Express mode: full SDD workflow from idea to implementation without pauses."                       "sdd.go.md"
register_skill "sdd.check"       "Spec compliance check — non-blocking, shows COMPLIANT/PARTIAL/MISSING per scenario."               "sdd.check.md"
register_skill "sdd.fix"         "Debug and fix a reported issue using the sdd-debugger agent."                                      "sdd.fix.md"
register_skill "sdd.reverse-eng" "Reverse engineer existing code into SDD artifacts (spec + design)."                               "sdd.reverse-eng.md"
register_skill "sdd.backlog"     "Manage the feature backlog: add, list, done, remove items."                                        "sdd.backlog.md"
register_skill "sdd.archive"     "Archive a completed feature, moving it from wip/ to features/."                                    "sdd.archive.md"
register_skill "sdd.compact"     "Compact session context to save tokens using sdd-context-compactor."                               "sdd.compact.md"
register_skill "sdd.list"        "List all WIP and archived features in the current project."                                        "inline"
register_skill "sdd.cancel"      "Cancel a WIP feature, updating its meta.md status to cancelled."                                  "inline"
register_skill "sdd.rollback"    "Rollback a feature's git changes to its branching point."                                          "inline"
register_skill "sdd.help"        "Show available SDD commands with descriptions and usage examples."                                 "inline"

echo ""

# ---------------------------------------------------------------------------
# 4. Parchear CLAUDE.md si no tiene el bloque orquestador
# ---------------------------------------------------------------------------
log "Verificando CLAUDE.md ..."

CLAUDE_BLOCK='## SDD Custom Kit — Orchestrator'

if grep -qF "$CLAUDE_BLOCK" "$CLAUDE_MD" 2>/dev/null; then
  skip "CLAUDE.md ya contiene el bloque orquestador"
else
  log "Agregando bloque orquestador a $CLAUDE_MD ..."
  BLOCK=$(sed -n '/^```markdown$/,/^```$/p' "$KIT_DEST/CLAUDE-INTEGRATION.md" | sed '1d;$d')
  if [[ -z "$BLOCK" ]]; then
    echo "ERROR: No se pudo extraer el bloque de CLAUDE-INTEGRATION.md"
    exit 1
  fi
  printf '\n%s\n' "$BLOCK" >> "$CLAUDE_MD"
  ok "CLAUDE.md parcheado"
fi

echo ""
log "Instalación completa."
echo ""
echo -e "  Kit instalado en: ${CYAN}$KIT_DEST${NC}"
echo -e "  Probar con:       ${CYAN}/sdd.help${NC}"
echo ""
echo "  Para actualizar después de cambios en el repo:"
echo "    bash $KIT_SOURCE/install.sh"
echo ""

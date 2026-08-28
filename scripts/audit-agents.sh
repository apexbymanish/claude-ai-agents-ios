#!/usr/bin/env bash
#
# Mechanical checks for this repo's own .claude/agents and .claude/skills
# files. These are the same checks that got written out by hand, over and
# over, throughout this repo's development -- name-matches-filename,
# description has a real trigger phrase, a read-only claim doesn't sit
# next to a Write/Edit grant, code fences close. Scripting them once beats
# re-deriving them by hand on every future change.
#
# Usage: scripts/audit-agents.sh [repo-root]
#
# This never fails the run -- exit code is always 0. A check that blocks
# work is a check someone disables; these are findings for a human to
# act on, not a gate.

set -uo pipefail

ROOT="${1:-.}"
AGENTS_DIR="$ROOT/.claude/agents"
SKILLS_DIR="$ROOT/.claude/skills"

issues=0

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()      { printf '  ✓ %s\n' "$1"; }
warn()    { printf '  ⚠ %s\n' "$1"; issues=$((issues + 1)); }
bad()     { printf '  ✗ %s\n' "$1"; issues=$((issues + 1)); }

check_fence_balance() {
    local file="$1" count
    count=$(grep -c '^```' "$file")
    if [ $((count % 2)) -ne 0 ]; then
        bad "unbalanced code fence ($count backtick-fence lines -- an odd count means a block never closes)"
    fi
}

check_agent() {
    local file="$1" base name desc tools quoted
    base=$(basename "$file" .md)
    section "agent: $base"

    name=$(grep -m1 '^name:' "$file" | sed 's/^name: *//')
    if [ -z "$name" ]; then
        bad "no 'name:' in frontmatter -- this agent will never load"
    elif [ "$name" != "$base" ]; then
        bad "name ($name) doesn't match the filename ($base) -- invocation by name misses it"
    else
        ok "name matches filename"
    fi

    desc=$(grep -m1 '^description:' "$file")
    if [ -z "$desc" ]; then
        bad "no 'description:' -- this agent can never be auto-selected"
    else
        quoted=$(printf '%s' "$desc" | grep -oE '"[^"]+"' | wc -l | tr -d ' ')
        if [ "$quoted" -eq 0 ]; then
            warn "description has no quoted trigger phrase -- a bare category label under-triggers"
        else
            ok "description carries $quoted quoted trigger phrase(s)"
        fi
    fi

    tools=$(grep -m1 '^tools:' "$file")
    if [ -z "$tools" ]; then
        warn "no 'tools:' line -- tool access defaults to unrestricted"
    else
        ok "tools: $(printf '%s' "$tools" | sed 's/^tools: *//')"
    fi

    # A body that claims read-only behavior but still carries Write/Edit
    # is a contradiction the agent will act on unpredictably.
    if grep -qiE 'read-only|does not edit|do not edit|never modif(y|ies)' "$file" \
       && printf '%s' "$tools" | grep -qE '\b(Write|Edit)\b'; then
        bad "body claims read-only behavior but tools: still grants Write/Edit"
    fi

    # An agent naming a Skill by backtick reference needs the Skill tool
    # to actually load it -- otherwise the reference is dead weight.
    if grep -qE '`ios-[a-z-]+`[^.]{0,40}skill' "$file" \
       && ! printf '%s' "$tools" | grep -qw 'Skill'; then
        warn "references a skill by name but tools: doesn't include Skill"
    fi

    check_fence_balance "$file"
}

check_skill() {
    local file="$1" dname name desc quoted
    dname=$(basename "$(dirname "$file")")
    section "skill: $dname"

    name=$(grep -m1 '^name:' "$file" | sed 's/^name: *//')
    if [ -z "$name" ]; then
        bad "no 'name:' in frontmatter -- this skill will never load"
    elif [ "$name" != "$dname" ]; then
        bad "name ($name) doesn't match the directory ($dname) -- calls by name miss it"
    else
        ok "name matches directory"
    fi

    desc=$(grep -m1 '^description:' "$file")
    if [ -z "$desc" ]; then
        bad "no 'description:' -- this skill can never be auto-selected"
    else
        quoted=$(printf '%s' "$desc" | grep -oE '"[^"]+"' | wc -l | tr -d ' ')
        if [ "$quoted" -eq 0 ]; then
            warn "description has no quoted trigger phrase"
        else
            ok "description carries $quoted quoted trigger phrase(s)"
        fi
    fi

    check_fence_balance "$file"
}

check_cross_references() {
    section "cross-file references"
    local all_names mentioned missing=0

    # Third-party MCP server names this repo documents integrating with
    # (see .mcp.json and README) -- not agents or skills defined here, so
    # they'd otherwise read as dangling references.
    local external_names=$'ios-agent\nios-simulator\nios-simulator-mcp\nios-agent-mcp'

    all_names=$( { ls "$AGENTS_DIR" 2>/dev/null | sed 's/\.md$//'; ls "$SKILLS_DIR" 2>/dev/null; printf '%s\n' "$external_names"; } | sort -u)
    mentioned=$(grep -rhoE '`ios-[a-z-]+`' "$AGENTS_DIR" "$SKILLS_DIR" 2>/dev/null | tr -d '`' | sort -u)

    # Every backtick `ios-...` mention across every agent/skill file should
    # resolve to a real agent or skill in this repo (or a known external
    # tool above). A renamed or typo'd reference is otherwise invisible
    # until someone follows it and finds nothing there.
    while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        if ! printf '%s\n' "$all_names" | grep -qx "$ref"; then
            bad "\`$ref\` is referenced somewhere but no agent or skill by that name exists"
            missing=1
        fi
    done <<< "$mentioned"

    [ "$missing" -eq 0 ] && ok "every \`ios-*\` reference resolves to a real agent or skill"
}

agent_files=()
while IFS= read -r f; do agent_files+=("$f"); done < <(find "$AGENTS_DIR" -name '*.md' 2>/dev/null | sort)
for f in "${agent_files[@]}"; do check_agent "$f"; done

skill_files=()
while IFS= read -r f; do skill_files+=("$f"); done < <(find "$SKILLS_DIR" -name 'SKILL.md' 2>/dev/null | sort)
for f in "${skill_files[@]}"; do check_skill "$f"; done

check_cross_references

section "summary"
if [ "$issues" -eq 0 ]; then
    printf '  ✓ clean -- no issues found\n'
else
    printf '  ⚠ %d issue(s) listed above\n' "$issues"
fi
printf '\nNon-blocking by design -- these are findings for a human to act on.\n'

exit 0

#!/bin/bash
# Собирает shell-master_standalone.sh: распаковка дерева (lib, levels, share, bin) и запуск bin/shell-master.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${1:-$ROOT/shell-master_standalone.sh}"

_need=(bin/shell-master lib/run.sh lib/common.sh share/outro.txt)
for p in "${_need[@]}"; do
    if [[ ! -e "$ROOT/$p" ]]; then
        echo "gen_standalone: нет $ROOT/$p" >&2

        exit 1
    fi
done

mapfile -t _payload_files < <(
    {
        find "$ROOT/lib" "$ROOT/levels" "$ROOT/share" "$ROOT/bin" -type f 2>/dev/null
    } | LC_ALL=C sort
)

if ((${#_payload_files[@]} == 0)); then
    echo "gen_standalone: нет файлов для упаковки" >&2

    exit 1
fi

{
    echo '#!/usr/bin/env bash'
    echo '# Сгенерировано scripts/gen_standalone.sh — не править вручную.'
    echo 'shell_master_install_payload() {'
    echo '    local _root="$1"'
    echo '    mkdir -p "$_root" || return 1'

    for f in "${_payload_files[@]}"; do
        rel="${f#$ROOT/}"
        tag="P64_${rel//[^a-zA-Z0-9_]/_}"
        parent=$(dirname "$rel")

        if [[ "$parent" != "." ]]; then
            echo "    mkdir -p \"\$_root/$parent\""
        fi

        echo "    base64 -d > \"\$_root/$rel\" <<'$tag'"
        base64 "$f" | tr -d '\n'
        echo ""
        echo "$tag"
    done

    echo '}'
    echo 'SHELL_MASTER_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/shell-master.XXXXXX")'
    echo 'trap '"'"'rm -rf "$SHELL_MASTER_ROOT"'"'"' EXIT INT TERM HUP'
    echo 'shell_master_install_payload "$SHELL_MASTER_ROOT" || { echo shell-master: распаковка не удалась >&2; exit 1; }'
    echo 'chmod +x "$SHELL_MASTER_ROOT/bin/shell-master" 2>/dev/null || true'
    echo 'exec bash "$SHELL_MASTER_ROOT/bin/shell-master" "$@"'
} > "$OUT"

chmod +x "$OUT"
echo "gen_standalone: wrote $OUT (${#_payload_files[@]} файлов)"

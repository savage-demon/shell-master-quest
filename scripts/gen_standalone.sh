#!/bin/bash
# Собирает game5_standalone.sh: распаковка дерева проекта (lib, levels, share, bin) и запуск bin/game5.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${1:-$ROOT/game5_standalone.sh}"

_need=(bin/game5 lib/run.sh lib/common.sh share/outro.txt)
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
    echo 'game5_install_payload() {'
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
    echo 'GAME5_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/game5.XXXXXX")'
    echo 'trap '"'"'rm -rf "$GAME5_ROOT"'"'"' EXIT INT TERM HUP'
    echo 'game5_install_payload "$GAME5_ROOT" || { echo game5: распаковка не удалась >&2; exit 1; }'
    echo 'chmod +x "$GAME5_ROOT/bin/game5" 2>/dev/null || true'
    echo 'exec bash "$GAME5_ROOT/bin/game5" "$@"'
} > "$OUT"

chmod +x "$OUT"
echo "gen_standalone: wrote $OUT (${#_payload_files[@]} файлов)"

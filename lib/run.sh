#!/bin/bash
# Движок: уровни в levels/<NN>_<name>/ (intro.txt, on_success.txt, on_reject.txt, generate.sh).

# Базовый каталог игры (относительно cwd или абсолютный путь). Внутри него рядом создаются level_1, level_2, …
GAME="${1:-quest}"

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$_LIB_DIR/.." && pwd)"

source "$_LIB_DIR/common.sh"

ROOT=""
export ROOT

declare -a _LEVEL_DIRS=()
discover_levels() {
    local d

    shopt -s nullglob

    for d in "$PROJECT_ROOT/levels/"[0-9][0-9]_*/; do
        [[ -d "$d" ]] || continue

        _LEVEL_DIRS+=("$d")
    done

    shopt -u nullglob

    if ((${#_LEVEL_DIRS[@]} == 0)); then
        echo "quest: нет уровней в $PROJECT_ROOT/levels/" >&2

        exit 1
    fi
}

validate_level() {
    local d=$1

    for f in intro.txt on_success.txt on_reject.txt generate.sh; do
        if [[ ! -f "$d/$f" ]]; then
            echo "quest: в $d нет файла $f" >&2

            exit 1
        fi
    done
}

if [[ "$GAME" == /* ]]; then
    _GAME_WORKDIR_ABS="$GAME"
else
    _GAME_WORKDIR_ABS="$(pwd)/$GAME"
fi

if command -v realpath >/dev/null 2>&1; then
    _GAME_WORKDIR_ABS="$(realpath -m "$_GAME_WORKDIR_ABS")"
fi

clear
show_welcome_arena "$_GAME_WORKDIR_ABS"

rm -rf "$GAME" && mkdir -p "$GAME" && cd "$GAME" || exit
ROOT=$(pwd)
export ROOT

discover_levels

_level_idx=0

for level_dir in "${_LEVEL_DIRS[@]}"; do
    validate_level "$level_dir"

    ((_level_idx++))
    mkdir -p "$ROOT/level_${_level_idx}" && cd "$ROOT/level_${_level_idx}" || exit 1

    LEVEL_CORRECT=""

    echo ""
    print_task_file "$level_dir/intro.txt"
    echo ""

    # shellcheck source=/dev/null
    source "$level_dir/generate.sh"

    if [[ -z "${LEVEL_CORRECT:-}" ]]; then
        echo "quest: $level_dir/generate.sh должен задать LEVEL_CORRECT" >&2

        exit 1
    fi

    progress_done

    echo "Каталог с файлами задания:"
    echo "$(pwd)"
    echo "---------------------------------------------------------"

    check_level_answer "$LEVEL_CORRECT" "$level_dir/on_success.txt" "$level_dir/on_reject.txt" || exit 1
done

show_outro_from_file "$PROJECT_ROOT/share/outro.txt"

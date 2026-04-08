# Общие функции терминального квеста. Подключается из framework.sh и из generate.sh уровней.
# Ожидаются: ROOT, PLAYER, GAME_HOST, _ALNUM (или задаются здесь).

: "${GAME_HOST:=netgrid}"
: "${_ALNUM:=abcdefghijklmnopqrstuvwxyz0123456789}"

gen_id() { echo $((100000 + RANDOM % 899999)); }

gen_name() {
    local s=""

    for ((i = 0; i < 10; i++)); do s+="${_ALNUM:$((RANDOM % 36)):1}"; done

    echo "$s"
}

tpl_expand() {
    local s=$1
    local ans="${2-}"

    s=${s//@ROOT@/$ROOT}
    s=${s//@PLAYER@/$PLAYER}
    s=${s//@HOST@/$GAME_HOST}
    s=${s//@FLAG@/${FINAL_FLAG_ID-}}
    s=${s//@ANS@/$ans}

    printf '%s' "$s"
}

progress_done() {
    echo ""
}

readonly _OP_WRAP_MAX=80
readonly _OP_PREFIX_LEN=12
readonly _OP_WRAP_BUDGET=$((_OP_WRAP_MAX - _OP_PREFIX_LEN))
readonly _OP_INDENT='            '

_operator_print_wrapped_line() {
    local use_op_prefix=$1
    local chunk_first=$2
    local chunk=$3

    if ((chunk_first && use_op_prefix)); then
        printf '\033[1;33m[operator]:\033[0m \033[0;37m%s\033[0m\n' "$chunk"
    else
        printf '%s\033[0;37m%s\033[0m\n' "$_OP_INDENT" "$chunk"
    fi
}

_operator_emit_oversized_word() {
    local use_op_prefix=$1
    local chunk_first=$2
    local w=$3
    local rest=$w
    local take

    while (( ${#rest} > _OP_WRAP_BUDGET )); do
        take="${rest:0:_OP_WRAP_BUDGET}"
        _operator_print_wrapped_line "$use_op_prefix" "$chunk_first" "$take"
        chunk_first=0
        rest="${rest:_OP_WRAP_BUDGET}"
    done

    if [[ -n "$rest" ]]; then
        _operator_print_wrapped_line "$use_op_prefix" "$chunk_first" "$rest"
    fi
}

operator_emit_wrapped_paragraph() {
    local use_op_prefix=$1
    local text=$2
    local line=""
    local w
    local chunk_first=1

    [[ -z "${text// }" ]] && return 0

    set -f
    for w in $text; do
        if (( ${#w} > _OP_WRAP_BUDGET )); then
            if [[ -n "$line" ]]; then
                _operator_print_wrapped_line "$use_op_prefix" "$chunk_first" "$line"
                chunk_first=0
                line=""
            fi

            _operator_emit_oversized_word "$use_op_prefix" "$chunk_first" "$w"
            chunk_first=0

            continue
        fi

        local cand="$line"
        [[ -n "$line" ]] && cand+=" "
        cand+="$w"

        if (( ${#cand} <= _OP_WRAP_BUDGET )); then
            line="$cand"
        else
            _operator_print_wrapped_line "$use_op_prefix" "$chunk_first" "$line"
            chunk_first=0
            line="$w"
        fi
    done

    set +f

    if [[ -n "$line" ]]; then
        _operator_print_wrapped_line "$use_op_prefix" "$chunk_first" "$line"
    fi
}

readonly _SYS_WRAP_MAX=80
readonly _SYS_PREFIX_LEN=12
readonly _SYS_WRAP_BUDGET=$((_SYS_WRAP_MAX - _SYS_PREFIX_LEN))
readonly _SYS_INDENT='            '

_system_print_wrapped_line() {
    local chunk_first=$1
    local chunk=$2

    if ((chunk_first)); then
        printf '\033[1;36m[system]:\033[0m %s\n' "$chunk"
    else
        printf '%s%s\n' "$_SYS_INDENT" "$chunk"
    fi
}

_system_emit_oversized_word_sys() {
    local chunk_first=$1
    local w=$2
    local rest=$w
    local take

    while (( ${#rest} > _SYS_WRAP_BUDGET )); do
        take="${rest:0:_SYS_WRAP_BUDGET}"
        _system_print_wrapped_line "$chunk_first" "$take"
        chunk_first=0
        rest="${rest:_SYS_WRAP_BUDGET}"
    done

    if [[ -n "$rest" ]]; then
        _system_print_wrapped_line "$chunk_first" "$rest"
    fi
}

system_emit_wrapped_paragraph() {
    local text=$1
    local line=""
    local w
    local chunk_first=1

    [[ -z "${text// }" ]] && return 0

    set -f
    for w in $text; do
        if (( ${#w} > _SYS_WRAP_BUDGET )); then
            if [[ -n "$line" ]]; then
                _system_print_wrapped_line "$chunk_first" "$line"
                chunk_first=0
                line=""
            fi

            _system_emit_oversized_word_sys "$chunk_first" "$w"
            chunk_first=0

            continue
        fi

        local cand="$line"
        [[ -n "$line" ]] && cand+=" "
        cand+="$w"

        if (( ${#cand} <= _SYS_WRAP_BUDGET )); then
            line="$cand"
        else
            _system_print_wrapped_line "$chunk_first" "$line"
            chunk_first=0
            line="$w"
        fi
    done

    set +f

    if [[ -n "$line" ]]; then
        _system_print_wrapped_line "$chunk_first" "$line"
    fi
}

system_say() {
    local msg

    msg=$(tpl_expand "$1")
    system_emit_wrapped_paragraph "$msg"
}

show_connect() {
    system_say "установка зашифрованного канала связи..."
    echo -ne "\033[1;36m[system]:\033[0m Введите ваш идентификатор доступа \033[1;37m(LOGIN)\033[0m: "
    read -r PLAYER || exit 1
    PLAYER="${PLAYER#"${PLAYER%%[![:space:]]*}"}"
    PLAYER="${PLAYER%"${PLAYER##*[![:space:]]}"}"
    [[ -z "$PLAYER" ]] && PLAYER="OPERATOR"

    system_say "добро пожаловать в сеть, ${PLAYER}. соединение установлено."
}

operator_level_from_file() {
    local path=$1
    local line
    local first=1
    local -a raw=()
    local n i

    mapfile -t raw < "$path"

    n=${#raw[@]}
    while ((n > 0)) && [[ -z "${raw[n - 1]// }" ]]; do
        ((n--))
    done

    for ((i = 0; i < n; i++)); do
        line=$(tpl_expand "${raw[i]}")

        if [[ -z "${line// }" ]]; then
            echo ""
            first=1

            continue
        fi

        if ((first)); then
            operator_emit_wrapped_paragraph 1 "$line"
            first=0
        else
            operator_emit_wrapped_paragraph 0 "$line"
        fi
    done
}

show_progress() {
    local current=$1 total=$2 title=$3

    ((total < 1)) && return 0

    local step=$((total / 10))
    ((step < 1)) && step=1

    if ((current % step == 0 || current == total)); then
        local perc=$((current * 100 / total))
        local done=$((perc / 5))
        local rem=$((20 - done))
        local fill_done=$(printf "%${done}s" | tr ' ' '#')
        local fill_rem=$(printf "%${rem}s" | tr ' ' '-')

        printf "\r\033[1;36m[system]:\033[0m \033[0;37m%s\033[0m [\033[1;32m%s\033[1;30m%s\033[0m] %d%%\033[0m" "$title" "$fill_done" "$fill_rem" "$perc"
    fi
}

operator_emit_template_file() {
    local path=$1
    local ans="${2-}"
    local msg line out first

    if [[ ! -f "$path" ]]; then
        if [[ -n "$ans" ]]; then
            operator_emit_wrapped_paragraph 1 "$(tpl_expand "Ответ «@ANS@» не подходит. Файл оператора не найден: ${path##*/}" "$ans")"
        else
            operator_emit_wrapped_paragraph 1 "Файл оператора не найден: ${path##*/}"
        fi

        return 1
    fi

    out=""
    first=1

    while IFS= read -r line || [[ -n $line ]]; do
        line="${line%$'\r'}"

        if ((first)); then
            out=$line
            first=0
        else
            out+=" $line"
        fi
    done < "$path"

    operator_emit_wrapped_paragraph 1 "$(tpl_expand "$out" "$ans")"
}

# Ожидание ответа игрока: файлы успеха и отклонения из папки уровня.
check_level_answer() {
    local correct=$1
    local path_ok=$2
    local path_reject=$3
    local input=""

    while true; do
        printf '\033[1;32m[%s]:\033[0m ' "$PLAYER"
        read -r input || return 1
        input="${input#"${input%%[![:space:]]*}"}"
        input="${input%"${input##*[![:space:]]}"}"

        if [[ "$input" == "$correct" ]]; then
            operator_emit_template_file "$path_ok"

            return 0
        fi

        operator_emit_template_file "$path_reject" "$input"
    done
}

show_outro_from_file() {
    local outro_path=$1
    local line

    FINAL_FLAG_ID=$(gen_id)

    while IFS= read -r line || [[ -n $line ]]; do
        line=$(tpl_expand "$line")

        [[ -z "${line// }" ]] && continue

        if [[ "$line" == '[operator]:'* ]]; then
            echo -e "\033[1;32m${line}\033[0m"
        elif [[ "$line" == '[system]:'* ]]; then
            echo -e "\033[1;36m${line}\033[0m"
        else
            echo "$line"
        fi
    done < "$outro_path"
}

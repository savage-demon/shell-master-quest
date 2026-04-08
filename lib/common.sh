# Общие функции квеста (задачи и проверка ответа, без сюжета «чата»).

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

    s=${s//@ROOT@/${ROOT-}}
    s=${s//@PLAYER@/${PLAYER-}}
    s=${s//@HOST@/${GAME_HOST-}}
    s=${s//@FLAG@/${FINAL_FLAG_ID-}}
    s=${s//@ANS@/$ans}
    s=${s//@ans@/$ans}

    printf '%s' "$s"
}

progress_done() {
    echo ""
}

show_welcome_arena() {
    local workdir=$1

    echo "# Тест на знание терминала Bash"
    echo "---------------------------------------------------------"
    echo "Откройте второе окно терминала для выполнения задач,"
    echo "перейдите в папку $workdir"
    echo "Нажмите [Enter], чтобы начать..."
    read -r || exit 1
}

# Текст задания из intro.txt (построчно, без подстановки имён файлов в glob).
print_task_file() {
    local path=$1
    local line

    while IFS= read -r line || [[ -n $line ]]; do
        echo "$(tpl_expand "$line")"
    done < "$path"
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

        printf "\r%s [%s%s] %d%%" "$title" "$fill_done" "$fill_rem" "$perc"
    fi
}

print_feedback_file() {
    local path=$1
    local ans="${2-}"
    local line

    if [[ ! -f "$path" ]]; then
        if [[ -n "$ans" ]]; then
            echo "$(tpl_expand "Ответ «@ans@» не подходит. Нет файла уведомления: ${path##*/}" "$ans")"
        else
            echo "Нет файла уведомления: ${path##*/}"
        fi

        return 1
    fi

    while IFS= read -r line || [[ -n $line ]]; do
        line="${line%$'\r'}"
        echo "$(tpl_expand "$line" "$ans")"
    done < "$path"
}

check_level_answer() {
    local correct=$1
    local path_ok=$2
    local path_reject=$3
    local input=""

    while true; do
        echo ""
        printf 'Ответ: '
        read -r input || return 1
        input="${input#"${input%%[![:space:]]*}"}"
        input="${input%"${input##*[![:space:]]}"}"

        if [[ "$input" == "$correct" ]]; then
            echo ""
            print_feedback_file "$path_ok"

            return 0
        fi

        echo ""
        print_feedback_file "$path_reject" "$input"
        echo ""
    done
}

show_outro_from_file() {
    local outro_path=$1
    local line

    FINAL_FLAG_ID=$(gen_id)

    echo ""

    while IFS= read -r line || [[ -n $line ]]; do
        line=$(tpl_expand "$line")
        [[ -z "${line// }" ]] && continue

        echo "$line"
    done < "$outro_path"

    echo ""
}

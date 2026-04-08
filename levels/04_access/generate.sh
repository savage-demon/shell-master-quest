# access.log: топ-3 IP по числу строк со STATUS:500 (строгий порядок без ничьих в топ-3).

T1="10.20.1.100"
T2="10.20.2.200"
T3="10.20.3.50"

LEVEL_CORRECT=$(printf '%s\n%s\n%s' "$T1" "$T2" "$T3")
LEVEL_ANSWER_MODE=lines
LEVEL_ANSWER_EXPECT_LINES=3

# Число ответов 500 для лидеров (строго убывает) и «шумовых» IP с 500 (все меньше T3).
N_T1=55
N_T2=40
N_T3=24
D1="192.168.91.7"
D2="172.31.200.1"
D3="10.99.1.2"
N_D1=14
N_D2=11
N_D3=9

_NOISE_LINES=1600
_TOTAL=$((N_T1 + N_T2 + N_T3 + N_D1 + N_D2 + N_D3 + _NOISE_LINES))

_access_ts() {
    printf '2026-04-08 %02d:%02d:%02d' $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60))
}

_access_emit() {
    local ip=$1 status=$2

    echo "$(_access_ts) IP:${ip} STATUS:${status} BYTES:$((RANDOM % 9000 + 128))"
}

: > access.log

_p=0

_bump() {
    ((_p++))
    show_progress "$_p" "$_TOTAL" "access.log"
}

_k=0

for ((_k = 0; _k < N_T1; _k++)); do
    _access_emit "$T1" 500 >> access.log
    _bump
done

for ((_k = 0; _k < N_T2; _k++)); do
    _access_emit "$T2" 500 >> access.log
    _bump
done

for ((_k = 0; _k < N_T3; _k++)); do
    _access_emit "$T3" 500 >> access.log
    _bump
done

for ((_k = 0; _k < N_D1; _k++)); do
    _access_emit "$D1" 500 >> access.log
    _bump
done

for ((_k = 0; _k < N_D2; _k++)); do
    _access_emit "$D2" 500 >> access.log
    _bump
done

for ((_k = 0; _k < N_D3; _k++)); do
    _access_emit "$D3" 500 >> access.log
    _bump
done

_rand_status() {
    case $((RANDOM % 10)) in
        0) echo 404 ;;
        1) echo 302 ;;
        *) echo 200 ;;
    esac
}

_rand_noise_ip() {
    echo "10.$((RANDOM % 200 + 40)).$((RANDOM % 255)).$((RANDOM % 254 + 1))"
}

for ((_k = 0; _k < _NOISE_LINES; _k++)); do
    _access_emit "$(_rand_noise_ip)" "$(_rand_status)" >> access.log
    _bump
done

sort -R access.log -o access.log

progress_done
echo "Готово: access.log (${_TOTAL} строк)."

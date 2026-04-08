# VPN-логи. Текущий каталог — $ROOT/level_1/$TARGET_SECTOR (после уровня shadow).

vpn_decoy_handoff_line() {
    local ts="2026-04-06T$(printf '%02d:%02d:%02d' $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60)))Z"

    case $((RANDOM % 6)) in
        0) echo "$ts tun0 event=handoff trace_exit_node=_" ;;
        1) echo "$ts tun0 event=handoff trace_exit_node=" ;;
        2) echo "$ts tun0 event=handoff trace_exit_node=NA" ;;
        3) echo "$ts tun0 event=handoff trace_exit_node=---" ;;
        4) echo "$ts tun0 event=handoff trace_exit_node=void" ;;
        5) echo "$ts tun0 event=handoff trace_exit_node=$(gen_name)" ;;
    esac
}

vpn_decoy_sess_noise_line() {
    local ts="2026-04-06T$(printf '%02d:%02d:%02d' $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60)))Z"
    local sid="sess$((100000 + RANDOM % 899999))"

    case $((RANDOM % 6)) in
        0) echo "$ts tun0 sess=${sid} event=keepalive peer=10.$((RANDOM % 255)).2" ;;
        1) echo "$ts tun0 sess=${sid} op=teardown reason=cleanup" ;;
        2) echo "$ts tun0 sess=${sid} event=rx_burst bytes=$((RANDOM % 9999))" ;;
        3) echo "$ts tun0 sess=${sid} event=handoff trace_exit_node=_" ;;
        4) echo "$ts tun0 sess=${sid} link_probe=wan state=idle" ;;
        5) echo "$ts tun0 sess=${sid} route_metric=$((RANDOM % 200)) flapping=0" ;;
    esac
}

TARGET_EXIT="$(gen_name)"
VPN_REAL_SESS="sess$(gen_id)"
VPN_REAL_TS="2026-04-06T$(printf '%02d:%02d:%02d' $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60)))Z"

LEVEL_CORRECT="$TARGET_EXIT"

for i in {1..380}; do
    {
        for j in {1..8}; do
            echo "2026-04-06T$(printf '%02d:%02d:%02d' $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60)))Z tun0 peer=10.$((RANDOM % 255)).1 op=rx state=ok"
        done
        for k in {1..6}; do
            vpn_decoy_handoff_line
        done
        for k in {1..5}; do
            vpn_decoy_sess_noise_line
        done
    } > "vpn_${i}.log"
    show_progress $i 380 "VPN-логи"
done

progress_done
{
    echo "${VPN_REAL_TS} tun0 sess=${VPN_REAL_SESS} event=handoff"
    echo "${VPN_REAL_TS} tun0 sess=${VPN_REAL_SESS} trace_exit_node=${TARGET_EXIT}"
} >> "vpn_$((RANDOM % 380 + 1)).log"
echo "Готово: созданы vpn_*.log (380 файлов)."

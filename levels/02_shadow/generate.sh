# Дамп shadow. Текущий каталог — $ROOT/level_2 (соседний с level_1, не вложенный).

S_NUM=$((10 + RANDOM % 89))
SEP="##${S_NUM}!!$((RANDOM % 99))"
V_ID=$(gen_id)
LEVEL_CORRECT="$V_ID"

HDR="type${SEP}date${SEP}ts_utc${SEP}uid${SEP}login${SEP}gecos${SEP}shell${SEP}home${SEP}gid${SEP}realm${SEP}code${SEP}quota${SEP}flags${SEP}attr${SEP}level"

echo "$HDR" > shadow_fragment.db
line="user${SEP}2026-04-06${SEP}1712448000${SEP}1001${SEP}dummy${SEP}stub${SEP}/bin/sh${SEP}/tmp${SEP}1000${SEP}vault${SEP}000000${SEP}0${SEP}0x0${SEP}none${SEP}low"

for i in {1..50}; do
    { for j in {1..100}; do echo "$line"; done; } >> shadow_fragment.db
    show_progress $((i * 100)) 5000 "shadow_fragment.db"
done

progress_done
echo "svc${SEP}2026-04-06${SEP}$(date +%s)${SEP}9999${SEP}op-core${SEP}Maint${SEP}/bin/bash${SEP}/root${SEP}0${SEP}core${SEP}$V_ID${SEP}0${SEP}0x1${SEP}live${SEP}operator" >> shadow_fragment.db
echo "Готово: файл shadow_fragment.db создан."

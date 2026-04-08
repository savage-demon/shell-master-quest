# Уровень: пересечение истории shell и списка секторов. Текущий каталог — $ROOT/level_1.

S_TARGET_LO=1000
S_TARGET_SPAN=2500
S_HIST_LO=5000
S_HIST_SPAN=2000
S_DB_LO=7000
S_DB_SPAN=2000
TARGET_VAL=$((S_TARGET_LO + RANDOM % S_TARGET_SPAN))
TARGET_SECTOR="sector_$TARGET_VAL"
export TARGET_SECTOR

LEVEL_CORRECT="$TARGET_SECTOR"

_L2_PROGRESS_TOTAL=700

: > shell_history.log

for i in {1..350}; do
    echo "cd sector_$((S_HIST_LO + RANDOM % S_HIST_SPAN))" >> shell_history.log
    echo "ls -la" >> shell_history.log
    show_progress "$i" "$_L2_PROGRESS_TOTAL" "Синхронизация"
done

echo "cd $TARGET_SECTOR" >> shell_history.log
echo "exit" >> shell_history.log

: > available_sectors.db

for i in {1..350}; do
    echo "sector_$((S_DB_LO + RANDOM % S_DB_SPAN))" >> available_sectors.db
    show_progress "$((350 + i))" "$_L2_PROGRESS_TOTAL" "Синхронизация"
done

echo "$TARGET_SECTOR" >> available_sectors.db
sort -R available_sectors.db -o available_sectors.db

progress_done
echo "Готово: файлы shell_history.log и available_sectors.db созданы."

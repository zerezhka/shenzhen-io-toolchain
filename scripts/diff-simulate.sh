#!/bin/bash
# Дифф-обвязка: сравнивает вывод `simulate` у C#-оракула и Zig-версии.
# Использование:
#   scripts/diff-simulate.sh [файлы или директории с .asm]
# Без аргументов гоняет все .asm из tests/simulate/.
#
# Сравнивает acc, dat, cycles. Формат Zig: acc=N dat=N cycles=N
# C# выводит развёрнутый блок — скрипт нормализует его в тот же формат.
#
# Статусы:
#   PASS      — acc/dat/cycles совпали
#   DIFF      — оба отработали, значения разные
#   ZIG-FAIL  — C# справился, Zig упал
#   CS-FAIL   — упал сам оракул

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CS_SIO="$ROOT/sio"
ZIG_SIO="$ROOT/zig/zig-out/bin/sio"

if ! "$CS_SIO" 2>&1 | grep -q Usage; then
    echo "error: C#-оракул не запускается" >&2
    exit 2
fi
(cd "$ROOT/zig" && zig build) || { echo "error: zig build упал" >&2; exit 2; }

extract_cs() {
    local out="$1"
    local acc dat cyc
    acc=$(echo "$out" | grep 'ACC:' | awk '{print $2}')
    dat=$(echo "$out" | grep 'DAT:' | awk '{print $2}')
    cyc=$(echo "$out" | grep 'Cycles:' | awk '{print $2}')
    echo "acc=$acc dat=$dat cycles=$cyc"
}

files=()
for arg in "${@:-$ROOT/tests/simulate}"; do
    if [ -d "$arg" ]; then
        while IFS= read -r f; do files+=("$f"); done < <(find "$arg" -name '*.asm' | sort)
    else
        files+=("$arg")
    fi
done

pass=0 diff_=0 zig_fail=0 cs_fail=0
for f in "${files[@]}"; do
    rel="${f#"$ROOT"/}"
    cs_raw="$("$CS_SIO" simulate "$f" 2>/dev/null)"; cs_rc=$?
    zig_raw="$("$ZIG_SIO" simulate "$f" 2>/dev/null)"; zig_rc=$?

    if [ $cs_rc -ne 0 ]; then
        echo "CS-FAIL   $rel"; ((cs_fail++)); continue
    fi
    if [ $zig_rc -ne 0 ]; then
        echo "ZIG-FAIL  $rel"; ((zig_fail++)); continue
    fi

    cs_norm=$(extract_cs "$cs_raw")
    zig_norm="$zig_raw"

    if [ "$cs_norm" = "$zig_norm" ]; then
        echo "PASS      $rel"; ((pass++))
    else
        echo "DIFF      $rel"; ((diff_++))
        if [ "${VERBOSE:-0}" = "1" ]; then
            echo "    C#:  $cs_norm"
            echo "    Zig: $zig_norm"
        fi
    fi
done

total=$((pass + diff_ + zig_fail + cs_fail))
echo "---"
echo "total: $total  pass: $pass  diff: $diff_  zig-fail: $zig_fail  cs-fail: $cs_fail"
[ $diff_ -gt 0 ] || [ $zig_fail -gt 0 ] && echo "(подробности: VERBOSE=1 $0 ...)"
[ $((diff_ + zig_fail + cs_fail)) -eq 0 ]

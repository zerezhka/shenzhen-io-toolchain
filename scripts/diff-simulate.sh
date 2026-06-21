#!/bin/bash
# Дифф-обвязка: сравнивает вывод `simulate` у C#-оракула и Zig-версии.
# Использование:
#   scripts/diff-simulate.sh [--trace] [файлы или директории с .asm]
# Без аргументов гоняет все .asm из tests/simulate/.
#
# Без --trace: сравнивает acc, dat, cycles.
# С --trace: дополнительно сравнивает последовательность выполненных операций.
#   C# trace: "CYCLE:Instruction:OP ARGS", Zig trace (stderr): "cycle=N pc=N op=OP acc=N dat=N"
#   Нормализуем оба в список мнемоник (без sleep-тактов и skipped).
#
# Статусы:
#   PASS      — всё совпало
#   DIFF      — оба отработали, значения разные
#   ZIG-FAIL  — C# справился, Zig упал
#   CS-FAIL   — упал сам оракул

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CS_SIO="$ROOT/sio"
ZIG_SIO="$ROOT/zig/zig-out/bin/sio"

TRACE=0
if [ "${1:-}" = "--trace" ]; then
    TRACE=1
    shift
fi

if ! "$CS_SIO" 2>&1 | grep -q Usage; then
    echo "error: C#-оракул не запускается" >&2
    exit 2
fi
(cd "$ROOT/zig" && zig build) || { echo "error: zig build упал" >&2; exit 2; }

extract_cs_state() {
    local out="$1"
    local acc dat cyc p0 p1 p2 p3 p4 p5
    acc=$(echo "$out" | grep 'ACC:' | awk '{print $2}')
    dat=$(echo "$out" | grep 'DAT:' | awk '{print $2}')
    cyc=$(echo "$out" | grep 'Cycles:' | awk '{print $2}')
    p0=$(echo "$out" | grep 'p0:' | awk '{print $2}')
    p1=$(echo "$out" | grep 'p1:' | awk '{print $2}')
    p2=$(echo "$out" | grep 'p2:' | awk '{print $2}')
    p3=$(echo "$out" | grep 'p3:' | awk '{print $2}')
    p4=$(echo "$out" | grep 'p4:' | awk '{print $2}')
    p5=$(echo "$out" | grep 'p5:' | awk '{print $2}')
    echo "acc=$acc dat=$dat cycles=$cyc p0=$p0 p1=$p1 p2=$p2 p3=$p3 p4=$p4 p5=$p5"
}

# C# trace: "0:Instruction:mov 5 acc" → "mov"
extract_cs_ops() {
    echo "$1" | grep ':Instruction:' | sed 's/.*:Instruction://' | awk '{print $1}'
}

# Zig trace (stderr): "cycle=1 pc=0 op=mov acc=1 dat=0" → "mov"
# Filter out sleep ticks (op=slp with same pc as previous slp)
extract_zig_ops() {
    echo "$1" | grep '^cycle=' | sed 's/.*op=\([^ ]*\).*/\1/' | awk '
        { if ($1 == "slp" && prev == "slp") next; prev = $1; print }
    '
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

    if [ $TRACE -eq 1 ]; then
        cs_raw="$("$CS_SIO" simulate "$f" --trace 2>/dev/null)"; cs_rc=$?
        zig_stdout="$("$ZIG_SIO" simulate "$f" --trace 2>/tmp/_zig_trace)"; zig_rc=$?
        zig_trace=$(cat /tmp/_zig_trace)
    else
        cs_raw="$("$CS_SIO" simulate "$f" 2>/dev/null)"; cs_rc=$?
        zig_stdout="$("$ZIG_SIO" simulate "$f" 2>/dev/null)"; zig_rc=$?
    fi

    if [ $cs_rc -ne 0 ]; then
        echo "CS-FAIL   $rel"; ((cs_fail++)); continue
    fi
    if [ $zig_rc -ne 0 ]; then
        echo "ZIG-FAIL  $rel"; ((zig_fail++)); continue
    fi

    cs_state=$(extract_cs_state "$cs_raw")
    zig_state="$zig_stdout"
    ok=1

    if [ "$cs_state" != "$zig_state" ]; then
        ok=0
    fi

    if [ $TRACE -eq 1 ] && [ $ok -eq 1 ]; then
        cs_ops=$(extract_cs_ops "$cs_raw")
        zig_ops=$(extract_zig_ops "$zig_trace")
        if [ "$cs_ops" != "$zig_ops" ]; then
            ok=0
        fi
    fi

    if [ $ok -eq 1 ]; then
        echo "PASS      $rel"; ((pass++))
    else
        echo "DIFF      $rel"; ((diff_++))
        if [ "${VERBOSE:-0}" = "1" ]; then
            echo "    state C#:  $cs_state"
            echo "    state Zig: $zig_state"
            if [ $TRACE -eq 1 ]; then
                echo "    trace diff:"
                diff <(echo "$cs_ops") <(echo "$zig_ops") | sed 's/^/      /'
            fi
        fi
    fi
done

rm -f /tmp/_zig_trace
total=$((pass + diff_ + zig_fail + cs_fail))
echo "---"
echo "total: $total  pass: $pass  diff: $diff_  zig-fail: $zig_fail  cs-fail: $cs_fail"
[ $diff_ -gt 0 ] || [ $zig_fail -gt 0 ] && echo "(подробности: VERBOSE=1 $0 ...)"
[ $((diff_ + zig_fail + cs_fail)) -eq 0 ]

#!/bin/bash
# Дифф-обвязка: сравнивает вывод `assemble` у C#-оракула и Zig-версии.
# Использование:
#   scripts/diff-zig-cs.sh [файлы или директории с .asm]
# Без аргументов гоняет все .asm из examples/.
#
# Статусы:
#   PASS      — вывод совпал
#   DIFF      — оба отработали, вывод разный (баг или нереализованный extended)
#   ZIG-FAIL  — C# справился, Zig упал (честная ошибка лучше тихого DIFF)
#   CS-FAIL   — упал сам оракул (файл битый? мира больше нет?)

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CS_SIO="$ROOT/sio"
ZIG_SIO="$ROOT/zig/zig-out/bin/sio"

# у C#-CLI нет --version; признак жизни — usage-подсказка
if ! "$CS_SIO" 2>&1 | grep -q Usage; then
    echo "error: C#-оракул не запускается (собери: cd src && msbuild Sio.Cli/Sio.Cli.csproj)" >&2
    exit 2
fi
(cd "$ROOT/zig" && zig build) || { echo "error: zig build упал" >&2; exit 2; }

# Собираем список файлов
files=()
for arg in "${@:-$ROOT/examples}"; do
    if [ -d "$arg" ]; then
        while IFS= read -r f; do files+=("$f"); done < <(find "$arg" -name '*.asm' | sort)
    else
        files+=("$arg")
    fi
done

pass=0 diff_=0 zig_fail=0 cs_fail=0
for f in "${files[@]}"; do
    rel="${f#"$ROOT"/}"
    cs_out="$("$CS_SIO" assemble "$f" 2>/dev/null)"; cs_rc=$?
    zig_out="$("$ZIG_SIO" assemble "$f" 2>/dev/null)"; zig_rc=$?

    if [ $cs_rc -ne 0 ]; then
        echo "CS-FAIL   $rel"; ((cs_fail++)); continue
    fi
    if [ $zig_rc -ne 0 ]; then
        echo "ZIG-FAIL  $rel"; ((zig_fail++)); continue
    fi
    if [ "$cs_out" = "$zig_out" ]; then
        echo "PASS      $rel"; ((pass++))
    else
        echo "DIFF      $rel"; ((diff_++))
        if [ "${VERBOSE:-0}" = "1" ]; then
            diff <(printf '%s\n' "$cs_out") <(printf '%s\n' "$zig_out") | sed 's/^/    /'
        fi
    fi
done

total=$((pass + diff_ + zig_fail + cs_fail))
echo "---"
echo "total: $total  pass: $pass  diff: $diff_  zig-fail: $zig_fail  cs-fail: $cs_fail"
echo "(подробности диффа: VERBOSE=1 $0 ...)"
[ $((diff_ + zig_fail + cs_fail)) -eq 0 ]

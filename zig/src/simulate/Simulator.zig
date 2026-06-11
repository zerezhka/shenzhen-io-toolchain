const std = @import("std");
const Parser = @import("../parse/Parser.zig");

/// Регистры/счётчик/флаги одного MCU.
/// Зеркалит Sio.Simulator.Cpu.CpuState из C#.
pub const Cpu = struct {
    acc: i32 = 0,
    /// dat есть только на MC6000. null => регистра нет (MC4000).
    dat: ?i32 = null,
    pc: usize = 0,

    /// Состояние условного исполнения:
    /// true  => включены инструкции с префиксом '+',
    /// false => включены инструкции с префиксом '-'.
    /// Изначально false.
    conditional_positive: bool = false,
    /// После tcp при равенстве — выключены и '+', и '-'.
    conditional_equal: bool = false,

    pub fn init(has_dat: bool) Cpu {
        if (has_dat) {
            return Cpu{
                .dat = 0,
            };
        } else {
            return Cpu{};
        }
    }

    /// Регистры зажаты в диапазон [-999, 999].
    pub fn clamp(value: i32) i32 {
        if (value < -999)
            return -999
        else if (value > 999)
            return 999
        else
            return value;
    }

    pub fn setAcc(self: *Cpu, value: i32) void {
        self.acc = clamp(value);
    }

    pub fn setDat(self: *Cpu, value: i32) !void {
        if (self.dat != null) {
            self.dat = clamp(value);
        } else {
            return error.DatNotAvailable;
        }
    }
};

/// Предекодированный операнд. Вместо того чтобы на каждом цикле парсить
/// строку (как C# Decoder.ResolveOperand), разбираем один раз при build.
/// Метку держим как имя — резолвим в PC на исполнении через Program.labels
/// (иначе forward-прыжки требовали бы второго прохода).
pub const Operand = union(enum) {
    imm: i32,
    acc,
    dat,
    nul, // ключевое слово `null` — читается как 0, запись игнорируется
    port: u8, // p0..pN  (x-порты/xbus добавим на шаге портов)
    label: []const u8,
};

/// Разбирает текст операнда в Operand.
/// Порядок проверок: число -> acc/dat/null -> pN -> иначе метка.
/// Immediate сразу зажимаем в [-999, 999] (как ClampValue в C#).
pub fn decodeOperand(text: []const u8) Operand {
    // число -> .imm (parseInt возвращает error-union: ловим, при провале идём дальше)
    if (std.fmt.parseInt(i32, text, 10)) |n| {
        return Operand{ .imm = Cpu.clamp(n) };
    } else |_| {}

    // ключевые слова
    if (std.mem.eql(u8, text, "acc")) return .acc;
    if (std.mem.eql(u8, text, "dat")) return .dat;
    if (std.mem.eql(u8, text, "null")) return .nul;

    // порт pN
    if (text.len >= 2 and text[0] == 'p') {
        if (std.fmt.parseInt(u8, text[1..], 10)) |idx| {
            return Operand{ .port = idx };
        } else |_| {}
    }

    // иначе — имя метки
    return Operand{ .label = text };
}

/// Ошибки чтения операнда.
pub const ReadError = error{
    /// dat есть только на MC6000 (cpu.dat == null на MC4000).
    DatNotAvailable,
    /// Порты — шаг 5.9; метки как читаемые значения — решится в 5.3.
    NotYetImplemented,
};

/// ШАГ 5.1 (тело пишешь ты): значение операнда при чтении.
/// Аналог `Decoder.ResolveOperand` из C#, но без парсинга строк — вид
/// операнда уже известен после предекода:
///   .imm   → само значение (зажато ещё в decodeOperand),
///   .acc   → cpu.acc,
///   .dat   → регистр, а на MC4000 (dat == null) → error.DatNotAvailable,
///   .nul   → 0 (чтение `null` всегда даёт ноль),
///   .port / .label → error.NotYetImplemented (шаги 5.9 / 5.3).
pub fn read(cpu: *const Cpu, operand: Operand) ReadError!i32 {
    _ = cpu;
    _ = operand;
    return error.NotYetImplemented; // TODO(5.1): замени на switch по operand
}

/// Одна исполняемая инструкция: метки уже разложены в `Program.labels`,
/// операнды предекодированы.
pub const ExecInstruction = struct {
    op: Parser.Mnemonic,
    condition: ?Parser.Condition,
    operands: []Operand,
};

/// Плоская программа: список инструкций + карта меток.
/// PC индексирует `instructions`.
pub const Program = struct {
    instructions: []ExecInstruction,
    labels: std.StringHashMap(usize),

    pub fn deinit(self: *Program, allocator: std.mem.Allocator) void {
        for (self.instructions) |value| {
            allocator.free(value.operands);
        }
        // for (self.labels) |label| {
        //     allocator.free(label);
        // }
        allocator.free(self.instructions);
        self.labels.deinit();
    }
};

/// Превращает разобранную `Parser.Program` в плоскую исполняемую форму.
/// Метки выкидываются из потока инструкций и мапятся на индекс следующей.
pub fn build(allocator: std.mem.Allocator, parsed: Parser.Program) !Program {
    var instructions = std.ArrayList(ExecInstruction).empty;
    var labels = std.StringHashMap(usize).init(allocator);

    for (parsed.statements) |stmt| switch (stmt) {
    // встретили метку: запоминаем, на какой индекс она смотрит.
    // instructions.items.len = сколько инструкций уже накопили =
    //   = индекс СЛЕДУЮЩЕЙ, которую вот-вот добавим. Ровно туда метка и показывает.
          .label => |name| try labels.put(name, instructions.items.len),

        // встретили инструкцию: надо предекодить её операнды и положить в массив.
          .instruction => |instr| {
            // отдельный накопитель под операнды ЭТОЙ инструкции
              var ops = std.ArrayList(Operand).empty;
            for (instr.operands) |raw| {
                try ops.append(allocator, decodeOperand(raw));
            }
            // собираем готовую инструкцию и кладём в общий массив
              try instructions.append(allocator, ExecInstruction{
                .op = instr.op,
                .condition = instr.condition,
                .operands = try ops.toOwnedSlice(allocator),
            });
        },
    };

    return Program{
        .instructions = try instructions.toOwnedSlice(allocator),
        .labels = labels,
    };
}

test "build flattens labels out of the instruction stream" {
    const parsed = try Parser.parse(std.testing.allocator, "loop:\nadd 1\njmp loop");
    defer parsed.deinit(std.testing.allocator);

    var program = try build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 2), program.instructions.len);
    try std.testing.expectEqual(Parser.Mnemonic.add, program.instructions[0].op);
    try std.testing.expectEqual(Parser.Mnemonic.jmp, program.instructions[1].op);
    try std.testing.expectEqual(@as(usize, 0), program.labels.get("loop").?);

    // operands предекодированы: "1" -> .imm, "loop" -> .label
    try std.testing.expect(program.instructions[0].operands[0] == .imm);
    try std.testing.expectEqual(@as(i32, 1), program.instructions[0].operands[0].imm);
    try std.testing.expect(program.instructions[1].operands[0] == .label);
    try std.testing.expectEqualStrings("loop", program.instructions[1].operands[0].label);
}

test "decodeOperand classifies each operand kind" {
    try std.testing.expectEqual(@as(i32, 42), decodeOperand("42").imm);
    try std.testing.expectEqual(@as(i32, -7), decodeOperand("-7").imm);
    try std.testing.expectEqual(@as(i32, 999), decodeOperand("1500").imm); // зажат
    try std.testing.expect(decodeOperand("acc") == .acc);
    try std.testing.expect(decodeOperand("dat") == .dat);
    try std.testing.expect(decodeOperand("null") == .nul);
    try std.testing.expectEqual(@as(u8, 3), decodeOperand("p3").port);
    try std.testing.expect(decodeOperand("loop") == .label);
}

test "label at end maps to one-past-last index" {
    const parsed = try Parser.parse(std.testing.allocator, "nop\ndone:");
    defer parsed.deinit(std.testing.allocator);

    var program = try build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), program.instructions.len);
    try std.testing.expectEqual(@as(usize, 1), program.labels.get("done").?);
}

// --- Шаг 5.1: тесты-задание. Сделай read() так, чтобы всё позеленело. ---

test "5.1 read: immediate returns its value" {
    const cpu = Cpu.init(false);
    try std.testing.expectEqual(@as(i32, 42), try read(&cpu, .{ .imm = 42 }));
    try std.testing.expectEqual(@as(i32, -7), try read(&cpu, .{ .imm = -7 }));
}

test "5.1 read: acc returns register value" {
    var cpu = Cpu.init(false);
    cpu.setAcc(123);
    try std.testing.expectEqual(@as(i32, 123), try read(&cpu, .acc));
}

test "5.1 read: dat on MC6000 returns register value" {
    var cpu = Cpu.init(true);
    try cpu.setDat(-55);
    try std.testing.expectEqual(@as(i32, -55), try read(&cpu, .dat));
}

test "5.1 read: dat on MC4000 is an error" {
    const cpu = Cpu.init(false);
    try std.testing.expectError(error.DatNotAvailable, read(&cpu, .dat));
}

test "5.1 read: null reads as zero" {
    var cpu = Cpu.init(false);
    cpu.setAcc(999); // чтение null не должно зависеть от состояния cpu
    try std.testing.expectEqual(@as(i32, 0), try read(&cpu, .nul));
}

test "5.1 read: ports and labels are not implemented yet" {
    const cpu = Cpu.init(false);
    try std.testing.expectError(error.NotYetImplemented, read(&cpu, .{ .port = 0 }));
    try std.testing.expectError(error.NotYetImplemented, read(&cpu, .{ .label = "loop" }));
}

test "cpu clamps registers" {
    try std.testing.expectEqual(@as(i32, 999), Cpu.clamp(1500));
    try std.testing.expectEqual(@as(i32, -999), Cpu.clamp(-1500));
    try std.testing.expectEqual(@as(i32, 42), Cpu.clamp(42));
}

const std = @import("std");

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
    nul,
    port: u8,
    label: []const u8,
    target: usize,
};

/// Разбирает текст операнда в Operand.
/// Порядок проверок: число -> acc/dat/null -> pN -> иначе метка.
/// Immediate сразу зажимаем в [-999, 999] (как ClampValue в C#).
pub fn decodeOperand(text: []const u8) Operand {
    if (std.fmt.parseInt(i32, text, 10)) |n| {
        return Operand{ .imm = Cpu.clamp(n) };
    } else |_| {}

    if (std.mem.eql(u8, text, "acc")) return .acc;
    if (std.mem.eql(u8, text, "dat")) return .dat;
    if (std.mem.eql(u8, text, "null")) return .nul;

    if (text.len >= 2 and text[0] == 'p') {
        if (std.fmt.parseInt(u8, text[1..], 10)) |idx| {
            return Operand{ .port = idx };
        } else |_| {}
    }

    return Operand{ .label = text };
}

/// Ошибки чтения операнда.
pub const ReadError = error{
    DatNotAvailable,
    NotYetImplemented,
};

/// Значение операнда при чтении.
pub fn read(cpu: *const Cpu, operand: Operand) ReadError!i32 {
    return switch (operand) {
        .imm => |val| val,
        .acc => cpu.acc,
        .dat => if (cpu.dat) |val| val else error.DatNotAvailable,
        .nul => 0,

        .target => error.NotYetImplemented,
        .label => error.NotYetImplemented,
        .port => error.NotYetImplemented,
    };
}

/// Запись значения в операнд.
pub fn write(cpu: *Cpu, operand: Operand, value: i32) !void {
    return switch (operand) {
        .acc => { cpu.setAcc(value); },
        .dat => try cpu.setDat(value),
        .nul => {},
        .imm, .target, .label, .port => error.NotYetImplemented,
    };
}

// --- Tests ---

test "decodeOperand classifies each operand kind" {
    try std.testing.expectEqual(@as(i32, 42), decodeOperand("42").imm);
    try std.testing.expectEqual(@as(i32, -7), decodeOperand("-7").imm);
    try std.testing.expectEqual(@as(i32, 999), decodeOperand("1500").imm);
    try std.testing.expect(decodeOperand("acc") == .acc);
    try std.testing.expect(decodeOperand("dat") == .dat);
    try std.testing.expect(decodeOperand("null") == .nul);
    try std.testing.expectEqual(@as(u8, 3), decodeOperand("p3").port);
    try std.testing.expect(decodeOperand("loop") == .label);
}

test "cpu clamps registers" {
    try std.testing.expectEqual(@as(i32, 999), Cpu.clamp(1500));
    try std.testing.expectEqual(@as(i32, -999), Cpu.clamp(-1500));
    try std.testing.expectEqual(@as(i32, 42), Cpu.clamp(42));
}

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
    cpu.setAcc(999);
    try std.testing.expectEqual(@as(i32, 0), try read(&cpu, .nul));
}

test "5.1 read: ports and labels are not implemented yet" {
    const cpu = Cpu.init(false);
    try std.testing.expectError(error.NotYetImplemented, read(&cpu, .{ .port = 0 }));
    try std.testing.expectError(error.NotYetImplemented, read(&cpu, .{ .label = "loop" }));
}

test "5.2 write: acc writes to register" {
    var cpu = Cpu.init(false);
    try write(&cpu, .acc, 42);
    try std.testing.expectEqual(@as(i32, 42), cpu.acc);
    try write(&cpu, .acc, -7);
    try std.testing.expectEqual(@as(i32, -7), cpu.acc);
}

test "5.2 write: dat on MC6000 writes to register" {
    var cpu = Cpu.init(true);
    try write(&cpu, .dat, 55);
    try std.testing.expectEqual(@as(i32, 55), cpu.dat.?);
    try write(&cpu, .dat, -99);
    try std.testing.expectEqual(@as(i32, -99), cpu.dat.?);
}

test "5.2 write: dat on MC4000 is an error" {
    var cpu = Cpu.init(false);
    try std.testing.expectError(error.DatNotAvailable, write(&cpu, .dat, 42));
}

test "5.2 write: null discards value silently" {
    var cpu = Cpu.init(false);
    cpu.setAcc(100);
    try write(&cpu, .nul, 42);
    try std.testing.expectEqual(@as(i32, 100), cpu.acc);
}

test "5.2 write: imm/label/port are not lvalues" {
    var cpu = Cpu.init(false);
    try std.testing.expectError(error.NotYetImplemented, write(&cpu, .{ .imm = 0 }, 42));
    try std.testing.expectError(error.NotYetImplemented, write(&cpu, .{ .label = "loop" }, 42));
    try std.testing.expectError(error.NotYetImplemented, write(&cpu, .{ .port = 0 }, 42));
}

test "5.2 write: acc clamps values" {
    var cpu = Cpu.init(false);
    try write(&cpu, .acc, 1500);
    try std.testing.expectEqual(@as(i32, 999), cpu.acc);
    try write(&cpu, .acc, -2000);
    try std.testing.expectEqual(@as(i32, -999), cpu.acc);
}

const std = @import("std");
const Parser = @import("../parse/Parser.zig");
const CpuModule = @import("Cpu.zig");
pub const Cpu = CpuModule.Cpu;
pub const Operand = CpuModule.Operand;
pub const decodeOperand = CpuModule.decodeOperand;
pub const read = CpuModule.read;
pub const write = CpuModule.write;

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
        // TODO: ownership — labels are borrowed from parsed, not owned
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

    // operands предекодированы: "1" -> .imm, "loop" -> .target (resolved)
    try std.testing.expect(program.instructions[0].operands[0] == .imm);
    try std.testing.expectEqual(@as(i32, 1), program.instructions[0].operands[0].imm);
    try std.testing.expect(program.instructions[1].operands[0] == .target);
    try std.testing.expectEqual(@as(usize, 0), program.instructions[1].operands[0].target);
}

test "label at end maps to one-past-last index" {
    const parsed = try Parser.parse(std.testing.allocator, "nop\ndone:");
    defer parsed.deinit(std.testing.allocator);

    var program = try build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), program.instructions.len);
    try std.testing.expectEqual(@as(usize, 1), program.labels.get("done").?);
}

// --- Шаг 5.3: label → target resolution в build() ---

test "5.3 build resolves label to target index" {
    const parsed = try Parser.parse(std.testing.allocator, "loop:\nnop\njmp loop");
    defer parsed.deinit(std.testing.allocator);

    var program = try build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    // jmp loop → .target = 0 (loop: points at instruction 0)
    try std.testing.expect(program.instructions[1].operands[0] == .target);
    try std.testing.expectEqual(@as(usize, 0), program.instructions[1].operands[0].target);
}

test "5.3 build resolves forward jump" {
    const parsed = try Parser.parse(std.testing.allocator, "jmp end\nnop\nend:");
    defer parsed.deinit(std.testing.allocator);

    var program = try build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    // jmp end → .target = 2 (end: is past last instruction)
    try std.testing.expect(program.instructions[0].operands[0] == .target);
    try std.testing.expectEqual(@as(usize, 2), program.instructions[0].operands[0].target);
}

test "5.3 build errors on unknown label" {
    const parsed = try Parser.parse(std.testing.allocator, "jmp nowhere");
    defer parsed.deinit(std.testing.allocator);

    const result = build(std.testing.allocator, parsed);
    try std.testing.expectError(error.UnknownLabel, result);
}

test "5.3 non-label operands are untouched" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 42 acc");
    defer parsed.deinit(std.testing.allocator);

    var program = try build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    try std.testing.expect(program.instructions[0].operands[0] == .imm);
    try std.testing.expect(program.instructions[0].operands[1] == .acc);
}

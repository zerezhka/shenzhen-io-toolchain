const std = @import("std");
const Tokenizer = @import("Tokenizer.zig");

const Operand = []const u8;
pub const Condition = enum {
    positive,
    negative,
};
pub const Mnemonic = enum {
    // basic
    nop,
    mov,
    jmp,
    slp,
    slx,
    // test
    teq,
    tgt,
    tlt,
    tcp,
    // arithmetic
    add,
    sub,
    mul,
    not,
    dgt,
    dst,
    // undocumented
    gen,
    @"@",
};

const Instruction = struct {
    condition: ?Condition,
    op: Mnemonic,
    operands: []Operand,
};
pub const Statement = union(enum) {
    label: []const u8,
    instruction: Instruction,
};
pub const Program = struct {
    statements: []Statement,

    pub fn deinit(self: Program, allocator: std.mem.Allocator) void {
        for (self.statements) |s| {
            switch (s) {
                .instruction => |instr| allocator.free(instr.operands),
                .label => {},
            }
        }
        allocator.free(self.statements);
    }
};
pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Program {
    const tokens = try Tokenizer.tokenize(allocator, source);
    defer allocator.free(tokens);


    var statements = std.ArrayList(Statement).empty;
    var i: usize = 0;
    while (i < tokens.len) {
        const token = tokens[i];
        // some logic
          switch (token.type) {
            .end_of_file => break,
            .new_line => {
                i += 1;
            },
            .condition => {
                const cond: Condition = if (token.value[0] == '+') .positive else .negative;
                i += 1;
                if (i >= tokens.len or tokens[i].type != .identifier) return error.ExpectedInstruction;
                try appendInstruction(allocator, &statements, tokens, &i, cond);
            },
            .identifier => {
                if (i + 1 < tokens.len and tokens[i + 1].type == .colon) {
                    try statements.append(allocator, Statement{ .label = token.value });
                    i += 2;
                    // if something follows on the same line — let the loop handle it
                } else {
                    try appendInstruction(allocator, &statements, tokens, &i, null);
                }
            },
            else => return error.UnexpectedToken,
        }
    }

    return Program{ .statements = try statements.toOwnedSlice(allocator) };
}
/// Читает мнемонику из tokens[i], её операнды и кладёт инструкцию в statements.
/// `i` должен указывать на identifier-токен мнемоники; на выходе сдвинут за операнды.
fn appendInstruction(
    allocator: std.mem.Allocator,
    statements: *std.ArrayList(Statement),
    tokens: []Tokenizer.Token,
    i: *usize,
    cond: ?Condition,
) !void {
    const mnemonic = parseMnemonic(tokens[i.*].value) orelse return error.UnknownInstruction;
    i.* += 1;
    // TODO(silent-fail): число операндов не проверяется — `mov` без операндов или
    // `jmp a b c` парсятся молча, и эмиттер выпустит код, который игра не
    // примет. Нужна проверка числа операндов по мнемонике (одна на оба пути:
    // assemble и build() симулятора).
    const operands = try parseOperands(allocator, tokens, i);
    try statements.append(allocator, Statement{ .instruction = .{
        .condition = cond,
        .op = mnemonic,
        .operands = operands,
    } });
}

const mnemonic_map = std.StaticStringMap(Mnemonic).initComptime(.{
    .{ "nop", Mnemonic.nop },
    .{ "mov", Mnemonic.mov },
    .{ "jmp", Mnemonic.jmp },
    .{ "slp", Mnemonic.slp },
    .{ "slx", Mnemonic.slx },
    .{ "teq", Mnemonic.teq },
    .{ "tgt", Mnemonic.tgt },
    .{ "tlt", Mnemonic.tlt },
    .{ "tcp", Mnemonic.tcp },
    .{ "add", Mnemonic.add },
    .{ "sub", Mnemonic.sub },
    .{ "mul", Mnemonic.mul },
    .{ "not", Mnemonic.not },
    .{ "dgt", Mnemonic.dgt },
    .{ "dst", Mnemonic.dst },
    .{ "gen", Mnemonic.gen },
    .{ "@", Mnemonic.@"@" },
});

fn parseMnemonic(value: []const u8) ?Mnemonic {
    return mnemonic_map.get(value);
}

fn parseOperands(allocator: std.mem.Allocator, tokens: []Tokenizer.Token, i: *usize) ![]Operand {
    var operands = std.ArrayList(Operand).empty;
    while (i.* < tokens.len) {
        const t = tokens[i.*];
        if (t.type == .new_line or t.type == .end_of_file) break;
        if (t.type == .identifier or t.type == .number) {
            try operands.append(allocator, t.value);
            i.* += 1;
        } else return error.UnexpectedToken;
    }
    return operands.toOwnedSlice(allocator);
}

// Tests written by Claude Sonnet 4.6
test "parse simple instruction" {
    const program = try parse(std.testing.allocator, "mov acc 1");
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), program.statements.len);
    const instr = program.statements[0].instruction;
    try std.testing.expectEqual(Mnemonic.mov, instr.op);
    try std.testing.expectEqual(@as(usize, 2), instr.operands.len);
    try std.testing.expectEqualStrings("acc", instr.operands[0]);
    try std.testing.expectEqualStrings("1", instr.operands[1]);
}

test "parse label" {
    const program = try parse(std.testing.allocator, "loop:");
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), program.statements.len);
    try std.testing.expectEqualStrings("loop", program.statements[0].label);
}

test "parse label and instruction" {
    const program = try parse(std.testing.allocator, "loop:\njmp loop");
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 2), program.statements.len);
    try std.testing.expectEqualStrings("loop", program.statements[0].label);
    try std.testing.expectEqual(Mnemonic.jmp, program.statements[1].instruction.op);
    try std.testing.expectEqualStrings("loop", program.statements[1].instruction.operands[0]);
}

test "parse conditional instruction" {
    const program = try parse(std.testing.allocator, "+ mov acc 1");
    defer program.deinit(std.testing.allocator);

    const instr = program.statements[0].instruction;
    try std.testing.expectEqual(Condition.positive, instr.condition.?);
    try std.testing.expectEqual(Mnemonic.mov, instr.op);
}

test "parse negative condition" {
    const program = try parse(std.testing.allocator, "- jmp loop");
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(Condition.negative, program.statements[0].instruction.condition.?);
}

test "parse label and instruction on same line" {
    const program = try parse(std.testing.allocator, "a:+ mov acc 1");
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 2), program.statements.len);
    try std.testing.expectEqualStrings("a", program.statements[0].label);
    try std.testing.expectEqual(Mnemonic.mov, program.statements[1].instruction.op);
    try std.testing.expectEqual(Condition.positive, program.statements[1].instruction.condition.?);
}

test "parse unknown instruction returns error" {
    try std.testing.expectError(error.UnknownInstruction, parse(std.testing.allocator, "invalid acc 1"));
}
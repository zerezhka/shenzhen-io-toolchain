const std = @import("std");
const Parser = @import("../parse/Parser.zig");

pub fn emit(allocator: std.mem.Allocator, program: Parser.Program) ![]u8 {
    var buf = std.ArrayList(u8).empty;

    var i: usize = 0;
    while (i < program.statements.len) {
        switch (program.statements[i]) {
            .label => |name| {
                try buf.appendSlice(allocator, name);
                try buf.appendSlice(allocator, ":\n");
            },
            .instruction => |instr| {
                if (instr.condition) |cond| {
                    const prefix = if (cond == Parser.Condition.positive) "+" else "-";
                    try buf.appendSlice(allocator, prefix);
                    try buf.appendSlice(allocator, " ");
                }
                try buf.appendSlice(allocator, @tagName(instr.op));
                for (instr.operands) |operand| {
                    try buf.appendSlice(allocator, " ");
                    // vanilla SIO has no +N syntax; strip + for C# compat
                    const normalized = if (operand.len > 1 and operand[0] == '+' and std.ascii.isDigit(operand[1]))
                        operand[1..]
                    else
                        operand;
                    try buf.appendSlice(allocator, normalized);
                }
                try buf.appendSlice(allocator, "\n");
            },
        }
        i += 1;
    }
    return try buf.toOwnedSlice(allocator);
}

fn expectEmit(source: []const u8, expected: []const u8) !void {
    const program = try Parser.parse(std.testing.allocator, source);
    defer program.deinit(std.testing.allocator);
    const out = try emit(std.testing.allocator, program);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(expected, out);
}

test "emit simple instruction" {
    try expectEmit("mov acc 1", "mov acc 1\n");
}

test "emit label" {
    try expectEmit("loop:", "loop:\n");
}

test "emit label and instruction" {
    try expectEmit("loop:\njmp loop", "loop:\njmp loop\n");
}

test "emit conditional instruction" {
    try expectEmit("+ mov acc 1", "+ mov acc 1\n");
}

test "emit negative condition" {
    try expectEmit("- jmp loop", "- jmp loop\n");
}

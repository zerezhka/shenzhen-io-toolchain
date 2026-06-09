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
                    try buf.appendSlice(allocator, operand);
                }
                try buf.appendSlice(allocator, "\n");
            },
        }
        i += 1;
    }
    return try buf.toOwnedSlice(allocator);
}

test "emit simple instruction" {
    const program = try Parser.parse(std.testing.allocator, "mov acc 1");
    defer program.deinit(std.testing.allocator);
    const out = try emit(std.testing.allocator, program);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("mov acc 1\n", out);
}

test "emit label" {
    const program = try Parser.parse(std.testing.allocator, "loop:");
    defer program.deinit(std.testing.allocator);
    const out = try emit(std.testing.allocator, program);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("loop:\n", out);
}

test "emit label and instruction" {
    const program = try Parser.parse(std.testing.allocator, "loop:\njmp loop");
    defer program.deinit(std.testing.allocator);
    const out = try emit(std.testing.allocator, program);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("loop:\njmp loop\n", out);
}

test "emit conditional instruction" {
    const program = try Parser.parse(std.testing.allocator, "+ mov acc 1");
    defer program.deinit(std.testing.allocator);
    const out = try emit(std.testing.allocator, program);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("+ mov acc 1\n", out);
}

test "emit negative condition" {
    const program = try Parser.parse(std.testing.allocator, "- jmp loop");
    defer program.deinit(std.testing.allocator);
    const out = try emit(std.testing.allocator, program);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("- jmp loop\n", out);
}

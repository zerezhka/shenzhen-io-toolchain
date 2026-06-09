const std = @import("std");

/// Разбирает `<name> <value>` из тела директивы const/alias (без префикса).
/// Возвращает null, если имени или значения нет.
fn parseKeyValue(rest: []const u8) ?struct { name: []const u8, value: []const u8 } {
    var parts = std.mem.splitAny(u8, rest, " \t");
    const name = parts.next() orelse return null;
    const value = parts.next() orelse return null;
    return .{ .name = name, .value = value };
}

pub fn preprocess(allocator: std.mem.Allocator, source: []const u8) ![]u8 {
    var consts = std.StringHashMap([]const u8).init(allocator);
    defer consts.deinit();
    var aliases = std.StringHashMap([]const u8).init(allocator);
    defer aliases.deinit();

    // first pass: collect const and alias definitions
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "const ")) {
            const kv = parseKeyValue(trimmed[6..]) orelse continue;
            try consts.put(kv.name, kv.value);
        } else if (std.mem.startsWith(u8, trimmed, "alias ")) {
            const kv = parseKeyValue(trimmed[6..]) orelse continue;
            try aliases.put(kv.name, kv.value);
        }
    }

    // second pass: skip directives, substitute consts/aliases, strip comments
    var out = std.ArrayList(u8).empty;
    lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "const ") or
            std.mem.startsWith(u8, trimmed, "alias ") or
            std.mem.startsWith(u8, trimmed, "include "))
        {
            continue;
        }

        // strip comment
        const code = if (std.mem.indexOf(u8, trimmed, "#")) |pos|
            std.mem.trim(u8, trimmed[0..pos], " \t")
        else
            trimmed;

        if (code.len == 0) continue;

        // substitute word by word
        var words = std.mem.splitAny(u8, code, " \t");
        var first = true;
        while (words.next()) |word| {
            if (word.len == 0) continue;
            if (!first) try out.append(allocator, ' ');
            first = false;
            const substituted = aliases.get(word) orelse consts.get(word) orelse word;
            try out.appendSlice(allocator, substituted);
        }
        try out.append(allocator, '\n');
    }

    return out.toOwnedSlice(allocator);
}

fn expectPreprocess(source: []const u8, expected: []const u8) !void {
    const out = try preprocess(std.testing.allocator, source);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(expected, out);
}

test "const substitution" {
    try expectPreprocess("const MAX 100\nmov acc MAX", "mov acc 100\n");
}

test "alias substitution" {
    try expectPreprocess("alias LED p0\nmov LED acc", "mov p0 acc\n");
}

test "comment stripping" {
    try expectPreprocess("mov acc 1 # set acc to 1", "mov acc 1\n");
}

test "skip include line" {
    try expectPreprocess("include helpers.asm\nmov acc 0", "mov acc 0\n");
}

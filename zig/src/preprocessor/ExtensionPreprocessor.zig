const std = @import("std");

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
            const rest = trimmed[6..];
            var parts = std.mem.splitAny(u8, rest, " \t");
            const name = parts.next() orelse continue;
            const value = parts.next() orelse continue;
            try consts.put(name, value);
        } else if (std.mem.startsWith(u8, trimmed, "alias ")) {
            const rest = trimmed[6..];
            var parts = std.mem.splitAny(u8, rest, " \t");
            const name = parts.next() orelse continue;
            const target = parts.next() orelse continue;
            try aliases.put(name, target);
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

test "const substitution" {
    const source = "const MAX 100\nmov acc MAX";
    const out = try preprocess(std.testing.allocator, source);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("mov acc 100\n", out);
}

test "alias substitution" {
    const source = "alias LED p0\nmov LED acc";
    const out = try preprocess(std.testing.allocator, source);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("mov p0 acc\n", out);
}

test "comment stripping" {
    const source = "mov acc 1 # set acc to 1";
    const out = try preprocess(std.testing.allocator, source);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("mov acc 1\n", out);
}

test "skip include line" {
    const source = "include helpers.asm\nmov acc 0";
    const out = try preprocess(std.testing.allocator, source);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("mov acc 0\n", out);
}

const std = @import("std");

pub const Token = struct {
    line: u32,
    column: u32,

    type: TokenType,
    value: []const u8,
};

pub const TokenType = enum {
    identifier,
    number,
    colon,
    condition,
    new_line,
    end_of_file,
};

const Tokenizer = struct {
    source: []const u8,
    pos: usize,
    line: u32,
    column: u32,

    fn next(self: *Tokenizer) Token {
        while (true) {
            while (self.peek()) |c| {
                if (isWhitespace(c)) _ = self.advance() else break;
            }

            const c = self.peek() orelse return .{
                .type = .end_of_file,
                .value = "",
                .line = self.line,
                .column = self.column,
            };

            const col = self.column;

            switch (c) {
                ':' => {
                    _ = self.advance();
                    return .{ .type = .colon, .value = ":", .line = self.line, .column = col };
                },
                'a'...'z', 'A'...'Z', '_' => {
                    const start = self.pos;
                    while (self.peek()) |nc| {
                        if (std.ascii.isAlphanumeric(nc) or nc == '_') _ = self.advance() else break;
                    }
                    return .{
                        .type = .identifier,
                        .value = self.source[start..self.pos],
                        .line = self.line,
                        .column = col,
                    };
                },
                '\n' => {
                    _ = self.advance();
                    self.line += 1;
                    self.column = 0;
                    return .{
                        .type = .new_line,
                        .value = "\n",
                        .line = self.line - 1,
                        .column = col,
                    };
                },
                '#' => {
                    while (self.peek()) |nc| {
                        if (nc == '\n') break;
                        _ = self.advance();
                    }
                },
                '+' => {
                    _ = self.advance();
                    return .{
                        .type = .condition,
                        .value = "+",
                        .line = self.line,
                        .column = col,
                    };
                },
                '-' => {
                    if (self.peekAt(1)) |nc2| {
                        if (std.ascii.isDigit(nc2)) {
                            const start = self.pos;
                            _ = self.advance();
                            while (self.peek()) |nc| {
                                if (std.ascii.isDigit(nc)) _ = self.advance() else break;
                            }
                            return .{
                                .type = .number,
                                .value = self.source[start..self.pos],
                                .line = self.line,
                                .column = col,
                            };
                        }
                    }
                    _ = self.advance();
                    return .{
                        .type = .condition,
                        .value = "-",
                        .line = self.line,
                        .column = col,
                    };
                },
                '0'...'9' => {
                    const start = self.pos;
                    while (self.peek()) |nc| {
                        if (std.ascii.isDigit(nc)) _ = self.advance() else break;
                    }
                    return .{
                        .type = .number,
                        .value = self.source[start..self.pos],
                        .line = self.line,
                        .column = col,
                    };
                },
                else => _ = self.advance(),
            }
        }
    }

    fn peek(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        return self.source[self.pos];
    }
    fn peekAt(self: *Tokenizer, p: usize) ?u8 {
        if (self.pos + p >= self.source.len) return null;
        return self.source[self.pos + p];
    }
    fn advance(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        defer {
            self.pos += 1;
            self.column +=1;
        }
        return self.source[self.pos];
    }

    fn isWhitespace(c: u8) bool {
        if (c == ' ' or c == '\t') return true;
        return false;
    }
};

pub fn tokenize(
    allocator: std.mem.Allocator,
    source: []const u8,
) ![]Token {
    var t = Tokenizer{ .source = source, .pos = 0, .line = 1, .column = 0 };
    var tokens = std.ArrayList(Token).empty;
    defer tokens.deinit(allocator);
    while (true) {
        const tok = t.next();
        try tokens.append(allocator, tok);
        if (tok.type == .end_of_file) break;
    }
    return tokens.toOwnedSlice(allocator);
}

// Tests written by Claude Sonnet 4.6
test "tokenize simple instruction" {
    const tokens = try tokenize(std.testing.allocator, "mov acc 1");
    defer std.testing.allocator.free(tokens);

    try std.testing.expectEqual(@as(usize, 4), tokens.len);
    try std.testing.expectEqualStrings("mov", tokens[0].value);
    try std.testing.expectEqual(TokenType.identifier, tokens[0].type);
    try std.testing.expectEqualStrings("acc", tokens[1].value);
    try std.testing.expectEqualStrings("1", tokens[2].value);
    try std.testing.expectEqual(TokenType.end_of_file, tokens[3].type);
}

test "tokenize label" {
    const tokens = try tokenize(std.testing.allocator, "loop:\nmov acc 1");
    defer std.testing.allocator.free(tokens);

    try std.testing.expectEqualStrings("loop", tokens[0].value);
    try std.testing.expectEqual(TokenType.identifier, tokens[0].type);
    try std.testing.expectEqual(TokenType.colon, tokens[1].type);
}

test "tokenize comment" {
    const tokens = try tokenize(std.testing.allocator, "mov acc 1 # this is a comment");
    defer std.testing.allocator.free(tokens);

    try std.testing.expectEqual(@as(usize, 4), tokens.len);
}

test "tokenize condition" {
    const tokens = try tokenize(std.testing.allocator, "+ mov acc 1");
    defer std.testing.allocator.free(tokens);

    try std.testing.expectEqual(TokenType.condition, tokens[0].type);
    try std.testing.expectEqualStrings("+", tokens[0].value);
}

test "tokenize negative number" {
    const tokens = try tokenize(std.testing.allocator, "-42");
    defer std.testing.allocator.free(tokens);

    try std.testing.expectEqual(TokenType.number, tokens[0].type);
    try std.testing.expectEqualStrings("-42", tokens[0].value);
}

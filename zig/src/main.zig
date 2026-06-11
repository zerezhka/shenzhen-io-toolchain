const std = @import("std");
const options = @import("options");
const Preprocessor = @import("preprocessor/ExtensionPreprocessor.zig");
const Parser = @import("parse/Parser.zig");
const Emitter = @import("emit/Emitter.zig");

const version = options.version;

const help =
    \\Usage: sio [command] [args]
    \\
    \\Commands:
    \\  assemble <file>   Assemble .asm to vanilla Shenzhen I/O assembly
    \\  simulate <file>   Simulate .asm execution cycle by cycle
    \\  test <file>       Run test cases against .asm output
    \\
    \\Options:
    \\  -h, --help        Print this help
    \\  --version         Print version
    \\
    \\Run without arguments to enter interactive mode.
    \\
;

pub fn main(init: std.process.Init) u8 {
    const io = init.io;
    const gpa = init.gpa;
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.skip(); // skip argv[0]

    const cmd = args.next() orelse {
        std.debug.print("TODO: interactive mode not implemented yet\n", .{});
        return 0;
    };

    if (std.mem.eql(u8, cmd, "-h") or std.mem.eql(u8, cmd, "--help")) {
        printStdout(io, "{s}", .{help}) catch return 1;
        return 0;
    }

    if (std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) {
        printStdout(io, "sio {s}\n", .{version}) catch return 1;
        return 0;
    }

    if (std.mem.eql(u8, cmd, "assemble")) {
        const path = args.next() orelse {
            std.debug.print("usage: sio assemble <file>\n", .{});
            return 1;
        };
        assemble(io, gpa, path) catch |err| {
            std.debug.print("error: {}\n", .{err});
            return 1;
        };
        return 0;
    }

    if (std.mem.eql(u8, cmd, "simulate")) {
        std.debug.print("TODO: simulate not implemented yet\n", .{});
        return 0;
    }

    if (std.mem.eql(u8, cmd, "test")) {
        std.debug.print("TODO: test not implemented yet\n", .{});
        return 0;
    }

    std.debug.print("unknown command: {s}\n\n{s}", .{ cmd, help });
    return 1;
}

/// Обычный вывод — в stdout (std.debug.print пишет в stderr и ломает
/// пайпы вроде `sio --version | grep`); stderr оставляем ошибкам.
fn printStdout(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    var buf: [4096]u8 = undefined;
    var fw = std.Io.File.stdout().writer(io, &buf);
    try fw.interface.print(fmt, args);
    try fw.interface.flush();
}

fn assemble(io: std.Io, gpa: std.mem.Allocator, path: []const u8) !void {
    const source = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, std.Io.Limit.limited(1 << 20));
    defer gpa.free(source);

    const preprocessed = try Preprocessor.preprocess(gpa, source);
    defer gpa.free(preprocessed);

    const program = try Parser.parse(gpa, preprocessed);
    defer program.deinit(gpa);

    const out = try Emitter.emit(gpa, program);
    defer gpa.free(out);

    var buf: [4096]u8 = undefined;
    var fw = std.Io.File.stdout().writer(io, &buf);
    try fw.interface.writeAll(out);
    try fw.interface.flush();
}

test {
    _ = @import("parse/Parser.zig");
    _ = @import("emit/Emitter.zig");
    _ = @import("preprocessor/ExtensionPreprocessor.zig");
    _ = @import("simulate/Simulator.zig");
}

const std = @import("std");
const options = @import("options");

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

pub fn main(init: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.init(init.args);
    _ = args.skip(); // skip argv[0]

    const cmd = args.next() orelse {
        std.debug.print("TODO: interactive mode not implemented yet\n", .{});
        return 0;
    };

    if (std.mem.eql(u8, cmd, "-h") or std.mem.eql(u8, cmd, "--help")) {
        std.debug.print("{s}", .{help});
        return 0;
    }

    if (std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) {
        std.debug.print("sio {s}\n", .{version});
        return 0;
    }

    if (std.mem.eql(u8, cmd, "assemble")) {
        std.debug.print("TODO: assemble not implemented yet\n", .{});
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

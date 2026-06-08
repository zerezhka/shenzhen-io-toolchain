const std = @import("std");

const version = "0.0.0";

pub fn main(init: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.init(init.args);
    _ = args.skip(); // skip argv[0]

    const cmd = args.next() orelse {
        printUsage();
        return 1;
    };

    if (std.mem.eql(u8, cmd, "--version")) {
        std.debug.print("sio {s}\n", .{version});
        return 0;
    }

    std.debug.print("unknown command: {s}\n", .{cmd});
    printUsage();
    return 1;
}

fn printUsage() void {
    std.debug.print("Usage: sio <command> [args]\n", .{});
}

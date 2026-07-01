const std = @import("std");
const options = @import("options");
const Preprocessor = @import("preprocessor/ExtensionPreprocessor.zig");
const Parser = @import("parse/Parser.zig");
const Emitter = @import("emit/Emitter.zig");
const Simulator = @import("simulate/Simulator.zig");
const Machine = @import("simulate/Machine.zig");

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
        const path = args.next() orelse {
            std.debug.print("usage: sio simulate <file> [--trace] [--cycles N]\n", .{});
            return 1;
        };
        var trace = false;
        var cycle_limit: u64 = 100_000;
        while (args.next()) |flag| {
            if (std.mem.eql(u8, flag, "--trace")) {
                trace = true;
            } else if (std.mem.eql(u8, flag, "--cycles")) {
                const val = args.next() orelse {
                    std.debug.print("--cycles requires a number\n", .{});
                    return 1;
                };
                cycle_limit = std.fmt.parseInt(u64, val, 10) catch {
                    std.debug.print("invalid --cycles value: {s}\n", .{val});
                    return 1;
                };
            }
        }
        simulate(io, gpa, path, trace, cycle_limit) catch |err| {
            std.debug.print("error: {}\n", .{err});
            return 1;
        };
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

fn simulate(io: std.Io, gpa: std.mem.Allocator, path: []const u8, trace: bool, cycle_limit: u64) !void {
    const source = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, std.Io.Limit.limited(1 << 20));
    defer gpa.free(source);

    const preprocessed = try Preprocessor.preprocess(gpa, source);
    defer gpa.free(preprocessed);

    const parsed = try Parser.parse(gpa, preprocessed);
    defer parsed.deinit(gpa);

    var program = try Simulator.build(gpa, parsed);
    defer program.deinit(gpa);

    var machine = Machine.Machine.init(program, true);
    machine.trace = trace;
    try machine.run(cycle_limit);

    const dat_val: i32 = if (machine.cpu.dat) |d| d else 0;
    try printStdout(io, "acc={d} dat={d} cycles={d} p0={d} p1={d} p2={d} p3={d} p4={d} p5={d}\n", .{
        machine.cpu.acc, dat_val, machine.cycles,
        machine.cpu.ports[0], machine.cpu.ports[1], machine.cpu.ports[2],
        machine.cpu.ports[3], machine.cpu.ports[4], machine.cpu.ports[5],
    });
}

test {
    _ = @import("parse/Parser.zig");
    _ = @import("emit/Emitter.zig");
    _ = @import("preprocessor/ExtensionPreprocessor.zig");
    _ = @import("simulate/Simulator.zig");
    _ = @import("simulate/Machine.zig");
    _ = @import("simulate/Board.zig");
}

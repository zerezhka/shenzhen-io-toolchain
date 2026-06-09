const std = @import("std");
const Parser = @import("parse/Parser.zig");
const Emitter = @import("emit/Emmiter.zig");

const sample =
    \\loop:
    \\mov acc 0
    \\teq acc 5
    \\+ jmp done
    \\add acc 1
    \\jmp loop
    \\done:
    \\mov p0 acc
;

const iterations = 1_000_000;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const start = std.Io.Clock.now(.awake, io);

    for (0..iterations) |_| {
        defer _ = arena.reset(.retain_capacity);
        const allocator = arena.allocator();

        const program = try Parser.parse(allocator, sample);
        const out = try Emitter.emit(allocator, program);
        _ = out;
    }

    const elapsed = start.untilNow(io, .awake);
    const ms = elapsed.toMilliseconds();
    const throughput = iterations * 1000 / (@as(usize, @intCast(ms)) + 1);

    std.debug.print("iterations: {d}\n", .{iterations});
    std.debug.print("time:       {d} ms\n", .{ms});
    std.debug.print("throughput: {d} ops/sec\n", .{throughput});
}

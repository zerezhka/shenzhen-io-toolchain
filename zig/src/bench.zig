const std = @import("std");
const bench_util = @import("bench_util.zig");

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
        try bench_util.runHot(arena.allocator(), sample);
    }

    const elapsed = start.untilNow(io, .awake);
    bench_util.reportThroughput(iterations, elapsed.toMilliseconds());
}

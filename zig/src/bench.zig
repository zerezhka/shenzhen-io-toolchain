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

fn nanoNow() u64 {
    var ts: std.os.linux.timespec = undefined;
    _ = std.os.linux.clock_gettime(std.os.linux.CLOCK.MONOTONIC, &ts);
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

pub fn main() !void {
    const start = nanoNow();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    for (0..iterations) |_| {
        defer _ = arena.reset(.retain_capacity);
        const allocator = arena.allocator();

        const program = try Parser.parse(allocator, sample);
        const out = try Emitter.emit(allocator, program);
        _ = out;
    }

    const elapsed_ns = nanoNow() - start;
    const elapsed_ms = elapsed_ns / std.time.ns_per_ms;
    const throughput = iterations * std.time.ms_per_s / (elapsed_ms + 1);

    std.debug.print("iterations: {d}\n", .{iterations});
    std.debug.print("time:       {d} ms\n", .{elapsed_ms});
    std.debug.print("throughput: {d} ops/sec\n", .{throughput});
}

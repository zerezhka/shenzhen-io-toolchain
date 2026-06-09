const std = @import("std");
const Parser = @import("parse/Parser.zig");
const Emitter = @import("emit/Emmiter.zig");

/// Один прогон parse→emit, результат отбрасывается. Аллокатор — обычно arena,
/// которую вызывающий ресетит между итерациями.
pub fn runHot(allocator: std.mem.Allocator, src: []const u8) !void {
    const program = try Parser.parse(allocator, src);
    const out = try Emitter.emit(allocator, program);
    _ = out;
}

/// Печатает iterations/time/throughput по числу прогонов и затраченным мс.
pub fn reportThroughput(iterations: usize, ms: anytype) void {
    const throughput = iterations * 1000 / (@as(usize, @intCast(ms)) + 1);
    std.debug.print("iterations: {d}\n", .{iterations});
    std.debug.print("time:       {d} ms\n", .{ms});
    std.debug.print("throughput: {d} ops/sec\n", .{throughput});
}

const std = @import("std");
const Parser = @import("parse/Parser.zig");
const Emitter = @import("emit/Emmiter.zig");

const solutions_dirs = [_][]const u8{
    "../tests/extracted-solutions",
    "../tests/extracted-solutions-stinkingbanana",
    "../tests/extracted-solutions-shiawasenahikari",
};

const target_iterations = 100_000;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    // load all .asm files into memory
    var sources = std.ArrayList([]const u8).empty;
    defer {
        for (sources.items) |s| gpa.free(s);
        sources.deinit(gpa);
    }

    for (solutions_dirs) |dir_path| {
        const dir = std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true }) catch continue;
        var walker = try dir.walk(gpa);
        defer walker.deinit();
        while (try walker.next(io)) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.path, ".asm")) continue;
            const src = dir.readFileAlloc(io, entry.path, gpa, std.Io.Limit.limited(1 << 20)) catch continue;
            try sources.append(gpa, src);
        }
    }

    std.debug.print("loaded {} files\n", .{sources.items.len});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const start = std.Io.Clock.now(.awake, io);
    var count: usize = 0;

    outer: while (true) {
        for (sources.items) |src| {
            defer _ = arena.reset(.retain_capacity);
            const allocator = arena.allocator();
            const program = try Parser.parse(allocator, src);
            const out = try Emitter.emit(allocator, program);
            _ = out;
            count += 1;
            if (count >= target_iterations) break :outer;
        }
    }

    const elapsed = start.untilNow(io, .awake);
    const ms = elapsed.toMilliseconds();
    const throughput = count * 1000 / (@as(usize, @intCast(ms)) + 1);

    std.debug.print("iterations: {d}\n", .{count});
    std.debug.print("time:       {d} ms\n", .{ms});
    std.debug.print("throughput: {d} ops/sec\n", .{throughput});
}

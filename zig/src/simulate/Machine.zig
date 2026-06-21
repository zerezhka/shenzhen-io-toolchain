const std = @import("std");
const CpuModule = @import("Cpu.zig");
const Simulator = @import("Simulator.zig");
const Parser = @import("../parse/Parser.zig");

pub const Machine = struct {
    cpu: CpuModule.Cpu,
    program: Simulator.Program,
    cycles: u64,
    sleep_remaining: u32,

    pub fn init(program: Simulator.Program, has_dat: bool) Machine {
        return .{
            .cpu = CpuModule.Cpu.init(has_dat),
            .program = program,
            .cycles = 0,
            .sleep_remaining = 0,
        };
    }

    pub fn step(self: *Machine) !void {
        if (self.cpu.pc >= self.program.instructions.len) return;

        const instr = self.program.instructions[self.cpu.pc];

        switch (instr.op) {
            .nop => {},
            .mov => {
                const val = try CpuModule.read(&self.cpu, instr.operands[0]);
                try CpuModule.write(&self.cpu, instr.operands[1], val);
            },
            .jmp => {
                self.cpu.pc = instr.operands[0].target;
                self.cycles += 1;
                return;
            },
            else => {
                return error.NotYetImplemented;
            },
        }

        self.cpu.pc += 1;
        self.cycles += 1;
    }
};

// --- Tests ---

test "5.4 nop advances PC and cycles" {
    const parsed = try Parser.parse(std.testing.allocator, "nop\nnop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try std.testing.expectEqual(@as(usize, 1), m.cpu.pc);
    try std.testing.expectEqual(@as(u64, 1), m.cycles);
    try m.step();
    try std.testing.expectEqual(@as(usize, 2), m.cpu.pc);
    try std.testing.expectEqual(@as(u64, 2), m.cycles);
}

test "5.4 step past end is a no-op" {
    const parsed = try Parser.parse(std.testing.allocator, "nop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // execute nop
    try m.step(); // past end — should do nothing
    try m.step(); // still nothing
    try std.testing.expectEqual(@as(usize, 1), m.cpu.pc);
    try std.testing.expectEqual(@as(u64, 1), m.cycles);
}

test "5.4 mov copies value between operands" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 42 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try std.testing.expectEqual(@as(i32, 42), m.cpu.acc);
}

test "5.4 mov acc to dat" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 99 acc\nmov acc dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true); // MC6000 has dat
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 99), m.cpu.dat.?);
}

test "5.4 jmp sets PC to target" {
    const parsed = try Parser.parse(std.testing.allocator, "jmp skip\nnop\nskip:\nmov 42 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // jmp skip → pc = 2 (skip: points to mov)
    try std.testing.expectEqual(@as(usize, 2), m.cpu.pc);
    try std.testing.expectEqual(@as(u64, 1), m.cycles);
    try m.step(); // mov 42 acc
    try std.testing.expectEqual(@as(i32, 42), m.cpu.acc);
}

test "5.4 jmp loop executes repeatedly" {
    const parsed = try Parser.parse(std.testing.allocator, "loop:\nnop\njmp loop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // nop, pc=1
    try m.step(); // jmp loop → pc=0
    try std.testing.expectEqual(@as(usize, 0), m.cpu.pc);
    try m.step(); // nop, pc=1
    try m.step(); // jmp loop → pc=0
    try std.testing.expectEqual(@as(usize, 0), m.cpu.pc);
    try std.testing.expectEqual(@as(u64, 4), m.cycles);
}

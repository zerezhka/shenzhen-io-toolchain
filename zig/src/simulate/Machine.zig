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

        if (instr.condition) |cond| {
            const skip = switch (cond) {
                .positive => !self.cpu.conditional_positive or self.cpu.conditional_equal,
                .negative => self.cpu.conditional_positive or self.cpu.conditional_equal,
            };
            if (skip) {
                self.cpu.pc += 1;
                self.cycles += 1;
                return;
            }
        }

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
            // arithmetics
            .add => {
                const val = try CpuModule.read(&self.cpu, instr.operands[0]);
                self.cpu.setAcc(self.cpu.acc + val);
            },
            .sub => {
                const val = try CpuModule.read(&self.cpu, instr.operands[0]);
                self.cpu.setAcc(self.cpu.acc - val);
            },
            .mul => {
                const val = try CpuModule.read(&self.cpu, instr.operands[0]);
                self.cpu.setAcc(self.cpu.acc * val);
            },
            .dgt => {
                const pos = try CpuModule.read(&self.cpu, instr.operands[0]);
                const divisor = std.math.powi(i32, 10, pos) catch 1;
                const digit = @mod(@divTrunc(self.cpu.acc, divisor), 10);
                try CpuModule.write(&self.cpu, instr.operands[1], digit);
            },
            .dst => {
                const pos = try CpuModule.read(&self.cpu, instr.operands[0]);
                const val = try CpuModule.read(&self.cpu, instr.operands[1]);
                const divisor = std.math.powi(i32, 10, pos) catch 1;
                const old_digit = @mod(@divTrunc(self.cpu.acc, divisor), 10);
                self.cpu.setAcc(self.cpu.acc - old_digit * divisor + val * divisor);
            },
            .not => {
                if (self.cpu.acc == 0) {
                    self.cpu.setAcc(100);
                } else {
                    self.cpu.setAcc(0);
                }
            },
            // conditional
            .teq => {
                const op1 = try CpuModule.read(&self.cpu, instr.operands[0]);
                const op2 = try CpuModule.read(&self.cpu, instr.operands[1]);
                if (op1 == op2) {
                    self.cpu.conditional_positive = true;
                    self.cpu.conditional_equal = false;
                } else {
                    self.cpu.conditional_positive = false;
                    self.cpu.conditional_equal = false;
                }
            },
            .tgt => {
                const op1 = try CpuModule.read(&self.cpu, instr.operands[0]);
                const op2 = try CpuModule.read(&self.cpu, instr.operands[1]);
                if (op1 > op2) {
                    self.cpu.conditional_positive = true;
                    self.cpu.conditional_equal = false;
                } else {
                    self.cpu.conditional_positive = false;
                    self.cpu.conditional_equal = false;
                }
            },
            .tlt => {
                const op1 = try CpuModule.read(&self.cpu, instr.operands[0]);
                const op2 = try CpuModule.read(&self.cpu, instr.operands[1]);
                if (op1 < op2) {
                    self.cpu.conditional_positive = true;
                    self.cpu.conditional_equal = false;
                } else {
                    self.cpu.conditional_positive = false;
                    self.cpu.conditional_equal = false;
                }
            },
            .tcp => {
                const op1 = try CpuModule.read(&self.cpu, instr.operands[0]);
                const op2 = try CpuModule.read(&self.cpu, instr.operands[1]);
                if (op1 > op2) {
                    self.cpu.conditional_positive = true;
                    self.cpu.conditional_equal = false;
                } else if (op2 > op1) {
                    self.cpu.conditional_positive = false;
                    self.cpu.conditional_equal = false;
                } else {
                    self.cpu.conditional_positive = false;
                    self.cpu.conditional_equal = true;
                }
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

// --- Step 5.5: arithmetic ---

test "5.5 add: acc += operand" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 10 acc\nadd 5");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 15), m.cpu.acc);
}

test "5.5 add: clamps at 999" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 990 acc\nadd 100");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 999), m.cpu.acc);
}

test "5.5 sub: acc -= operand" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 10 acc\nsub 3");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 7), m.cpu.acc);
}

test "5.5 sub: clamps at -999" {
    const parsed = try Parser.parse(std.testing.allocator, "mov -990 acc\nsub 100");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, -999), m.cpu.acc);
}

test "5.5 mul: acc *= operand" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 7 acc\nmul 6");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 42), m.cpu.acc);
}

test "5.5 not: zero becomes 100, nonzero becomes 0" {
    const parsed = try Parser.parse(std.testing.allocator, "not\nmov 42 acc\nnot");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // acc=0 → acc=100
    try std.testing.expectEqual(@as(i32, 100), m.cpu.acc);
    try m.step(); // mov 42 acc
    try m.step(); // acc=42 → acc=0
    try std.testing.expectEqual(@as(i32, 0), m.cpu.acc);
}

test "5.5 dgt: extract digit from acc" {
    // acc=123, dgt 0 acc → ones digit = 3
    // acc=123, dgt 1 acc → tens digit = 2
    // acc=123, dgt 2 acc → hundreds digit = 1
    const parsed = try Parser.parse(std.testing.allocator, "mov 123 acc\ndgt 0 dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 3), m.cpu.dat.?);
}

test "5.5 dgt: tens digit" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 456 acc\ndgt 1 dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 5), m.cpu.dat.?);
}

test "5.5 dst: set digit in acc" {
    // acc=100, dst 0 5 → acc=105
    const parsed = try Parser.parse(std.testing.allocator, "mov 100 acc\ndst 0 5");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 105), m.cpu.acc);
}

test "5.5 dst: set tens digit" {
    // acc=100, dst 1 7 → acc=170
    const parsed = try Parser.parse(std.testing.allocator, "mov 100 acc\ndst 1 7");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 170), m.cpu.acc);
}

// --- Step 5.6: test instructions & conditional execution ---

test "5.6 teq: equal sets positive" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 5 acc\nteq acc 5\n+ mov 1 dat\n- mov 2 dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true);
    try m.step(); // mov 5 acc
    try m.step(); // teq acc 5 → equal → positive=true
    try m.step(); // + mov 1 dat → executes
    try m.step(); // - mov 2 dat → skipped
    try std.testing.expectEqual(@as(i32, 1), m.cpu.dat.?);
}

test "5.6 teq: not equal sets negative" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 3 acc\nteq acc 5\n+ mov 1 dat\n- mov 2 dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true);
    try m.step(); // mov 3 acc
    try m.step(); // teq acc 5 → not equal → positive=false
    try m.step(); // + mov 1 dat → skipped
    try m.step(); // - mov 2 dat → executes
    try std.testing.expectEqual(@as(i32, 2), m.cpu.dat.?);
}

test "5.6 tgt: greater sets positive" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 10 acc\ntgt acc 5\n+ mov 1 dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true);
    try m.step(); // mov 10 acc
    try m.step(); // tgt acc 5 → 10 > 5 → positive=true
    try m.step(); // + mov 1 dat → executes
    try std.testing.expectEqual(@as(i32, 1), m.cpu.dat.?);
}

test "5.6 tlt: less sets positive" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 3 acc\ntlt acc 5\n+ mov 1 dat");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, true);
    try m.step(); // mov 3 acc
    try m.step(); // tlt acc 5 → 3 < 5 → positive=true
    try m.step(); // + mov 1 dat → executes
    try std.testing.expectEqual(@as(i32, 1), m.cpu.dat.?);
}

test "5.6 tcp: three-way compare" {
    // A > B → positive
    const parsed1 = try Parser.parse(std.testing.allocator, "mov 10 acc\ntcp acc 5\n+ mov 1 dat\n- mov 2 dat");
    defer parsed1.deinit(std.testing.allocator);
    var prog1 = try Simulator.build(std.testing.allocator, parsed1);
    defer prog1.deinit(std.testing.allocator);

    var m1 = Machine.init(prog1, true);
    try m1.step();
    try m1.step();
    try m1.step(); // + mov 1 dat → executes
    try m1.step(); // - mov 2 dat → skipped
    try std.testing.expectEqual(@as(i32, 1), m1.cpu.dat.?);

    // A < B → negative
    const parsed2 = try Parser.parse(std.testing.allocator, "mov 3 acc\ntcp acc 5\n+ mov 1 dat\n- mov 2 dat");
    defer parsed2.deinit(std.testing.allocator);
    var prog2 = try Simulator.build(std.testing.allocator, parsed2);
    defer prog2.deinit(std.testing.allocator);

    var m2 = Machine.init(prog2, true);
    try m2.step();
    try m2.step();
    try m2.step(); // + mov 1 dat → skipped
    try m2.step(); // - mov 2 dat → executes
    try std.testing.expectEqual(@as(i32, 2), m2.cpu.dat.?);

    // A == B → equal (both skipped)
    const parsed3 = try Parser.parse(std.testing.allocator, "mov 5 acc\ntcp acc 5\n+ mov 1 dat\n- mov 2 dat");
    defer parsed3.deinit(std.testing.allocator);
    var prog3 = try Simulator.build(std.testing.allocator, parsed3);
    defer prog3.deinit(std.testing.allocator);

    var m3 = Machine.init(prog3, true);
    try m3.step();
    try m3.step();
    try m3.step(); // + mov 1 dat → skipped
    try m3.step(); // - mov 2 dat → skipped
    try std.testing.expectEqual(@as(i32, 0), m3.cpu.dat.?); // dat untouched (init=0)
}

test "5.6 unconditional instructions always execute regardless of flags" {
    const parsed = try Parser.parse(std.testing.allocator, "teq 0 1\nmov 42 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // teq 0 1 → positive=false
    try m.step(); // mov 42 acc → no condition, always runs
    try std.testing.expectEqual(@as(i32, 42), m.cpu.acc);
}

test "5.6 skipped instruction still advances PC and costs a cycle" {
    const parsed = try Parser.parse(std.testing.allocator, "teq 0 1\n+ mov 42 acc\nmov 99 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // teq 0 1 → positive=false
    try m.step(); // + mov 42 acc → skipped, but PC still advances
    try m.step(); // mov 99 acc → executes
    try std.testing.expectEqual(@as(i32, 99), m.cpu.acc);
    try std.testing.expectEqual(@as(u64, 3), m.cycles);
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

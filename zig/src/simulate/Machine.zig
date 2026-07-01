const std = @import("std");
const CpuModule = @import("Cpu.zig");
const Simulator = @import("Simulator.zig");
const Parser = @import("../parse/Parser.zig");
const Board = @import("Board.zig");

/// Чем закончился runSlice: почему машина отдала управление.
/// 6.3: добавятся blocked_read/blocked_write для XBus.
pub const Yield = union(enum) {
    /// PC ушёл за конец программы — машина больше никогда не исполнится.
    halted,
    /// Исполнен slp N: машина хочет спать N time units.
    /// wake_time выставляет Board (машина своего времени не знает).
    sleep: u32,
};

/// Предохранитель: программа без slp (например `loop: jmp loop`) никогда
/// не отдаст управление — внутри одного time unit это вечный цикл.
/// Больше стольких инструкций за один slice → error.NeverSleeps.
pub const max_slice_instructions: u64 = 100_000;

pub const Machine = struct {
    cpu: CpuModule.Cpu,
    program: Simulator.Program,
    cycles: u64,
    sleep_remaining: u32,
    trace: bool = false,

    // --- Step 6.x: игровые time units + общие провода ---
    /// Провода платы (borrowed от Board). Пустой срез = чип вне платы.
    wires: []Board.Wire = &.{},
    /// pN чипа → индекс в wires. null = пин никуда не подключён:
    /// чтение даёт 0, запись уходит в никуда (как в игре).
    pin_map: [6]?usize = .{null} ** 6,
    /// Board.time, начиная с которого машина снова готова. Ведёт Board.
    wake_time: u64 = 0,
    /// true после того как runSlice дошёл до конца программы.
    halted: bool = false,

    pub fn init(program: Simulator.Program, has_dat: bool) Machine {
        return .{
            .cpu = CpuModule.Cpu.init(has_dat),
            .program = program,
            .cycles = 0,
            .sleep_remaining = 0,
        };
    }

    pub fn step(self: *Machine) !void {
        if (self.sleep_remaining > 0) {
            self.sleep_remaining -= 1;
            self.cycles += 1;
            if (self.trace) self.printTrace("slp", self.cpu.pc);
            return;
        }

        if (self.cpu.pc >= self.program.instructions.len) return;

        const instr = self.program.instructions[self.cpu.pc];

        if (instr.condition) |cond| {
            const skip = switch (cond) {
                .positive => !self.cpu.conditional_positive or self.cpu.conditional_equal,
                .negative => self.cpu.conditional_positive or self.cpu.conditional_equal,
            };
            if (skip) {
                self.cpu.pc += 1;
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
                const from = self.cpu.pc;
                self.cpu.pc = instr.operands[0].target;
                self.cycles += 1;
                if (self.trace) self.printTrace("jmp", from);
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
                self.cpu.setAcc(digit);
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
            .slp => {
                const tts = try CpuModule.read(&self.cpu, instr.operands[0]);
                self.sleep_remaining = @intCast(tts);
            },
            // gen expanded at build time into mov/slp/mov/slp
            else => {
                return error.NotYetImplemented;
            },
        }

        self.cpu.pc += 1;
        self.cycles += 1;
        if (self.trace) self.printTrace(@tagName(instr.op), self.cpu.pc - 1);
    }

    /// Чтение операнда с учётом проводов: .port идёт через pin_map/wires
    /// (неподключённый пин читается как 0), всё остальное — CpuModule.read.
    /// После 6.1 ветки .port в CpuModule.read/write и Cpu.ports умирают.
    pub fn readOperand(self: *Machine, operand: CpuModule.Operand) !i32 {
        _ = self;
        _ = operand;
        return error.NotYetImplemented;
    }

    /// Запись операнда: .port пишет в провод (clampPort, 0-100),
    /// неподключённый пин молча глотает значение, остальное — CpuModule.write.
    pub fn writeOperand(self: *Machine, operand: CpuModule.Operand, value: i32) !void {
        _ = self;
        _ = operand;
        _ = value;
        return error.NotYetImplemented;
    }

    /// Исполняет инструкции подряд — весь «кусок» одного time unit — пока:
    ///  - не исполнится slp N      → return .{ .sleep = N },
    ///  - PC не уйдёт за конец     → halted = true, return .halted,
    ///  - не сработает предохранитель max_slice_instructions → error.NeverSleeps.
    ///
    /// Каждая исполненная инструкция стоит 1 cycle (пропущенная по условию
    /// '+'/'-' — 0, как в step()). Сон циклов не стоит: cycles здесь — метрика
    /// мощности, время живёт на Board. sleep_remaining не используется.
    /// Вызов на уже halted машине сразу возвращает .halted.
    ///
    /// Логику исполнения инструкций бери из step() — switch остаётся тем же,
    /// только read/write заменяются на self.readOperand/self.writeOperand,
    /// а slp вместо sleep_remaining делает return.
    pub fn runSlice(self: *Machine) !Yield {
        _ = self;
        return error.NotYetImplemented;
    }

    fn printTrace(self: *const Machine, op: []const u8, pc: usize) void {
        const dat_val: i32 = if (self.cpu.dat) |d| d else 0;
        std.debug.print("cycle={d} pc={d} op={s} acc={d} dat={d}\n", .{
            self.cycles, pc, op, self.cpu.acc, dat_val,
        });
    }
    pub fn run(self: *Machine, limit: u64) !void {
        while (self.cycles < limit and (self.cpu.pc < self.program.instructions.len or self.sleep_remaining > 0)) {
            try self.step();
        }
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
    const parsed = try Parser.parse(std.testing.allocator, "mov 123 acc\ndgt 0");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 3), m.cpu.acc);
}

test "5.5 dgt: tens digit" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 456 acc\ndgt 1");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step();
    try m.step();
    try std.testing.expectEqual(@as(i32, 5), m.cpu.acc);
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

test "5.6 skipped instruction advances PC but costs no cycle" {
    const parsed = try Parser.parse(std.testing.allocator, "teq 0 1\n+ mov 42 acc\nmov 99 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // teq 0 1 → positive=false
    try m.step(); // + mov 42 acc → skipped, PC advances, no cycle
    try m.step(); // mov 99 acc → executes
    try std.testing.expectEqual(@as(i32, 99), m.cpu.acc);
    try std.testing.expectEqual(@as(u64, 2), m.cycles);
}

// --- Step 5.7: slp & run ---

test "5.7 slp: sleeps for N cycles" {
    const parsed = try Parser.parse(std.testing.allocator, "slp 3\nnop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // slp 3: costs 1 cycle, sets sleep_remaining=3
    try std.testing.expectEqual(@as(u64, 1), m.cycles);
    try std.testing.expectEqual(@as(u32, 3), m.sleep_remaining);
    try std.testing.expectEqual(@as(usize, 1), m.cpu.pc);

    try m.step(); // sleeping: cycle 2, remaining=2
    try m.step(); // sleeping: cycle 3, remaining=1
    try m.step(); // sleeping: cycle 4, remaining=0
    try std.testing.expectEqual(@as(u64, 4), m.cycles);
    try std.testing.expectEqual(@as(u32, 0), m.sleep_remaining);
    try std.testing.expectEqual(@as(usize, 1), m.cpu.pc); // PC didn't move during sleep

    try m.step(); // nop: cycle 5
    try std.testing.expectEqual(@as(u64, 5), m.cycles);
    try std.testing.expectEqual(@as(usize, 2), m.cpu.pc);
}

test "5.7 slp 0: costs 1 cycle, no extra sleep" {
    const parsed = try Parser.parse(std.testing.allocator, "slp 0\nnop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // slp 0: 1 cycle, sleep_remaining stays 0
    try std.testing.expectEqual(@as(u64, 1), m.cycles);
    try std.testing.expectEqual(@as(u32, 0), m.sleep_remaining);
    try m.step(); // nop
    try std.testing.expectEqual(@as(u64, 2), m.cycles);
}

test "5.7 run: executes until end of program" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 1 acc\nadd 2\nadd 3");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.run(1000);
    try std.testing.expectEqual(@as(i32, 6), m.cpu.acc);
    try std.testing.expectEqual(@as(u64, 3), m.cycles);
}

test "5.7 run: stops at cycle limit" {
    const parsed = try Parser.parse(std.testing.allocator, "loop:\nnop\njmp loop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.run(10);
    try std.testing.expectEqual(@as(u64, 10), m.cycles);
}

test "5.7 run: slp counts toward cycle limit" {
    const parsed = try Parser.parse(std.testing.allocator, "slp 5\nnop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.run(1000);
    try std.testing.expectEqual(@as(u64, 7), m.cycles); // 1 (slp) + 5 (sleep) + 1 (nop)
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

// --- Step 5.10: gen ---

test "5.10 gen: expands to mov/slp/mov/slp, total = 1+X+1+Y" {
    const parsed = try Parser.parse(std.testing.allocator, "gen p0 3 2\nnop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    // gen p0 3 2 → 4 instructions + nop = 5 instructions
    try std.testing.expectEqual(@as(usize, 5), program.instructions.len);

    var m = Machine.init(program, false);
    try m.run(1000);
    try std.testing.expectEqual(@as(u64, 10), m.cycles); // 1(mov)+1+3(slp 3)+1(mov)+1+2(slp 2)+1(nop)
}

test "5.10 gen: port ends at 0" {
    const parsed = try Parser.parse(std.testing.allocator, "gen p0 2 2");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.run(1000);
    try std.testing.expectEqual(@as(i32, 0), m.cpu.ports[0]);
}

test "5.10 gen: port is 100 after first mov" {
    const parsed = try Parser.parse(std.testing.allocator, "gen p0 3 2");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // mov 100 p0
    try std.testing.expectEqual(@as(i32, 100), m.cpu.ports[0]);
    try std.testing.expectEqual(@as(u64, 1), m.cycles);
}

test "5.10 gen: port becomes 0 after high phase" {
    const parsed = try Parser.parse(std.testing.allocator, "gen p0 2 3");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try m.step(); // mov 100 p0
    try m.step(); // slp 2 (instruction cycle)
    try m.step(); // sleep tick
    try m.step(); // sleep tick
    try m.step(); // mov 0 p0
    try std.testing.expectEqual(@as(i32, 0), m.cpu.ports[0]);
    try std.testing.expectEqual(@as(u64, 5), m.cycles);
}

// --- Step 6.0: runSlice — игровая семантика времени ---
// Один time unit = все инструкции подряд до slp/конца программы.
// После 6.1 старый step() и тесты 5.7/5.9/5.10 мигрируют на эту модель.

test "6.0 runSlice: straight-line program halts in one slice" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 1 acc\nadd 2");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    const y = try m.runSlice();
    try std.testing.expect(y == .halted);
    try std.testing.expect(m.halted);
    try std.testing.expectEqual(@as(i32, 3), m.cpu.acc);
    try std.testing.expectEqual(@as(u64, 2), m.cycles); // mov + add
}

test "6.0 runSlice: slp yields with duration, next slice resumes after it" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 1 acc\nslp 3\nmov 2 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);

    const y1 = try m.runSlice();
    try std.testing.expectEqual(@as(u32, 3), y1.sleep);
    try std.testing.expectEqual(@as(i32, 1), m.cpu.acc);
    try std.testing.expectEqual(@as(u64, 2), m.cycles); // mov + slp; сон бесплатен
    try std.testing.expect(!m.halted);

    const y2 = try m.runSlice();
    try std.testing.expect(y2 == .halted);
    try std.testing.expectEqual(@as(i32, 2), m.cpu.acc);
    try std.testing.expectEqual(@as(u64, 3), m.cycles);
}

test "6.0 runSlice: loop without slp fails loudly" {
    const parsed = try Parser.parse(std.testing.allocator, "loop:\nnop\njmp loop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    try std.testing.expectError(error.NeverSleeps, m.runSlice());
}

test "6.0 runSlice: already-halted machine stays halted" {
    const parsed = try Parser.parse(std.testing.allocator, "nop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    _ = try m.runSlice();
    const y = try m.runSlice();
    try std.testing.expect(y == .halted);
    try std.testing.expectEqual(@as(u64, 1), m.cycles); // второй вызов ничего не исполнил
}

test "6.0 runSlice: unconnected port reads 0, write is discarded" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 42 p0\nmov p0 acc\nmov 1 acc\nmov p1 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false); // pin_map весь null — чип вне платы
    const y = try m.runSlice();
    try std.testing.expect(y == .halted);
    try std.testing.expectEqual(@as(i32, 0), m.cpu.acc); // p1 читается как 0
}

test "6.0 runSlice: conditional flags survive across slices" {
    const parsed = try Parser.parse(std.testing.allocator, "teq 5 5\nslp 1\n+ mov 1 acc\n- mov 2 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var m = Machine.init(program, false);
    const y1 = try m.runSlice();
    try std.testing.expectEqual(@as(u32, 1), y1.sleep);
    const y2 = try m.runSlice();
    try std.testing.expect(y2 == .halted);
    try std.testing.expectEqual(@as(i32, 1), m.cpu.acc); // '+' исполнился после сна
}

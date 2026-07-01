const std = @import("std");
const MachineModule = @import("Machine.zig");
const Machine = MachineModule.Machine;
const Simulator = @import("Simulator.zig");
const Parser = @import("../parse/Parser.zig");

/// Один «провод» (net) между чипами. Simple I/O: хранит текущий уровень 0-100.
/// Пишет тот, кто исполняет `mov ... pN`; читают все машины, чей pin_map
/// смотрит на этот провод.
/// 6.3: сюда добавится kind (simple/xbus) и состояние блокирующей передачи.
pub const Wire = struct {
    value: i32 = 0,
};

/// Плата: набор чипов + провода + глобальное время.
///
/// Семантика времени — как в игре:
///  - квант синхронизации = time unit, а НЕ инструкция;
///  - за один time unit каждый готовый чип исполняет инструкции подряд
///    (Machine.runSlice), пока не упрётся в slp или конец программы;
///  - slp N усыпляет чип на N time units (wake_time = time + N);
///  - cycles считают исполненные инструкции (метрика мощности/score),
///    сон time units циклов НЕ стоит — это расхождение со старым step().
///
/// Порядок внутри time unit: машины шагают в порядке индекса, записи
/// в провода видны сразу (машина 1 в этом же такте видит то, что машина 0
/// только что записала). Это детерминированное упрощение — в игре чипы
/// «одновременны», но нам важна воспроизводимость.
pub const Board = struct {
    machines: []Machine,
    wires: []Wire,
    time: u64 = 0,

    /// Один time unit:
    ///  1. для каждой машины в порядке индекса: если не halted и
    ///     wake_time <= time — прогнать runSlice; при yield == .sleep N
    ///     выставить machine.wake_time = time + N;
    ///  2. time += 1.
    pub fn stepTimeUnit(self: *Board) !void {
        _ = self;
        return error.NotYetImplemented;
    }

    /// Крутит stepTimeUnit, пока time < limit и хоть одна машина
    /// не halted (спящая считается живой).
    pub fn run(self: *Board, limit: u64) !void {
        _ = self;
        _ = limit;
        return error.NotYetImplemented;
    }
};

// --- Tests: Step 6.1 — lock-step board with shared wires ---

test "6.1 board: two machines share a wire" {
    const parsed_a = try Parser.parse(std.testing.allocator, "mov 100 p0");
    defer parsed_a.deinit(std.testing.allocator);
    var prog_a = try Simulator.build(std.testing.allocator, parsed_a);
    defer prog_a.deinit(std.testing.allocator);

    const parsed_b = try Parser.parse(std.testing.allocator, "mov p0 acc");
    defer parsed_b.deinit(std.testing.allocator);
    var prog_b = try Simulator.build(std.testing.allocator, parsed_b);
    defer prog_b.deinit(std.testing.allocator);

    var wires = [_]Wire{.{}};

    var a = Machine.init(prog_a, false);
    a.wires = &wires;
    a.pin_map[0] = 0; // p0 чипа A → провод 0

    var b = Machine.init(prog_b, false);
    b.wires = &wires;
    b.pin_map[0] = 0; // p0 чипа B → тот же провод

    var machines = [_]Machine{ a, b };
    var board = Board{ .machines = &machines, .wires = &wires };

    try board.stepTimeUnit();
    // A (индекс 0) шагает первым и пишет 100; B читает уже новое значение.
    try std.testing.expectEqual(@as(i32, 100), wires[0].value);
    try std.testing.expectEqual(@as(i32, 100), machines[1].cpu.acc);
}

test "6.1 board: sleeping machine skips time units" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 1 acc\nslp 2\nmov 2 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var machines = [_]Machine{Machine.init(program, false)};
    var board = Board{ .machines = &machines, .wires = &.{} };

    try board.stepTimeUnit(); // t=0: mov 1 acc; slp 2 → wake_time=2
    try std.testing.expectEqual(@as(i32, 1), machines[0].cpu.acc);

    try board.stepTimeUnit(); // t=1: спит
    try std.testing.expectEqual(@as(i32, 1), machines[0].cpu.acc);

    try board.stepTimeUnit(); // t=2: проснулась, mov 2 acc, halt
    try std.testing.expectEqual(@as(i32, 2), machines[0].cpu.acc);
    try std.testing.expectEqual(@as(u64, 3), board.time);
}

test "6.1 board: gen producer drives consumer" {
    const parsed_a = try Parser.parse(std.testing.allocator, "loop:\ngen p0 3 2\njmp loop");
    defer parsed_a.deinit(std.testing.allocator);
    var prog_a = try Simulator.build(std.testing.allocator, parsed_a);
    defer prog_a.deinit(std.testing.allocator);

    const parsed_b = try Parser.parse(std.testing.allocator, "loop:\nmov p0 acc\nslp 1\njmp loop");
    defer parsed_b.deinit(std.testing.allocator);
    var prog_b = try Simulator.build(std.testing.allocator, parsed_b);
    defer prog_b.deinit(std.testing.allocator);

    var wires = [_]Wire{.{}};

    var a = Machine.init(prog_a, false);
    a.wires = &wires;
    a.pin_map[0] = 0;

    var b = Machine.init(prog_b, false);
    b.wires = &wires;
    b.pin_map[0] = 0;

    var machines = [_]Machine{ a, b };
    var board = Board{ .machines = &machines, .wires = &wires };

    // gen p0 3 2: high на t=0..2, low на t=3..4, снова high с t=5.
    // Consumer сэмплирует каждый time unit ПОСЛЕ producer'а (индекс 1).
    try board.stepTimeUnit(); // t=0
    try std.testing.expectEqual(@as(i32, 100), machines[1].cpu.acc);

    try board.stepTimeUnit(); // t=1
    try board.stepTimeUnit(); // t=2
    try board.stepTimeUnit(); // t=3: producer проснулся, mov 0 p0
    try std.testing.expectEqual(@as(i32, 0), machines[1].cpu.acc);

    try board.stepTimeUnit(); // t=4
    try board.stepTimeUnit(); // t=5: снова high
    try std.testing.expectEqual(@as(i32, 100), machines[1].cpu.acc);
}

test "6.1 board: run stops when all machines halt" {
    const parsed = try Parser.parse(std.testing.allocator, "mov 1 acc");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var machines = [_]Machine{Machine.init(program, false)};
    var board = Board{ .machines = &machines, .wires = &.{} };

    try board.run(1000);
    try std.testing.expectEqual(@as(i32, 1), machines[0].cpu.acc);
    try std.testing.expectEqual(@as(u64, 1), board.time);
}

test "6.1 board: run respects time limit" {
    const parsed = try Parser.parse(std.testing.allocator, "loop:\nslp 1\njmp loop");
    defer parsed.deinit(std.testing.allocator);
    var program = try Simulator.build(std.testing.allocator, parsed);
    defer program.deinit(std.testing.allocator);

    var machines = [_]Machine{Machine.init(program, false)};
    var board = Board{ .machines = &machines, .wires = &.{} };

    try board.run(10);
    try std.testing.expectEqual(@as(u64, 10), board.time);
}

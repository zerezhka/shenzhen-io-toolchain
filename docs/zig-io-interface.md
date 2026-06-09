# Zig 0.16 I/O Interface (`std.Io`) — Cheat Sheet

This project builds against **Zig 0.16.0**, which ships two big breaking changes:

1. **"Writergate"** (landed in 0.15) — the old generic `std.io.Reader`/`std.io.Writer`
   are gone. There is now a single non-generic `std.Io.Reader` / `std.Io.Writer` whose
   **buffer lives in the interface**, not the implementation.
2. **`std.Io` interface + "Juicy Main"** (0.16) — almost all of `std.posix` /
   `std.os` is replaced by a runtime-injected `Io` value, and `main` can now receive a
   pre-initialized `std.process.Init`.

> ⚠️ Casing matters: it is **`std.Io`** (capital I), not `std.io`. There is **no
> `std.io` namespace and no `std.io.default_io`** in 0.16 — any code using those will
> not compile (see [Gotchas](#gotchas-things-that-no-longer-exist)).

All API names below were verified against the installed stdlib at
`/usr/lib/zig/std/` (Io.zig, process.zig, Io/File.zig, Io/Writer.zig, Io/Dir.zig).

---

## 1. `main` signatures

There are three accepted shapes. Pick the smallest one that gives you what you need.

```zig
// (a) No injection — you build your own allocator/Io.
pub fn main() !void {}

// (b) Minimal — just args + environ, no allocator/Io provided for you.
pub fn main(init: std.process.Init.Minimal) !void {}

// (c) Full "Juicy Main" — pre-initialized allocator, arena, Io, environ.
pub fn main(init: std.process.Init) !void {}
```

The return type may be `void`, `!void`, `u8`, or `!u8`.

### `std.process.Init` fields (verified)

```zig
pub const Init = struct {
    minimal: Minimal,                 // superset: args + environ live here
    arena: *std.heap.ArenaAllocator,  // permanent, freed on exit, threadsafe
    gpa: Allocator,                   // GPA for temp allocs; leak-checks in Debug
    io: Io,                           // default Io for the target  ← the important one
    environ_map: *Environ.Map,        // env vars (not threadsafe)
    preopens: Preopens,               // mainly WASI

    pub const Minimal = struct {
        environ: Environ,
        args: Args,
    };
};
```

So to read CLI args + own an `Io` in one shot:

```zig
pub fn main(init: std.process.Init) !u8 {
    const io = init.io;
    const gpa = init.gpa;
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.skip(); // argv[0]
    // ...
}
```

> If you only take `Init.Minimal`, **you do not get an `io`** — you must construct one
> yourself (see §5). `sio`'s `main` takes the full `std.process.Init` and threads
> `init.io` into `assemble`, sidestepping this entirely.

---

## 2. Writers — `std.Io.Writer`

Core idea: **a writer always has a buffer.** You write into the buffer; bytes only reach
the OS on a full buffer or an explicit `flush()`. **Forgetting `flush()` loses output.**

### stdout / stderr / a file

`std.Io.File.writer(io, buffer)` returns a `File.Writer` struct. The actual
`std.Io.Writer` is its `.interface` field — you pass `&fw.interface` to anything that
wants a writer. (Get used to `&xyz.interface` everywhere.)

```zig
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buf: [4096]u8 = undefined;
    var fw = std.Io.File.stdout().writer(io, &buf); // File.Writer
    const w = &fw.interface;                          // *std.Io.Writer

    try w.writeAll("hello\n");
    try w.print("answer = {d}\n", .{42});
    try w.flush();                                    // REQUIRED
}
```

Key `std.Io.Writer` methods: `writeAll`, `print`, `writeByte`, `flush`,
`writableArray`, and `fixed(buffer)`.

### One-shot writes without manual buffering

`File.writeStreaming` pushes bytes straight through (handy for "dump this blob then
exit"):

```zig
// fn writeStreaming(file, io, header, data: []const []const u8, splat) !usize
_ = try std.Io.File.stdout().writeStreaming(io, out, &.{}, 1);
```

### In-memory writers

```zig
// Fixed slice — no allocation, errors when full.
var mem: [256]u8 = undefined;
var w = std.Io.Writer.fixed(&mem);
try w.print("{d}", .{x});
const written = w.buffered();          // the bytes so far

// Growable — std.Io.Writer.Allocating wraps an allocator.
var aw = std.Io.Writer.Allocating.init(gpa);
defer aw.deinit();
try aw.writer.print("{d}", .{x});
```

### `std.debug.print` still works

`std.debug.print(fmt, args)` writes to stderr and **auto-flushes** — fine for quick
diagnostics and what `sio` uses today. It needs no `io`. Use real writers for program
output.

---

## 3. Readers — `std.Io.Reader`

Symmetric to writers: `std.Io.File.reader(io, buffer)` → `File.Reader`, use
`&fr.interface` for a `*std.Io.Reader`. Common helpers on the interface:
`readSliceShort`, `fill`, `buffered`, `toss`, `streamRemaining`.

For "just give me the whole file", skip readers entirely and use `Dir` (next section).

---

## 4. Files & directories — `std.Io.Dir` / `std.Io.File`

`std.posix.open/read/write` are gone. Go through `Dir`/`File`, which **take `io` as an
argument**.

```zig
const cwd = std.Io.Dir.cwd();

// Read a whole file:
const src = try cwd.readFileAlloc(io, path, gpa, std.Io.Limit.limited(1 << 20));
defer gpa.free(src);

// Open / stream / close:
var file = try cwd.openFile(io, path, .{});
defer file.close(io);
const n = try file.length(io);
```

Renames worth knowing: `fs.File.read/write` → `File.readStreaming/writeStreaming`,
`getEndPos`/`setEndPos` → `File.length`/`File.setLength`.

> Note the **argument order** for `readFileAlloc` in 0.16 is
> `(self_dir, io, sub_path, allocator, limit)`, where `limit` is a
> `std.Io.Limit` — build it with `std.Io.Limit.limited(n)`, **not** a
> `.{ .size = n }` struct literal (it's an enum, not a struct).

---

## 5. Getting an `Io` without "Juicy Main"

If `main` takes `Init.Minimal` (or `void`), build a backend yourself. The default,
portable backend is `std.Io.Threaded`:

```zig
pub fn main(init: std.process.Init.Minimal) !u8 {
    var threaded = std.Io.Threaded.init(gpa); // needs an allocator
    defer threaded.deinit();
    const io = threaded.io();                 // <- a usable std.Io
    // ...
}
```

Backends available: `std.Io.Threaded` (OS thread pool — the safe default),
`std.Io.Evented` (io_uring/kqueue, **WIP, may not compile yet**), plus `Dispatch`,
`Uring`, `Kqueue`. For tests there is also `std.Io.Threaded.global_single_threaded`.

Simplest fix for a CLI that doesn't need fancy I/O: **switch `main` to take the full
`std.process.Init` and use `init.io`.**

---

## 6. Timers / clocks for benchmarks (cross-platform)

`bench.zig` currently hand-rolls `clock_gettime` via `std.os.linux` — Linux-only. The
`std.Io` timing API is portable and replaces it. Everything goes through `io`.

### Reading the clock

```zig
const Clock = std.Io.Clock;

const start = Clock.now(.awake, io);        // Io.Timestamp
// ... work ...
const elapsed = start.untilNow(io, .awake); // Io.Duration
std.debug.print("time: {d} ms\n", .{elapsed.toMilliseconds()});
```

### `std.Io.Clock` variants (verified)

| Variant        | Meaning                                                        |
|----------------|----------------------------------------------------------------|
| `.awake`       | Monotonic, excludes suspend (Linux `CLOCK_MONOTONIC`). **Use this for benchmarks.** |
| `.boot`        | Monotonic, includes suspend (`CLOCK_BOOTTIME`).                |
| `.real`        | Wall-clock / Unix time; can jump backwards. For timestamps, not durations. |
| `.cpu_process` | CPU time used by the whole process.                            |
| `.cpu_thread`  | CPU time used by the calling thread.                           |

### `Timestamp` / `Duration` API (verified)

```zig
// Clock entry points
Clock.now(clock, io) -> Io.Timestamp
Clock.resolution(clock, io) -> ResolutionError!Io.Duration   // granularity; 0 = unsupported

// Timestamp methods
ts.durationTo(other)   -> Duration
ts.untilNow(io, clock) -> Duration        // convenience: now - ts
ts.addDuration(d) / ts.subDuration(d) -> Timestamp
ts.toNanoseconds() / toMicroseconds() / toMilliseconds() / toSeconds()

// Duration constructors / accessors
Duration.fromNanoseconds(i96) / fromMicroseconds / fromMilliseconds / fromSeconds
d.toNanoseconds() / toMicroseconds() / toMilliseconds() / toSeconds()
Duration.zero, Duration.max

// Sleeping (cancelable, needs io)
try Clock.Duration.fromMilliseconds(10).sleep(io);
```

### Portable benchmark skeleton

```zig
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const Clock = std.Io.Clock;

    const start = Clock.now(.awake, io);
    for (0..iterations) |_| {
        // work under test
    }
    const elapsed = start.untilNow(io, .awake);

    const ms = elapsed.toMilliseconds();
    const ns = elapsed.toNanoseconds();
    std.debug.print("iterations: {d}\n", .{iterations});
    std.debug.print("time:       {d} ms ({d} ns)\n", .{ ms, ns });
}
```

This drops the `std.os.linux.timespec` / `clock_gettime` dance and the
`std.time.ns_per_*` arithmetic — `Duration` does the conversions.

---

## Gotchas (things that no longer exist)

These **fail to compile** against 0.16 (an earlier WIP `sio` tree hit all of these; the
current `main.zig` has since been migrated and builds clean):

- `std.io.default_io` — **no such symbol.** There is no ambient default `Io`; obtain one
  from `init.io` or construct `std.Io.Threaded` (§5).
- `std.io.getStdOut()` — gone. Use `std.Io.File.stdout()` (+ `.writer(io, buf)` /
  `.writeStreaming(...)`).
- Generic `std.io.Reader(...)` / `std.io.Writer(...)` / `std.io.BufferedWriter` — replaced
  by non-generic `std.Io.Reader` / `std.Io.Writer` with the buffer in the interface.
- Most `std.posix.*` mid-level wrappers (`open`, `read`, `write`, …) — go **higher**
  (`std.Io.Dir`/`File`) or **lower** (`std.posix.system.*`).
- `bench.zig`'s `std.os.linux.clock_gettime` works but is Linux-only — prefer
  `std.Io.Clock` (§6).

### How `sio assemble` does it

`main` takes the full `std.process.Init` and threads `init.io` into `assemble` (the
alternative would be building a `Threaded` backend, §5):

```zig
fn assemble(io: std.Io, gpa: std.mem.Allocator, path: []const u8) !void {
    const source = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, std.Io.Limit.limited(1 << 20));
    defer gpa.free(source);
    // ... preprocess / parse / emit ...

    var buf: [4096]u8 = undefined;
    var fw = std.Io.File.stdout().writer(io, &buf);
    try fw.interface.writeAll(out);
    try fw.interface.flush();
}
```

---

## Sources

- [Zig 0.16.0 Release Notes](https://ziglang.org/download/0.16.0/release-notes.html)
- [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html) (Writergate)
- [Writergate PR #24329](https://github.com/ziglang/zig/pull/24329)
- [Zig's new Writer — openmymind.net](https://www.openmymind.net/Zigs-New-Writer/)
- [Async I/O in Zig 0.16, today — Lukáš Lalinský](https://lalinsky.com/2026/05/11/async-io-in-zig-016-today.html)
- Verified against installed stdlib: `/usr/lib/zig/std/{Io.zig, process.zig, Io/File.zig, Io/Writer.zig, Io/Dir.zig}`
</content>
</invoke>

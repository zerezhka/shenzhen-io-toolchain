using NUnit.Framework;
using Sio.Simulator.Cpu;
using Sio.Simulator.Isa;
using Sio.Simulator.Parse;
using Sio.Simulator.Ports;
using Sio.Simulator.Runtime;
using Sio.Simulator.Trace;

namespace Sio.UnitTests.Simulator
{
    public sealed class BasicInstructionTests
    {
        [Test]
        public void Mov_Registers()
        {
            var parser = new ProgramParser();
            var program = parser.Parse("mov 42 acc\nmov acc dat");
            var cpu = new CpuState(hasDatRegister: true);
            var ports = new PortBus(4);
            var cycles = new CycleController(100);
            var tracer = new Tracer();
            var engine = new StepEngine(cpu, ports, cycles, tracer, program);

            // Execute first instruction: mov 42 acc
            engine.Step();
            Assert.AreEqual(42, cpu.Acc);

            // Execute second instruction: mov acc dat
            engine.Step();
            Assert.AreEqual(42, cpu.Dat);
        }

        [Test]
        public void Add_Sub_Arithmetic()
        {
            var parser = new ProgramParser();
            var program = parser.Parse("mov 10 acc\nadd 5\nsub 3");
            var cpu = new CpuState();
            var ports = new PortBus(4);
            var cycles = new CycleController(100);
            var tracer = new Tracer();
            var engine = new StepEngine(cpu, ports, cycles, tracer, program);

            // mov 10 acc
            engine.Step();
            Assert.AreEqual(10, cpu.Acc);

            // add 5
            engine.Step();
            Assert.AreEqual(15, cpu.Acc);

            // sub 3
            engine.Step();
            Assert.AreEqual(12, cpu.Acc);
        }

        [Test]
        public void Teq_ConditionalExecution()
        {
            var parser = new ProgramParser();
            var program = parser.Parse("mov 10 acc\nteq acc 10\n+ mov 99 acc");
            var cpu = new CpuState();
            var ports = new PortBus(4);
            var cycles = new CycleController(100);
            var tracer = new Tracer();
            var engine = new StepEngine(cpu, ports, cycles, tracer, program);

            // mov 10 acc
            engine.Step();
            Assert.AreEqual(10, cpu.Acc);
            Assert.IsFalse(cpu.ConditionalPositiveEnabled);

            // teq acc 10 (should enable '+' instructions)
            engine.Step();
            Assert.IsTrue(cpu.ConditionalPositiveEnabled);

            // + mov 99 acc (should execute because '+' is enabled)
            engine.Step();
            Assert.AreEqual(99, cpu.Acc);
        }

        [Test]
        public void Jmp_Label()
        {
            var parser = new ProgramParser();
            var program = parser.Parse("mov 1 acc\nloop:\nadd 1\nteq acc 5\n+ jmp end\njmp loop\nend:\nmov 0 acc");
            var cpu = new CpuState();
            var ports = new PortBus(4);
            var cycles = new CycleController(100);
            var tracer = new Tracer();
            var engine = new StepEngine(cpu, ports, cycles, tracer, program);

            // Run until completion
            engine.Run();

            // Should end with acc = 0 (from the end: label)
            Assert.AreEqual(0, cpu.Acc);
        }
    }
}


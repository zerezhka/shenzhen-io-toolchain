using System;

namespace Sio.Simulator.Cpu
{
    /// <summary>
    /// Represents the CPU state for a single MCU.
    /// </summary>
    public sealed class CpuState
    {
        /// <summary>
        /// Accumulator register (always available).
        /// </summary>
        public int Acc { get; set; }

        /// <summary>
        /// Data register (only available on MC6000, null on MC4000).
        /// </summary>
        public int? Dat { get; set; }

        /// <summary>
        /// Program counter (current instruction index).
        /// </summary>
        public int Pc { get; set; }

        /// <summary>
        /// Conditional execution state: true if '+' instructions are enabled, false if '-' instructions are enabled.
        /// Initially false (all conditional instructions disabled).
        /// </summary>
        public bool ConditionalPositiveEnabled { get; set; }

        /// <summary>
        /// For tcp instruction: when true, both '+' and '-' instructions are disabled (equal condition).
        /// </summary>
        public bool ConditionalEqualState { get; set; }

        /// <summary>
        /// Whether the CPU is currently sleeping.
        /// </summary>
        public bool IsSleeping { get; set; }

        /// <summary>
        /// Remaining sleep cycles (when IsSleeping is true).
        /// </summary>
        public int SleepCyclesRemaining { get; set; }

        /// <summary>
        /// Whether the CPU is waiting for XBus data (slx instruction).
        /// </summary>
        public bool IsWaitingForXBus { get; set; }

        /// <summary>
        /// XBus pin being waited on (when IsWaitingForXBus is true).
        /// </summary>
        public int? WaitingXBusPin { get; set; }

        /// <summary>
        /// Creates a new CPU state initialized to zero.
        /// </summary>
        public CpuState(bool hasDatRegister = false)
        {
            Acc = 0;
            Dat = hasDatRegister ? 0 : (int?)null;
            Pc = 0;
            ConditionalPositiveEnabled = false;
            IsSleeping = false;
            SleepCyclesRemaining = 0;
            IsWaitingForXBus = false;
            WaitingXBusPin = null;
        }

        /// <summary>
        /// Clamps a value to the valid register range (-999 to 999).
        /// </summary>
        public static int ClampValue(int value)
        {
            if (value < -999) return -999;
            if (value > 999) return 999;
            return value;
        }

        /// <summary>
        /// Sets the acc register with clamping.
        /// </summary>
        public void SetAcc(int value)
        {
            Acc = ClampValue(value);
        }

        /// <summary>
        /// Sets the dat register with clamping (only if available).
        /// </summary>
        public void SetDat(int value)
        {
            if (Dat.HasValue)
            {
                Dat = ClampValue(value);
            }
            else
            {
                throw new InvalidOperationException("dat register is not available on this MCU");
            }
        }
    }
}


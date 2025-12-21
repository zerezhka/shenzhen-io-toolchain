namespace Sio.Simulator.Runtime
{
    /// <summary>
    /// Manages cycle counting and stop conditions for simulation.
    /// </summary>
    public sealed class CycleController
    {
        private long _currentCycle;
        private readonly long? _cycleLimit;

        /// <summary>
        /// Current cycle count.
        /// </summary>
        public long CurrentCycle => _currentCycle;

        /// <summary>
        /// Whether the cycle limit has been reached.
        /// </summary>
        public bool IsLimitReached => _cycleLimit.HasValue && _currentCycle >= _cycleLimit.Value;

        /// <summary>
        /// Creates a new cycle controller.
        /// </summary>
        /// <param name="cycleLimit">Maximum cycles to execute, or null for unlimited</param>
        public CycleController(long? cycleLimit = null)
        {
            _currentCycle = 0;
            _cycleLimit = cycleLimit;
        }

        /// <summary>
        /// Advances the cycle counter by the specified amount.
        /// </summary>
        public void Advance(long cycles = 1)
        {
            if (cycles < 0)
                throw new System.ArgumentOutOfRangeException(nameof(cycles), "Cycles must be >= 0");
            
            _currentCycle += cycles;
        }

        /// <summary>
        /// Resets the cycle counter to zero.
        /// </summary>
        public void Reset()
        {
            _currentCycle = 0;
        }
    }
}


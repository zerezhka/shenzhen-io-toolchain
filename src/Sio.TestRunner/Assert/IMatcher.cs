using System.Collections.Generic;
using Sio.TestRunner.Model;
using Sio.TestRunner.Runtime;

namespace Sio.TestRunner.Assert
{
    /// <summary>
    /// Interface for output matchers that validate test results.
    /// </summary>
    public interface IMatcher
    {
        /// <summary>
        /// Matches actual outputs against expected outputs.
        /// </summary>
        /// <returns>True if match, false otherwise</returns>
        bool Match(ExpectedOutput expected, List<SimulatorHarness.PortOutput> actual, out string failureReason);
    }
}


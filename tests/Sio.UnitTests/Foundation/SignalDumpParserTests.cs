using NUnit.Framework;
using Sio.TestRunner.IO;

namespace Sio.UnitTests.Foundation
{
    public sealed class SignalDumpParserTests
    {
        [Test]
        public void ParseLine_Valid()
        {
            var s = SignalDumpParser.ParseLine("Sz010.2:80,0,1,2");
            Assert.AreEqual("Sz010.2", s.Id);
            Assert.AreEqual(80, s.Rate);
            Assert.AreEqual(3, s.Samples.Count);
            Assert.AreEqual(2, s.Samples[2]);
        }

        [Test]
        public void ParseLine_Invalid_Throws()
        {
            Assert.Throws<System.FormatException>(() => SignalDumpParser.ParseLine("bad"));
        }
    }
}



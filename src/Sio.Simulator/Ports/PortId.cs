using System;

namespace Sio.Simulator.Ports
{
    public readonly struct PortId : IEquatable<PortId>
    {
        public int Index { get; }

        public PortId(int index)
        {
            if (index < 0) throw new ArgumentOutOfRangeException(nameof(index), "Port index must be >= 0");
            Index = index;
        }

        public override string ToString() => "p" + Index;

        public static bool TryParse(string s, out PortId portId)
        {
            portId = default(PortId);
            if (string.IsNullOrWhiteSpace(s)) return false;
            s = s.Trim();
            if (s.Length < 2) return false;
            if (s[0] != 'p' && s[0] != 'P') return false;
            if (!int.TryParse(s.Substring(1), out var idx)) return false;
            if (idx < 0) return false;
            portId = new PortId(idx);
            return true;
        }

        public bool Equals(PortId other) => Index == other.Index;
        public override bool Equals(object obj) => obj is PortId other && Equals(other);
        public override int GetHashCode() => Index;
        public static bool operator ==(PortId left, PortId right) => left.Equals(right);
        public static bool operator !=(PortId left, PortId right) => !left.Equals(right);
    }
}



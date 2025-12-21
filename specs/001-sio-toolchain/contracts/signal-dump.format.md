# Signal dump format (optional adapter)

This document describes an optional, user-supplied “signal dump” input format that can be used to populate test `inputs` streams without manually transcribing samples.

## Line format

Each non-empty line contains:

`<stream-id>:<rate>,<sample-0>,<sample-1>,...`

Where:

- `<stream-id>` is an identifier (string) used to refer to the stream
- `<rate>` is an integer (rate/interval metadata carried through to test inputs)
- `<sample-i>` are integer samples

### Example

`Sz010.2:80,0,0,13572,9454,2709,...`

## Notes

- Parsing must be deterministic.
- The toolchain must treat these dumps as **local-only user input**; the repository should not ship copyrighted dumps.
- This adapter produces `SignalStream` objects used by tests and simulation port mappings.



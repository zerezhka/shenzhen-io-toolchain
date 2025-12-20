# Shenzhen I/O: External Development & Simulation Environment

### 🎯 Project Overview
This project provides a **proper IDE experience for prototyping schemes** in **Shenzhen I/O**. It bypasses the restrictive in-game code editor, offering a professional development environment with modern tooling, syntax highlighting, and debugging capabilities.

**Goal:** Create a seamless prototyping workflow where you can:
* Develop complex algorithms without line limits or character constraints
* Use descriptive variable names, extensive comments, and clear formatting
* Test and iterate on schemes with real game data before optimization
* Leverage full IDE features (autocomplete, search, refactoring, etc.)
* Debug step-by-step with register monitoring and output verification

---

### 🛠 Architecture & Tools
The prototyping environment integrates three core components:

1.  **IDE (Visual Studio Code):** 
    * Full-featured code editor with syntax highlighting, IntelliSense, and extensions
    * Multi-file project support for organizing complex schemes
    * Git integration for version control and experimentation tracking
    * Unlimited comments, descriptive variable names, and clear formatting
2.  **Compiler ([omaskery/shenzhen.io-assembler](https://github.com/omaskery/shenzhen.io-assembler)):**
    * Preprocessor that handles `alias` and `const` definitions
    * Minifies code by stripping comments and whitespace for game compatibility
    * Enables extended syntax during development, clean output for deployment
3.  **Simulator ([nielseneli/shenzhen-io](https://github.com/nielseneli/shenzhen-io)):**
    * C#-based runtime that executes assembly logic
    * Step-by-step debugging with register inspection
    * Testing without the 9-14 line limit enforced by the game's microcontrollers

---

### 🚀 Prototyping Workflow

#### 1. Development (IDE Experience)
Write your scheme logic in `.asm` or `.s` files using the extended syntax.
* **No Line Limits:** Use as many lines as needed to implement complex algorithms
* **Rich Documentation:** Add detailed comments explaining each section of your algorithm
* **Descriptive Aliases:** Use meaningful names for ports (e.g., `alias audio_in = p0`, `alias output = p1`)
* **Code Organization:** Split complex logic across multiple files if needed
* **IDE Features:** Leverage search, replace, refactoring, and all standard editor capabilities

#### 2. Signal Integration
The environment uses raw data dumps (like `nulyu.txt`) to simulate game conditions.
* The system parses game-specific signal formats: `[Component].[Port]: [Frequency], [V1], [V2]...`
* These values are injected into the simulator as input streams for testing
* Prototype with real game data to catch edge cases early

#### 3. Simulation & Validation
Run the compiled code through the C# simulator.
* **Step-by-Step Debugging:** Monitor `acc` and `dat` registers in real-time
* **Output Verification:** Compare the simulator's output against expected values
* **Iterative Refinement:** Test, debug, and improve your scheme before optimization

---

### 📂 Input Data Reference
The project utilizes the following data sources for the "Rubbish Audio Thing" contract:
* **`nulyu.txt`**: Contains the input waveforms and timing data for the test cases.
* **`amplifier.txt`**: Contains the functional requirements for the Harmonic Maximization Algorithm.

---

### 🔧 Setup Instructions
1.  **VS Code:** Install the `Shenzhen I/O Support` extension for syntax highlighting.
2.  **Compiler:** Ensure Python 3.x is installed to run the `shenasm.py` preprocessor.
3.  **Simulator:** Install [.NET SDK](https://dotnet.microsoft.com/download) to build and run the `nielseneli` simulator project.
4.  **Minification:** Once the logic is verified, use the compiler to generate the `.pzp` format for copy-pasting into the game.

---

### 📉 Goals
**Primary Goal:** Provide a proper IDE experience for prototyping schemes in Shenzhen I/O.

**Specific Objectives:**
* Prototype complex algorithms without the stress of the 14-line limit
* Use modern IDE features (syntax highlighting, autocomplete, debugging) for scheme development
* Verify edge cases using full data traces from game dumps
* Iteratively refine and test schemes before optimization
* Seamlessly transition from prototype to minified production code
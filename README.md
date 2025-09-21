# WolfPy Package

A Mathematica package for converting Mathematica expressions and functions to Python format with robust Greek letter support and automatic file handling.

## Features

- **Expression Conversion**: Convert Mathematica expressions to Python strings with proper operator mapping
- **Function Conversion**: Convert Mathematica function definitions to Python functions with correct parameter extraction
- **Universal Greek Letter Support**: Automatically converts any Greek letter using general pattern `\[Name] → name` (τ → tau, φ → phi, λ → lambda, etc.)
- **Mathematical Functions**: Maps Mathematica functions to NumPy equivalents (Sin → np.sin, Exp → np.exp, Sqrt → ()**(1/2), etc.)
- **Smart File Handling**: Automatically creates directories and files if they don't exist
- **Flexible Output**: Print to console, save to files, or append to existing files
- **Cross-Platform**: Works on macOS, Linux, and Windows

## Installation

### Automatic Installation (Recommended)

1. Download or clone the WolfPy folder
2. Open Terminal and navigate to the WolfPy directory
3. Run the installation script:

```bash
# For user installation (recommended)
./install.sh

# For system-wide installation (requires admin privileges)
./install.sh --system

# For help
./install.sh --help
```

4. After installation, load the package in Mathematica:

```mathematica
<<WolfPy`
```

### Manual Installation

If you prefer manual installation:

1. Copy the WolfPy folder to your Mathematica Applications directory:
   - **macOS**: `~/Library/Mathematica/Applications/`
   - **Linux**: `~/.Mathematica/Applications/`
   - **Windows**: `%USERPROFILE%\AppData\Roaming\Mathematica\Applications\`

2. Load the package in Mathematica:

```mathematica
<<WolfPy`
```

### Uninstallation

To remove WolfPy:

```bash
# Interactive uninstall
./uninstall.sh

# Force remove all installations
./uninstall.sh --force

# Clean up old backup directories
./uninstall.sh --cleanup
```

## Usage

### Basic Expression Conversion

```mathematica
(* Convert and print to console *)
ToPythonString[a^2 + b*c]
(* Output: ((a**2) + (b * c)) *)

(* Convert Greek letters *)
ToPythonString[α^2 + β*γ]
(* Output: ((alpha**2) + (beta * gamma)) *)

(* Stigma theory example *)
ToPythonString[ς*(υ^2 + τ*ω)]
(* Output: (varsigma * ((upsilon**2) + (tau * omega))) *)
```

### Enhanced Square Root and Fractional Power Combination

```mathematica
(* Basic square root combination (assumes positive variables) *)
CombineSqrt[Sqrt[a]*Sqrt[b]]
(* Output: Sqrt[a*b] *)

(* Division of square roots *)
CombineSqrt[Sqrt[a]/Sqrt[b]]
(* Output: Sqrt[a/b] *)

(* NEW: General fractional powers a^(n/2) *)
CombineSqrt[a^(3/2) * b^(1/2)]
(* Output: Sqrt[a^3 * b] *)

CombineSqrt[a^(5/2) * b^(-1/2) * c^(3/2)]
(* Output: Sqrt[a^5 * c^3 / b] *)

(* NEW: Negative fractional powers (common in physics) *)
CombineSqrt[ups2^(-3/2) * stigma^(1/2)]
(* Output: Sqrt[stigma / ups2^3] *)

(* Mathematically rigorous with assumptions *)
CombineSqrt[Sqrt[a]*Sqrt[b], a > 0 && b > 0]
(* Output: Sqrt[a*b] *)

CombineSqrt[Sqrt[a]*Sqrt[b], a < 0 && b < 0]
(* Output: -Sqrt[a*b] *)

(* Complex fractional power example *)
CombineSqrt[a^(3/2)*b^(1/2), a > 0 && b > 0]
(* Output: Sqrt[a^3 * b] *)

(* Integration with Python conversion *)
ToPythonString[CombineSqrt[a^(3/2)*Sqrt[b]]]
(* Output: "(a**3 * b)**(1/2)" *)

(* Insufficient assumptions - remains unchanged *)
CombineSqrt[Sqrt[x]*Sqrt[y], x > 0]
(* Output: Sqrt[x]*Sqrt[y] (unchanged because y's sign unknown) *)
```

### Function Conversion

```mathematica
(* Define a Mathematica function *)
myFunc[x_] := x^2 + Sin[x]

(* Convert and print to console *)
ToPython[myFunc]
(* Output:
def myFunc(x):
    return x**2 + np.sin(x)
*)

(* Greek letter function *)
phiFunc[\[Phi]_, \[Alpha]_, \[Beta]_] := \[Phi]*Sin[\[Alpha]] + Cos[\[Beta]]
ToPython[phiFunc]
(* Output:
def phiFunc(phi, alpha, beta):
    return np.cos(beta) + phi*np.sin(alpha)
*)
```

### Saving to Files

```mathematica
(* Save expression to file - creates directory if needed *)
ToPythonString[a^2 + b/c, "output/my_expression.py"]

(* Save function to file *)
ToPython[myFunc, "functions/my_function.py"]

(* Append to existing file *)
ToPython[anotherFunc, "functions/my_function.py", True]

(* Multiple functions in one file *)
ToPython[phiFunc, "physics_functions.py"]
ToPython[stigmaFunc, "physics_functions.py", True]
```

## Supported Conversions

### Mathematical Operators
- `^` → `**` (exponentiation)
- `/` → `/` (division)
- `*` → `*` (multiplication)
- `+` → `+` (addition)
- `-` → `-` (subtraction)

### Functions
- `Sin[x]` → `np.sin(x)`
- `Cos[x]` → `np.cos(x)`
- `Tan[x]` → `np.tan(x)`
- `ArcSin[x]` → `np.arcsin(x)`
- `ArcCos[x]` → `np.arccos(x)`
- `ArcTan[x]` → `np.arctan(x)`
- `Sinh[x]` → `np.sinh(x)`
- `Cosh[x]` → `np.cosh(x)`
- `Tanh[x]` → `np.tanh(x)`
- `Exp[x]` → `np.exp(x)`
- `Log[x]` → `np.log(x)`
- `Sqrt[x]` → `(x)**(1/2)`
- `Abs[x]` → `np.abs(x)`
- `Sign[x]` → `np.sign(x)`
- `Floor[x]` → `np.floor(x)`
- `Ceiling[x]` → `np.ceil(x)`
- `Round[x]` → `np.round(x)`

### Constants
- `Pi` → `np.pi`
- `E` → `np.e`

### Enhanced Square Root and Fractional Power Combination
- `CombineSqrt[expr]` → Combines fractional powers `a^(n/2)` syntactically (assumes positive variables)
- `CombineSqrt[expr, assumptions]` → Mathematically rigorous combination with proper sign handling
- Handles any fractional power: `a^(3/2)`, `a^(-5/2)`, etc.
- Combines multiple terms: `a^(3/2)*b^(1/2)` → `Sqrt[a^3*b]`

### Data Structures
- `{a, b, c}` → `np.array([a, b, c])`


## Requirements

- Mathematica (tested on version 12+)
- Python with NumPy (for using the generated Python code)

## Mathematical Notes

### Square Root Combination (`CombineSqrt`)

The `CombineSqrt` function handles the mathematical identity `√a × √b = √(ab)`, which is **not always true** for complex numbers or negative values.

**Mathematical Background:**
- `√a × √b = √(ab)` when at least one of `a, b ≥ 0`
- `√a × √b = -√(ab)` when both `a, b < 0`

**Examples:**
- `√4 × √9 = 2 × 3 = 6 = √36` ✓
- `√(-4) × √(-9) = (2i) × (3i) = -6 ≠ √36 = 6` ✗

**Usage Modes:**
1. **Syntactic Mode**: `CombineSqrt[expr]` assumes positive variables (fast, cosmetic)
2. **Rigorous Mode**: `CombineSqrt[expr, assumptions]` uses mathematical assumptions for correct signs

## Limitations

- Derivatives require manual handling
- Some advanced Mathematica functions may not have direct NumPy equivalents
- Complex nested structures may need manual adjustment
- `CombineSqrt` without assumptions may produce incorrect results for complex/negative numbers

## Contributing

Feel free to extend the `$greekReplacements` and `$functionReplacements` lists in the package to add more conversions as needed.

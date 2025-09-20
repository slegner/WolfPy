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

### Greek Letters (Universal Support)
The package automatically converts any Greek letter using the pattern `\[Name] → name`:
- `τ` (\\[Tau]) → `tau`
- `φ` (\\[Phi]) → `phi`
- `α` (\\[Alpha]) → `alpha`
- `β` (\\[Beta]) → `beta`
- `γ` (\\[Gamma]) → `gamma`
- `δ` (\\[Delta]) → `delta`
- `λ` (\\[Lambda]) → `lambda`
- `μ` (\\[Mu]) → `mu`
- `ν` (\\[Nu]) → `nu`
- `ω` (\\[Omega]) → `omega`
- `θ` (\\[Theta]) → `theta`
- `ς` (\\[FinalSigma]) → `finalsigma`
- And **all other** Greek letters automatically!

### Data Structures
- `{a, b, c}` → `np.array([a, b, c])`

## Examples for Stigma Theory

```mathematica
(* Load the package *)
Get["WolfPy/WolfPy.m"]

(* Define a Stigma theory function *)
stigmaFunc[τ_, ς_, υ_] := Exp[-ς*τ]*Cos[υ*τ]

(* Convert to Python *)
ToPython[stigmaFunc]
(* Output:
def stigmaFunc(tau, varsigma, upsilon):
    return (np.exp(((-varsigma) * tau)) * np.cos((upsilon * tau)))
*)

(* Power series example *)
powerSeries[τ_] := a1*τ + a2*τ^2 + a3*τ^3
ToPython[powerSeries, "stigma_functions.py"]
```

## Requirements

- Mathematica (tested on version 12+)
- Python with NumPy (for using the generated Python code)

## Limitations

- Derivatives require manual handling
- Some advanced Mathematica functions may not have direct NumPy equivalents
- Complex nested structures may need manual adjustment

## Contributing

Feel free to extend the `$greekReplacements` and `$functionReplacements` lists in the package to add more conversions as needed.

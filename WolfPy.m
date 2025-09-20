(* ::Package:: *)

BeginPackage["WolfPy`"];

(* ::Section:: *)
(*Usage messages for the public functions*)

ToPython::usage = "ToPython[func] converts a Mathematica function definition to a Python function and prints it.
ToPython[func, \"file.py\"] converts the function and saves it to the specified file.
ToPython[func, \"file.py\", True] appends to the file instead of overwriting.";

ToPythonString::usage = "ToPythonString[expr] converts a Mathematica expression to a Python string and prints it.
ToPythonString[expr, \"file.py\"] converts the expression and saves it to the specified file.
ToPythonString[expr, \"file.py\", True] appends to the file instead of overwriting.";

(* ::Section:: *)
(*Implementation*)

Begin["`Private`"];

(* --- Helper Data and Functions --- *)

(* String replacement rules for converting Mathematica expressions to Python *)
$stringReplacementRules = {
  (* Handle Sqrt specifically first - Sqrt[x] -> (x)**(1/2) *)
  RegularExpression["Sqrt\\[([^\\]]+)\\]"] -> "($1)**(1/2)",
  
  (* Handle Power function - Power[x, y] -> (x)**(y) *)  
  RegularExpression["Power\\[([^,]+),\\s*([^\\]]+)\\]"] -> "($1)**($2)",
  
  (* Trigonometric functions with np prefix *)
  "Sin[" -> "np.sin(",
  "Cos[" -> "np.cos(",
  "Tan[" -> "np.tan(",
  "ArcSin[" -> "np.arcsin(",
  "ArcCos[" -> "np.arccos(",
  "ArcTan[" -> "np.arctan(",
  "Sinh[" -> "np.sinh(",
  "Cosh[" -> "np.cosh(",
  "Tanh[" -> "np.tanh(",
  
  (* Other mathematical functions with np prefix *)
  "Log[" -> "np.log(",
  "Exp[" -> "np.exp(",
  "Abs[" -> "np.abs(",
  "Sign[" -> "np.sign(",
  "Floor[" -> "np.floor(",
  "Ceiling[" -> "np.ceil(",
  "Round[" -> "np.round(",
  
  (* Constants with np prefix *)
  "Pi" -> "np.pi",
  "E" -> "np.e",
  "I" -> "1j",
  
  (* Replace remaining brackets with parentheses *)
  "[" -> "(",
  "]" -> ")"
};

(* --- Helper Functions --- *)


(* --- Core Expression Converter --- *)

(* Simple and robust conversion using InputForm + string replacement *)
pythonFormat[expr_] := Module[{result},
  (* Convert to InputForm string with ASCII encoding to get \[name] notation *)
  result = ToString[expr, InputForm, CharacterEncoding -> "ASCII"];
  
  (* Convert \[Name] to lowercase name using corrected regex pattern *)
  result = StringReplace[result, 
    RegularExpression["\\\\\\[([^]]+)]"] :> ToLowerCase["$1"]];
  
  (* Apply remaining string replacements *)
  result = StringReplace[result, $stringReplacementRules];
  
  (* Handle ^ to ** conversion *)
  result = StringReplace[result, "^" -> "**"];
  
  (* Handle any remaining exponential patterns *)
  result = StringReplace[result, RegularExpression["([a-zA-Z0-9_]+)\\^([a-zA-Z0-9_]+)"] -> "$1**$2"];
  
  result
];


(* --- Public Functions --- *)

(* ToPythonString: Converts a single expression *)
ToPythonString::ioerr = "Could not write to file `1`.";
ToPythonString[expr_, file_String : "", append_: False] := Module[{result},
  result = pythonFormat[Unevaluated[expr]];
  
  Which[
    file === "", 
    (* No file specified - just print the result *)
    Print[result],
    
    append === True,
    (* Append to file - create directory if needed *)
    Module[{dir = DirectoryName[file]},
      If[dir =!= "" && !DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
      Check[
        Export[file, result <> "\n", "Text", "Append" -> True],
        Message[ToPythonString::ioerr, file]
      ]
    ],
    
    True,
    (* Overwrite file - create directory if needed *)
    Module[{dir = DirectoryName[file]},
      If[dir =!= "" && !DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
      Check[
        Export[file, result, "Text"],
        Message[ToPythonString::ioerr, file]
      ]
    ]
  ];
  
  result
];

(* ToPython: Converts a full function definition *)
ToPython::nodef = "No definition found for the symbol `1`.";
ToPython[f_Symbol, file_String : "", append_: False] := Module[
  {def, lhs, rhs, funcName, args, argString, bodyString, pyFunc},
  
  def = DownValues[f];
  If[def === {},
    Message[ToPython::nodef, f];
    Return[$Failed];
  ];
  
  (* Use the first definition found for the symbol *)
  {lhs, rhs} = First[def] /. RuleDelayed -> List;
  
  (* Extract function name - handle HoldPattern wrapper *)
  funcName = Switch[Head[lhs],
    HoldPattern, 
    (* Extract the function symbol from inside HoldPattern *)
    SymbolName[lhs[[1, 0]]],
    _, SymbolName[Head[lhs]]
  ];
  
  (* Extract arguments and clean them up *)
  args = Cases[lhs, p_Pattern :> p[[1]], Infinity, Heads -> True];
  (* Convert each argument symbol to Python parameter name using general conversion *)
  args = Map[
    Function[sym,
      Module[{result},
        result = ToString[sym, InputForm, CharacterEncoding -> "ASCII"];
        result = StringReplace[result, 
          RegularExpression["\\\\\\[([^]]+)]"] :> ToLowerCase["$1"]];
        result
      ]
    ],
    args
  ];
  argString = StringRiffle[args, ", "];
  
  (* Convert the function body *)
  bodyString = pythonFormat[rhs];
  
  (* Assemble the final Python function string *)
  pyFunc = StringTemplate["def `name`(`args`):\n    return `body`"][<|
    "name" -> funcName,
    "args" -> argString,
    "body" -> bodyString
  |>];
  
  Which[
    file === "",
    (* No file specified - just print the result *)
    Print[pyFunc],
    
    append === True,
    (* Append to file - create directory if needed *)
    Module[{dir = DirectoryName[file]},
      If[dir =!= "" && !DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
      Check[
        Export[file, pyFunc <> "\n\n", "Text", "Append" -> True],
        Message[ToPythonString::ioerr, file]
      ]
    ],
    
    True,
    (* Overwrite file - create directory if needed *)
    Module[{dir = DirectoryName[file]},
      If[dir =!= "" && !DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
      Check[
        Export[file, pyFunc, "Text"],
        Message[ToPythonString::ioerr, file]
      ]
    ]
  ];
  
  pyFunc
];

End[]; (* `Private` *)

EndPackage[]; (* WolfPy` *)
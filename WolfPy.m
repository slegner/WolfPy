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

CombineSqrt::usage = "CombineSqrt[expr] combines fractional powers (n/2) in mathematical expressions with proper sign handling.
CombineSqrt[expr] - assumes variables are positive (syntactic transformation)
CombineSqrt[expr, assumptions] - mathematically rigorous with assumption checking
- Handles any fractional power x^(n/2): Sqrt[a], a^(3/2), a^(5/2), etc.
- Sqrt[a]*Sqrt[b] → Sqrt[a*b] when both a,b ≥ 0
- a^(3/2)*b^(1/2) → a*Sqrt[a*b] when both a,b ≥ 0  
- Warns about negative bases in fractional powers (complex results)
Examples: CombineSqrt[a^(3/2)*Sqrt[b], a > 0 && b > 0] gives a*Sqrt[a*b]";

CombineSqrt::unknownsigns = "Variables with unknown signs: `1`. Cannot combine square roots safely without knowing their signs.";
CombineSqrt::suggest = "Try adding assumptions like: `1`";

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
  
  (* Constants with np prefix - use word boundaries to avoid partial matches *)
  RegularExpression["\\bPi\\b"] -> "np.pi",
  RegularExpression["\\bE\\b"] -> "np.e", 
  RegularExpression["\\bI\\b"] -> "1j",
  
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

(* CombineSqrt: Combines square roots in mathematical expressions with optional assumption checking *)
CombineSqrt[expr_, assumptions_: True] := Module[{
  allSqrtArgs, unknownSignArgs, suggestedAssumptions, result
},
  
  (* First, extract all arguments under fractional powers (n/2) to check for unknown signs *)
  allSqrtArgs = Cases[expr, Power[x_, Rational[n_, 2]] /; IntegerQ[n] :> x, Infinity];
  
  (* If assumptions are provided, check which signs are unknown *)
  If[assumptions =!= True && Length[allSqrtArgs] > 0,
    (* Convert List of assumptions to logical expression if needed *)
    If[Head[assumptions] === List,
      assumptions = Apply[And, assumptions];
    ];
    
    unknownSignArgs = Select[allSqrtArgs, 
      !MemberQ[{-1, 0, 1}, Quiet[Simplify[Sign[#], assumptions]]] &
    ];
    
    (* If there are unknown signs, issue warnings *)
    If[Length[unknownSignArgs] > 0,
      Message[CombineSqrt::unknownsigns, unknownSignArgs];
      
      (* Generate suggested assumptions *)
      suggestedAssumptions = StringRiffle[
        Map[ToString[#] <> " > 0" &, unknownSignArgs], 
        " && "
      ];
      Message[CombineSqrt::suggest, suggestedAssumptions];
      
      (* Also print detailed information *)
      Print["Debugging: Unknown sign expressions found:"];
      Do[
        signResult = Quiet[Simplify[Sign[unknownSignArgs[[i]]], assumptions]];
        Print["  ", unknownSignArgs[[i]], " has sign: ", signResult];
      , {i, 1, Min[5, Length[unknownSignArgs]]}]; (* Limit to first 5 to avoid spam *)
      If[Length[unknownSignArgs] > 5,
        Print["  ... and ", Length[unknownSignArgs] - 5, " more expressions"];
      ];
    ];
  ];
  
  (* Apply transformation: combine all fractional powers a^(n/2) under one sqrt *)
  (* Simple approach: a^(n/2) * b^(m/2) = Sqrt[a^n * b^m] *)
  result = expr //.
    (HoldPattern[Times[args__]] /; (Count[{args}, Power[_, Rational[n_, 2]] /; IntegerQ[n]] >= 2) :>
      Module[{fracPowers, others, allBases, baseSigns, numNegative, signFactor},
        
        (* Extract fractional powers and other terms *)
        fracPowers = Cases[{args}, Power[base_, Rational[n_, 2]] /; IntegerQ[n] :> {base, n}];
        others = Cases[{args}, Except[Power[_, Rational[n_, 2]] /; IntegerQ[n]]];
        
        (* Convert each a^(n/2) to a^n under the sqrt: a^(n/2) -> a^n *)
        allBases = Map[#[[1]]^#[[2]] &, fracPowers];
        
        (* If no assumptions provided, use simple combination *)
        If[assumptions === True,
          (* Simple syntactic transformation: combine everything under sqrt *)
          Times @@ others * Sqrt[Times @@ allBases],
          
          (* Rigorous transformation with assumption checking *)
          baseSigns = Quiet[Simplify[Sign[#], assumptions]] & /@ Map[First, fracPowers];
          
          (* Check if any sign is indeterminate *)
          If[AnyTrue[baseSigns, !MemberQ[{-1, 0, 1}, #] &],
            (* Return unchanged to prevent transformation *)
            Inactive[Times][args],
            
            (* All signs are known, proceed with correct sign factor *)
            numNegative = Count[baseSigns, -1];
            signFactor = (-1)^Quotient[numNegative, 2];
            
            (* Assemble final result *)
            signFactor * Times @@ others * Sqrt[Times @@ allBases]
          ]
        ]
      ]) /. Inactive[Times][args_] :> Times[args];
  
  result
];

(* Set HoldFirst attribute to prevent argument evaluation *)
SetAttributes[CombineSqrt, HoldFirst];

End[]; (* `Private` *)

EndPackage[]; (* WolfPy` *)
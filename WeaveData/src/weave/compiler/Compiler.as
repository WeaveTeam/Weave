/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.compiler
{
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	
	import weave.core.ClassUtils;
	import weave.core.StageUtils;
	
	/**
	 * This class provides a static function compileToFunction() that compiles an expression String into a Function.
	 * 
	 * @author adufilie
	 */
	public class Compiler
	{
		private static var debug:Boolean = false;
		
		{ /** begin static code block **/
			initStaticObjects();
			includeLibraries(Math, MathLib, StringUtil, StringLib, BooleanLib, ArrayLib);
			
			//StageUtils.callLater(null, test);
		} /** end static code block **/
		
		/**
		 * This function compiles an expression into a Function that evaluates using variables from a symbolTable.
		 * Strings may be surrounded by quotation marks (") and literal quotation marks are escaped by two quote marks together ("").
		 * The escape sequence for a quoted variable name to indicate a quotation mark is two quotation marks together.
		 * @param expression An expression to compile.
		 * @param symbolTable This is either a function that returns a variable by name or a lookup table containing custom variables and functions that can be used in the expression.  These values may be changed after compiling.
		 * @return A Function generated from the expression String, or null if the String does not represent a valid expression.
		 */
		public static function compileToFunction(expression:String, symbolTable:Object):Function
		{
			var tokens:Array = getTokens(expression);
			//trace("source:", expression, "tokens:" + tokens.join(' '));
			var compiledObject:ICompiledObject = compileTokens(tokens, true);
			return compileObjectToFunction(compiledObject, symbolTable);
		}
		
		/**
		 * This function will compile an expression into a compiled object representing a function that takes no parameters and returns a value.
		 * This function is useful for inspecting the structure of the compiled function and decompiling individual parts.
		 * @param expression An expression to parse.
		 * @param enableOptimizations If this is true and all the compiledParameters are constants, the function will be called once and the result will be saved as a constant.
		 * @return A CompiledConstant or CompiledFunctionCall generated from the tokens, or null if the tokens do not represent a valid expression.
		 */
		public static function compileToObject(expression:String, enableOptimizations:Boolean = false):ICompiledObject
		{
			return compileTokens(getTokens(expression), enableOptimizations);
		}
		
		/*
			Escape Sequence     Character Represented
			\b                  backspace character (ASCII 8)
			\f                  form-feed character (ASCII 12)
			\n                  line-feed character (ASCII 10)
			\r                  carriage return character (ASCII 13)
			\t                  tab character (ASCII 9)
			\"                  double quotation mark
			\'                  single quotation mark
			\\                  backslash
			\000 .. \377        a byte specified in octal
			\x00 .. \xFF        a byte specified in hexadecimal
			\u0000 .. \uFFFF    a 16-bit Unicode character specified in hexadecimal
		*/
		private static const ENCODE_LOOKUP:Object = {'\b':'b', '\f':'f', '\n':'n', '\r':'r', '\t':'t', '\\':'\\'};
		private static const DECODE_LOOKUP:Object = {'b':'\b', 'f':'\f', 'n':'\n', 'r':'\r', 't':'\t'};
		
		/**
		 * This function surrounds a String with quotes and escapes special characters using ActionScript string literal format.
		 * @param string A String that may contain special characters.
		 * @param useDoubleQuotes If this is true, double-quote will be used.  If false, single-quote will be used.
		 * @return The given String formatted for ActionScript.
		 */
		public static function encodeString(string:String, doubleQuote:Boolean = true):String
		{
			var quote:String = doubleQuote ? '"' : "'";
			var result:Array = new Array(string.length);
			for (var i:int = 0; i < string.length; i++)
			{
				var chr:String = string.charAt(i);
				var esc:String = chr == quote ? quote : ENCODE_LOOKUP[chr];
				result[i] = esc ? '\\' + esc : chr;
			}
			return quote + result.join("") + quote;
		}
		
		/**
		 * This function is for internal use only.  It assumes the string it receives is valid.
		 * @param encodedString A quoted String with special characters escaped using ActionScript string literal format.
		 * @return The unescaped literal string.
		 */
		private static function decodeString(encodedString:String):String
		{
			// remove quotes
			var quote:String = encodedString.charAt(0);
			var input:String = encodedString.substr(1, encodedString.length - 2);
			input = input.split(quote + quote).join(quote); // handle doubled quote escape sequences
			var output:String = "";
			var begin:int = 0;
			while (true)
			{
				var esc:int = input.indexOf("\\", begin);
				if (esc < 0)
				{
					output += input.substring(begin);
					break;
				}
				else
				{
					// look up escaped character
					var c:String = input.charAt(esc + 1);
					
					//TODO: octal and hex escape sequences
					
					c = DECODE_LOOKUP[c] || c;
					output += input.substring(begin, esc) + c;
					// skip over escape sequence
					begin = esc + 2;
				}
			}
			return output;
		}
		
		/**
		 * This function will include additional libraries to be supported by the compiler when compiling functions.
		 * @param classesOrObjects An Array of Class definitions or objects containing functions to be supported by the compiler.
		 */		
		public static function includeLibraries(...classesOrObjects):void
		{
			for (var i:int = 0; i < classesOrObjects.length; i++)
			{
				var library:Object = classesOrObjects[i];
				// only add this library to the list if it is not already added.
				if (library != null && libraries.indexOf(library) < 0)
				{
					libraries.push(library);
					
					var classInfo:XML = describeType(library);
					for each (var constantName:String in classInfo.child("constant").attribute("name"))
						constants[constantName] = library[constantName];
					for each (var methodName:String in classInfo.child("method").attribute("name"))
						functions[methodName] = library[methodName];
				}
			}
		}
		
		/**
		 * This function will add a variable to the constants available in expressions.
		 * @param constantName The name of the constant.
		 * @param constantValue The value of the constant.
		 */		
		public static function includeConstant(constantName:String, constantValue:*):void
		{
			constants[constantName] = constantValue;
		}

		/**
		 * This function gets a list of all the libraries currently being used by the compiler.
		 * @return A new Array containing a list of all the objects and/or classes used as libraries in the compiler.
		 */		
		public static function getAllLibraries():Array
		{
			return libraries.concat(); // make a copy
		}
		
		/**
		 * This is a list of objects and/or classes containing functions and constants supported by the compiler.
		 */
		private static const libraries:Array = [];
		
		/**
		 * This is the prefix used for the function notation of infix operators.
		 * For example, the function notation for ( x + y ) is ( operator+(x,y) ).
		 */
		public static const OPERATOR_PREFIX:String = 'operator';
		
		/**
		 * This is a String containing all the characters that are treated as whitespace.
		 */
		private static const WHITESPACE:String = '\r\n \t';
		/**
		 * This is the maximum allowed length of an operator.
		 */		
		private static const MAX_OPERATOR_LENGTH:int = 3;
		/**
		 * This object maps the name of a predefined constant to its value.
		 */
		private static var constants:Object = null;
		/**
		 * This object maps a function name to its Function definition.
		 */
		private static var functions:Object = null;
		/**
		 * This object maps an operator like "*" to a Function with the following signature:
		 *     function(x:Number, y:Number):Number
		 * If there is no function associated with the operator, it maps the operator to a value of null.
		 */
		private static var operators:Object = null;
		/**
		 * This object maps a unary operator like "-" to a Function that takes one parameter.
		 */
		private static var unaryOperators:Object = null;
		/**
		 * This is a two-dimensional Array of operator symbols arranged in the order they should be evaluated.
		 * Each nested Array is a group of operators that should be evaluated in the same pass.
		 */
		private static var orderedOperators:Array = null;
		/**
		 * This is an Array of all the unary operator symbols.
		 */
		private static var unaryOperatorSymbols:Array = null;
		/**
		 * This object maps a function name to a value of true if the function is impure, meaning if
		 * it is called more than once with the same arguments, it may produce different results.
		 * The compiler checks this object to determine which function calls it cannot simplify to a constant.
		 * An example of an impure function is Math.random().
		 */
		private static var impureFunctions:Object = null;
		/**
		 * This function will initialize the operators, constants, and functions.
		 */
		private static function initStaticObjects():void
		{
			functions = new Object();
			constants = new Object();
			operators = new Object();
			unaryOperators = new Object();
			impureFunctions = new Object();
			
			// add built-in functions
			functions['iif'] = function(c:*, t:*, f:*):* { return c ? t : f; };
			functions['isNaN'] = isNaN;
			functions['isFinite'] = isFinite;
			functions['typeof'] = function(value:*):* { return typeof(value); };
			functions['Number'] = MathLib.toNumber;
			functions['String'] = StringLib.toString;
			functions['Boolean'] = BooleanLib.toBoolean;
			functions['Array'] = function(...values):Array { return values; };
			functions['Class'] = function(value:*):Class
			{
				if (value is Class)
					return value;
				if (!(value is String))
					value = getQualifiedClassName(value);
				if (value is String)
				{
					var domain:ApplicationDomain = ApplicationDomain.currentDomain;
					if (domain.hasDefinition(value))
						return domain.getDefinition(value) as Class;
				}
				return null;
			}
			functions['trace'] = function(...args):void
			{
				// for trace debugging, debug must be set to true
				if (debug)
					trace.apply(null, args);
			};
			
			// Save names of impure functions so the compiler will not reduce them to constants when all their parameters are constants.
			impureFunctions['random'] = true;
			impureFunctions['trace'] = true;
			
			// add constants so parser will not treat them as variable names
			constants["undefined"] = undefined;
			constants["null"] = null;
			constants["NaN"] = NaN;
			constants["true"] = true;
			constants["false"] = false;
			constants["Infinity"] = Infinity;

			/** operators **/
			// access
			//operators["."] = true;
			// grouping
			operators["("] = true;
			operators[")"] = true;
			operators[","] = true;
			// math
			operators["**"] = Math.pow;
			operators["*"] = function(x:*, y:*):Number { return x * y; };
			operators["/"] = function(x:*, y:*):Number { return x / y; };
			operators["%"] = function(x:*, y:*):Number { return x % y; };
			operators["+"] = function(x:*, y:*):* { return x + y; }; // also works for strings
			operators["-"] = function(...args):Number { return args.length == 1 ? -args[0] : args[0] - args[1]; }; // works as unary or infix operator
			// bitwise
			operators["~"] = function(x:*):* { return ~x; };
			operators["&"] = function(x:*, y:*):* { return x & y; };
			operators["|"] = function(x:*, y:*):* { return x | y; };
			operators["^"] = function(x:*, y:*):* { return x ^ y; };
			operators["<<"] = function(x:*, y:*):* { return x << y; };
			operators[">>"] = function(x:*, y:*):* { return x >> y; };
			operators[">>>"] = function(x:*, y:*):* { return x >>> y; };
			// comparison
			operators["<"] = function(x:*, y:*):Boolean { return x < y; };
			operators["<="] = function(x:*, y:*):Boolean { return x <= y; };
			operators[">"] = function(x:*, y:*):Boolean { return x > y; };
			operators[">="] = function(x:*, y:*):Boolean { return x >= y; };
			operators["=="] = function(x:*, y:*):Boolean { return x == y; };
			operators["==="] = function(x:*, y:*):Boolean { return x === y; };
			operators["!="] = function(x:*, y:*):Boolean { return x != y; };
			operators["!=="] = function(x:*, y:*):Boolean { return x !== y; };
			// boolean
			operators["!"] = function(x:*):Boolean { return !x; };
			operators["&&"] = function(x:*, y:*):* { return x && y; };
			operators["||"] = function(x:*, y:*):* { return x || y; };
			// branching
			operators["?"] = true;
			operators[":"] = true;
			operators["?:"] = functions['iif'];
			// assignment
			//operators["="] = true; 

			// unary operators
			unaryOperators['-'] = function(x:*):Number { return -x; };
			unaryOperators['!'] = operators['!'];
			unaryOperators['~'] = operators['~'];
			
			// evaluate operators in the same order as ActionScript
			orderedOperators = [
				['*','/','%'],
				['+','-'],
				['<<','>>','>>>'],
				['<','<=','>','>='],
				['==','!=','===','!=='],
				['&'],
				['^'],
				['|'],
				['&&'],
				['||']
			];
			unaryOperatorSymbols = ['-','~','!'];

			// create a corresponding function name for each operator
			for (var op:String in operators)
				if (operators[op] is Function)
					functions[OPERATOR_PREFIX + op] = operators[op];
		}

		/**
		 * @param expression An expression string to parse.
		 * @return An Array containing all the tokens found in the expression.
		 */
		private static function getTokens(expression:String):Array
		{
			var tokens:Array = [];
			var n:int = expression.length;
			// get a flat list of tokens
			var i:int = 0;
			while (i < n)
			{
				var token:String = getToken(expression, i);
				if (WHITESPACE.indexOf(token.charAt(0)) == -1)
					tokens.push(token);
				i += token.length;
			}
			return tokens;
		}
		/**
		 * This function is for internal use only.
		 * @param expression An expression to parse.
		 * @param index The starting index of the token.
		 * @return The token beginning at the specified index.
		 */
		private static function getToken(expression:String, index:int):String
		{
			var endIndex:int;
			var n:int = expression.length;
			var c:String = expression.charAt(index);
			
			// this function assumes operators has already been initialized

			// handle operators (find the longest matching operator)
			endIndex = index;
			while (endIndex < n && operators[ expression.substring(index, endIndex + 1) ] != undefined)
				endIndex++;
			if (index < endIndex)
				return expression.substring(index, endIndex);
			
			// handle whitespace (find the longest matching sequence)
			endIndex = index;
			while (endIndex < n && WHITESPACE.indexOf(expression.charAt(endIndex)) >= 0)
				endIndex++;
			if (index < endIndex)
				return expression.substring(index, endIndex);
			
			// handle quoted string
			if (c == '"' || c == "'")
			{
				var quote:String = c;
				// index points to the opening quote
				// make endIndex point to the matching end quote
				for (endIndex = index + 1; endIndex < n; endIndex++)
				{
					c = expression.charAt(endIndex);
					// stop when matching quote found, unless there are two together for an escape sequence
					if (c == quote)
					{
						if (endIndex < n - 1 && expression.charAt(endIndex + 1) == quote)
							endIndex++; // skip second quote
						else
							break;
					}
					
					// TODO: handle octal and hex escape sequences

					// handle remaining escape sequences
					if (c == '\\')
						endIndex++;
				}
				// Note: If the last character is '\\', endIndex will be n+1.  The final '\\' will be removed when decoding the string
				// if ending quote was not found, append it now
				if (endIndex == n)
					expression += quote;
				// return the quoted string, including the quotes
				return expression.substring(index, endIndex + 1);
			}
			// handle everything else (go until a special character is found)
			for (endIndex = index + 1; endIndex < n; endIndex++)
			{
				c = expression.charAt(endIndex);
				// whitespace or quotes terminates a token
				if (WHITESPACE.indexOf(c) >= 0 || c == '"')
					break;
				// operator terminates a token
				if (operators[c] != undefined)
				{
					// special case: "operator" followed by an operator symbol is treated as a single token
					if (expression.substring(index, endIndex) == OPERATOR_PREFIX)
					{
						for (var operatorLength:int = MAX_OPERATOR_LENGTH; operatorLength > 0; operatorLength--)
						{
							if (functions[expression.substring(index, endIndex + operatorLength)] is Function)
							{
								endIndex += operatorLength;
								break;
							}
						}
					}
					break;
				}
			}
			return expression.substring(index, endIndex);
		}

		/**
		 * This function will recursively compile a set of tokens into a compiled object representing a function that takes no parameters and returns a value.
		 * Example set of input tokens:  pow ( - ( - 2 + 1 ) ** - 4 , 3 ) - ( 4 + - 1 )
		 * @param tokens An Array of tokens for an expression.  This array will be modified in place.
		 * @param enableOptimizations If this is true and all the compiledParameters are constants, the function will be called once and the result will be saved as a constant.
		 * @return A CompiledConstant or CompiledFunctionCall generated from the tokens, or null if the tokens do not represent a valid expression.
		 */
		private static function compileTokens(tokens:Array, enableOptimizations:Boolean):ICompiledObject
		{
			var i:int;
			var subArray:Array;
			var compiledParams:Array;
			
			// step 0: compile quoted Strings and Numbers
			for (i = 0; i < tokens.length; i++)
			{
				var str:String = tokens[i] as String;
				if (!str)
					continue;
				
				// if the token starts with a quote, treat it as a String
				var quote:String = str.charAt(0);
				if (quote == '"' || quote == "'")
				{
					str = decodeString(str);
					tokens[i] = new CompiledConstant(encodeString(str, quote == '"'), str);
				}
				else
				{
					// attempt to evaluate the token as a Number
					try {
						var number:Number = Number(str);
						if (!isNaN(number))
							tokens[i] = new CompiledConstant(str, number);
					} catch (e:Error) { }
				}
			}

			// step 1: group tokens by parentheses and compile function calls
			while (true)
			{
				// find first ')' and work backwards to a '('
				var open:int;
				var close:int = tokens.indexOf(')');
				for (open = close - 1; open >= 0; open--)
					if (tokens[open] == '(')
						break;
				if (open < 0)
					break;
				if (open < close)
				{
					// cut out tokens between '(' and ')'
					subArray = tokens.splice(open + 1, close - open - 1);
					
					// if there is a non-operator token to the left, treat this as a function call.
					if (open > 0 && operators[tokens[open - 1]] == undefined)
					{
						var funcToken:Object = tokens[open - 1];
						var compiledMethod:ICompiledObject = funcToken as ICompiledObject;
						if (!compiledMethod)
						{
							// The function token hasn't been compiled yet.
							// Check the function table first and fall back to a variable lookup.
							if (functions[funcToken] != undefined)
								compiledMethod = new CompiledConstant(funcToken as String, functions[funcToken]);
							else
								compiledMethod = compileVariable(funcToken as String);
						}
						
						if (debug)
							trace("compiling function call", decompileObject(compiledMethod) + "(", subArray.join(' '), ")");
						
						// group tokens between commas and compile the function
						compiledParams = [];
						// special case for zero parameters: if subArray is empty, avoid compiling an empty set of tokens
						if (subArray.length > 0)
						{
							while (true)
							{
								var comma:int = subArray.indexOf(',');
								if (comma >= 0)
								{
									// compile the tokens before the comma as a parameter
									compiledParams.push(compileTokens(subArray.splice(0, comma), enableOptimizations));
									subArray.shift(); // remove comma
								}
								else
								{
									// compile remaining group of tokens as a parameter
									compiledParams.push(compileTokens(subArray, enableOptimizations));
									break;
								}
							}
						}
						// replace the function token, '(', and ')' tokens with a compiled function call
						tokens.splice(open - 1, 3, compileFunctionCall(compiledMethod, compiledParams, enableOptimizations));
					}
					else // These parentheses do not correspond to a function call.
					{
						if (debug)
							trace("compiling tokens (", subArray.join(' '), ")");
						// Replace the '(' and ')' tokens with the result of compiling subArray
						tokens.splice(open, 2, compileTokens(subArray, enableOptimizations));
					}
				}
				else
					throw new Error("Missing ')'");
			}
			// return null if there are extra ',' or ')' tokens
			if (tokens.indexOf(',') >= 0)
				throw new Error("Misplaced ',' in "+tokens.join(' '));
			if (tokens.indexOf(')') >= 0)
				throw new Error("Misplaced ')'");

			// -------------------

			// there are no more parentheses, so the remaining tokens are operators, constants, and variable names.
			if (debug)
				trace("compiling tokens", tokens.join(' '));
			
			// step 2: handle infix '.'
			// TODO
			
			// step 3: compile constants and variable names
			for (i = 0; i < tokens.length; i++)
			{
				var token:String = tokens[i] as String;
				// skip tokens that have already been compiled and skip operator tokens
				if (token == null || operators[token] != undefined)
					continue;
				// evaluate constants
				if (constants[token] != undefined)
				{
					tokens[i] = new CompiledConstant(token, constants[token]);
					continue;
				}
				// treat everything else as a variable name.
				// make a copy of the variable name that is safe for the wrapper function to use
				// compile the token as a call to variableGetter.
				tokens[i] = compileVariable(token);
			}
			
			// step 4: compile '**' infix operators
			compileInfixOperators(tokens, ['**'], enableOptimizations);
			
			// step 5: compile unary operators
			compileUnaryOperators(tokens, unaryOperatorSymbols, enableOptimizations);
			
			// step 6: compile remaining infix operators in order
			for (i = 0; i < orderedOperators.length; i++)
				compileInfixOperators(tokens, orderedOperators[i], enableOptimizations);
			
			// step 7: compile conditional branches
			while (true)
			{
				// true branch includes everything between the last '?' and the next ':'
				var left:int = tokens.lastIndexOf('?');
				var right:int = tokens.indexOf(':', left);
				
				// stop if operator missing or any section has no tokens
				if (right < 0 || left < 1 || left + 1 == right || right + 1 == tokens.length)
					break;
				
				if (debug)
					trace("compiling conditional branch:", tokens.slice(left - 1, right + 2).join(' '));
				var condition:ICompiledObject = compileTokens(tokens.slice(left - 1, left), enableOptimizations);
				var trueBranch:ICompiledObject = compileTokens(tokens.slice(left + 1, right), enableOptimizations);
				var falseBranch:ICompiledObject = compileTokens(tokens.slice(right + 1, right + 2), enableOptimizations);
				
				// optimization: eliminate unnecessary branch
				var result:ICompiledObject;
				if (enableOptimizations && condition is CompiledConstant)
					result = (condition as CompiledConstant).value ? trueBranch : falseBranch;
				else
					result = compileFunctionCall(new CompiledConstant(OPERATOR_PREFIX + '?:', operators['?:']), [condition, trueBranch, falseBranch], enableOptimizations);
				
				tokens.splice(left - 1, right - left + 3, result);
			}
			// stop if any branch operators remain
			if (Math.max(tokens.indexOf('?'), tokens.indexOf(':')) >= 0)
				throw new Error('Invalid conditional branch');
			
			// step 8: compile the last token
			// there should be only a single token left
			if (tokens.length == 1)
				return tokens[0];

			if (tokens.length > 1)
			{
				var leftToken:String = tokens[0] is ICompiledObject ? decompileObject(tokens[0]) : tokens[0];
				var rightToken:String = tokens[1] is ICompiledObject ? decompileObject(tokens[1]) : tokens[1];
				throw new Error("Missing operator between " + leftToken + ' and ' + rightToken);
			}

			throw new Error("Empty expression");
		}

		/**
		 * This function is for internal use only.
		 * This function ensures that mathFunction and evaluatedParams are new Flash variables for each wrapper function created.
		 * This returns a Function with the signature:  function():*
		 * @param compiledMethod A compiled object that evaluates to a Function.
		 * @param compiledParams An array of compiled parameters that will be evaluated when the wrapper function is called.
		 * @param enableOptimizations If this is true and all the compiledParameters are constants, the function will be called once and the result will be saved as a constant.
		 * @return A CompiledObject that contains either a constant or a wrapper function that runs the functionToCompile after evaluating the compiledParams.
		 */
		private static function compileFunctionCall(compiledMethod:ICompiledObject, compiledParams:Array, enableOptimizations:Boolean):ICompiledObject
		{
			var compiledFunctionCall:CompiledFunctionCall = new CompiledFunctionCall(compiledMethod, compiledParams);
			// if the compiled function call should not be evaluated to a constant, return it now.
			// impure functions cannot be evaluated to constants because by definition they may return different results on the same input.
			var constantMethod:CompiledConstant = compiledMethod as CompiledConstant;
			if (!enableOptimizations || !constantMethod || impureFunctions[constantMethod.name] != undefined)
				return compiledFunctionCall;
			// check for CompiledFunctionCall objects in the compiled parameters
			for each (var param:ICompiledObject in compiledParams)
				if (!(param is CompiledConstant))
					return compiledFunctionCall; // this compiled funciton call cannot be evaluated to a constant
			// if there are no CompiledFunctionCall objects in the compiled parameters, evaluate the compiled function call to a constant.
			var callWrapper:Function = compileObjectToFunction(compiledFunctionCall, null); // no symbol table required for evaluating a constant
			return new CompiledConstant(decompileObject(compiledFunctionCall), callWrapper());
		}

		/**
		 * This function is for internal use only.
		 * This function is necessary because variableName needs to be a new Flash variable each time a wrapper function is created.
		 * @param variableName The name of the variable to get when the resulting wrapper function is evaluated.
		 * @param A CompiledFunctionCall for getting the variable.
		 */
		private static function compileVariable(variableName:String):CompiledFunctionCall
		{
			return new CompiledFunctionCall(new CompiledConstant(variableName, variableName), null); // params are null as a special case
		}
		
		/**
		 * This function is for internal use only.
		 * This will compile unary operators of the given type from right to left.
		 * @param compiledTokens An Array of compiled tokens for an expression.  No '(' ')' or ',' tokens should appear in this Array.
		 * @param operatorSymbols An Array containing all the infix operator symbols to compile.
		 * @param enableOptimizations When this is true, function calls will be simplified to constants where possible.
		 */
		private static function compileUnaryOperators(compiledTokens:Array, operatorSymbols:Array, enableOptimizations:Boolean):void
		{
			var index:int;
			for (index = compiledTokens.length - 1; index >= 0; index--)
			{
				// skip tokens that are not unary operators
				if (operatorSymbols.indexOf(compiledTokens[index]) < 0)
					continue;
				
				// fail when next token is not a compiled object
				if (index + 1 == compiledTokens.length || compiledTokens[index + 1] is String)
					throw new Error("Misplaced unary operator '" + compiledTokens[index] + "'");
				
				// skip infix operator
				if (index > 0 && compiledTokens[index - 1] is ICompiledObject)
					continue;
				
				// compile unary operator
				if (debug)
					trace("compile unary operator", compiledTokens.slice(index, index + 2).join(' '));
				var operatorName:String = compiledTokens[index]; // no 'operator' prefix
				var compiledMethod:CompiledConstant = new CompiledConstant(operatorName, unaryOperators[operatorName]);
				var compiledParams:Array = [compiledTokens[index + 1]];
				compiledTokens.splice(index, 2, compileFunctionCall(compiledMethod, compiledParams, enableOptimizations));
			}
		}
		
		/**
		 * This function is for internal use only.
		 * This will compile infix operators of the given type from left to right.
		 * @param compiledTokens An Array of compiled tokens for an expression.  No '(' ')' or ',' tokens should appear in this Array.
		 * @param operatorSymbols An Array containing all the infix operator symbols to compile.
		 * @param enableOptimizations When this is true, function calls will be simplified to constants where possible.
		 */
		private static function compileInfixOperators(compiledTokens:Array, operatorSymbols:Array, enableOptimizations:Boolean):void
		{
			var index:int = 0;
			while (index < compiledTokens.length)
			{
				// skip tokens that are not infix operators
				if (operatorSymbols.indexOf(compiledTokens[index]) < 0)
				{
					index++;
					continue;
				}
				
				// special case code for infix operators ('**') that are evaluated prior to unary operators
				var right:int = index + 1;
				// find the next ICompiledObject
				while (right < compiledTokens.length && compiledTokens[right] is String)
					right++;
				// if there were String tokens, we need to compile unary operators on the right-hand-side
				if (right > index + 1)
				{
					// extract the right-hand-side, compile unary operators, and then insert the result to the right of the infix operator
					var rhs:Array = compiledTokens.splice(index + 1, right - index);
					compileUnaryOperators(rhs, unaryOperatorSymbols, enableOptimizations);
					if (rhs.length != 1)
						throw new Error("Unable to parse second parameter of infix operator '" + compiledTokens[index] + "'");
					compiledTokens.splice(index + 1, 0, rhs[0]);
				}
				
				// stop if infix operator does not have compiled objects on either side
				if (index == 0 || index + 1 == compiledTokens.length || compiledTokens[index - 1] is String || compiledTokens[index + 1] is String)
					throw new Error("Misplaced infix operator '" + compiledTokens[index] + "'");
				
				// compile a wrapper for the operator call
				var operatorName:String = OPERATOR_PREFIX + compiledTokens[index];
				var compiledMethod:CompiledConstant = new CompiledConstant(operatorName, functions[operatorName]);
				var compiledParams:Array = [compiledTokens[index - 1], compiledTokens[index + 1]];
				// replace the tokens for this infix operator call with the compiled operator call
				if (debug)
					trace("compile infix operator", compiledTokens.slice(index - 1, index + 2).join(' '));
				compiledTokens.splice(index - 1, 3, compileFunctionCall(compiledMethod, compiledParams, enableOptimizations));
			}
		}

		/**
		 * @param compiledObject A CompiledFunctionCall or CompiledConstant to decompile into an expression String.
		 * @return The expression String generated from the compiledObject.
		 */
		public static function decompileObject(compiledObject:ICompiledObject):String
		{
			if (compiledObject is CompiledConstant)
				return (compiledObject as CompiledConstant).name;
			
			if (debug)
				trace("decompiling: " + ObjectUtil.toString(compiledObject));
			
			var call:CompiledFunctionCall = compiledObject as CompiledFunctionCall;

			// decompile the function name
			var name:String = decompileObject(call.compiledMethod);
			
			// special case for variable lookup
			if (call.compiledParams == null)
				return name;
			
			// decompile each paramter
			var params:Array = [];
			for (var i:int = 0; i < call.compiledParams.length; i++)
				params[i] = decompileObject(call.compiledParams[i]);
			
			// replace infix operator function calls with the preferred infix syntax
			if (name.indexOf(OPERATOR_PREFIX) == 0)
			{
				var op:String = name.substr(OPERATOR_PREFIX.length);
				if (call.compiledParams.length == 1)
					return op + params[0];
				if (call.compiledParams.length == 2)
					return StringUtil.substitute("({0} {1} {2})", params[0], op, params[1]);
				if (call.compiledParams.length == 3 && op == '?:')
					return StringUtil.substitute("({0} ? {1} : {2})", params);
			}
			
			return name + '(' + params.join(', ') + ')';
		}
		
		/**
		 * This function is for internal use only.
		 * @param compiledObject Either a CompiledConstant or a CompiledFunctionCall.
		 * @param symbolTable This is either a function that returns a variable by name or a lookup table containing custom variables and functions that can be used in the expression.  These values may be changed after compiling.
		 * @return A Function that takes no parameters and returns the result of evaluating the ICompiledObject.
		 */
		public static function compileObjectToFunction(compiledObject:ICompiledObject, symbolTable:Object):Function
		{
			if (compiledObject == null)
				return null;
			
			if (symbolTable == null)
				symbolTable = {};
			
			if (compiledObject is CompiledConstant)
			{
				// create a new variable for the value to avoid the overhead of
				// accessing a member variable of the CompiledConstant object.
				const value:* = (compiledObject as CompiledConstant).value;
				return function():* { return value; };
			}
			
			// create the variables that will be used inside the wrapper function
			const METHOD_INDEX:int = -1;
			const CONDITION_INDEX:int = 0;
			const TRUE_INDEX:int = 1;
			const FALSE_INDEX:int = 2;
			const BRANCH_LOOKUP:Dictionary = new Dictionary();
			BRANCH_LOOKUP[functions[OPERATOR_PREFIX + '?:']] = true;
			BRANCH_LOOKUP[functions[OPERATOR_PREFIX + '&&']] = true;
			BRANCH_LOOKUP[functions[OPERATOR_PREFIX + '||']] = false;

			const stack:Array = []; // used as a queue of function calls
			var call:CompiledFunctionCall;
			var subCall:CompiledFunctionCall;
			var compiledParams:Array;
			var result:*;
			var defaultSymbolTable:Object = {};

			// return the wrapper function
			// this function avoids unnecessary function calls by keeping its own call stack rather than using recursion.
			return function(...args):*
			{
				defaultSymbolTable['this'] = this;
				defaultSymbolTable['arguments'] = args;
				// initialize top-level function and push it onto the stack
				call = compiledObject as CompiledFunctionCall;
				call.evalIndex = METHOD_INDEX;
				stack.length = 1;
				stack[0] = call;
				while (true)
				{
					// evaluate the CompiledFunctionCall on top of the stack
					call = stack[stack.length - 1] as CompiledFunctionCall;
					compiledParams = call.compiledParams;
					if (compiledParams)
					{
						// check which parameters should be evaluated
						for (; call.evalIndex < compiledParams.length; call.evalIndex++)
						{
							//trace(StringLib.lpad('', stack.length, '\t') + "[" + call.evalIndex + "] " + compiledParams[call.evalIndex].name);
							
							// handle branching and short-circuiting
							result = BRANCH_LOOKUP[call.evaluatedMethod];
							if (result !== undefined && call.evalIndex > CONDITION_INDEX)
								if (result == (call.evalIndex != (call.evaluatedParams[CONDITION_INDEX] ? TRUE_INDEX : FALSE_INDEX)))
									continue;
							
							if (call.evalIndex == METHOD_INDEX)
								subCall = call.compiledMethod as CompiledFunctionCall;
							else
								subCall = compiledParams[call.evalIndex] as CompiledFunctionCall;
							
							if (subCall != null)
							{
								// initialize subCall and push onto stack
								subCall.evalIndex = METHOD_INDEX;
								stack.push(subCall);
								break;
							}
						}
						// if more parameters need to be evaluated, evaluate the new top of the stack
						if (call.evalIndex < compiledParams.length)
							continue;
					}
					// no parameters need to be evaluated, so make the function call now
					try
					{
						if (compiledParams)
						{
							// function call
							result = call.evaluatedMethod.apply(null, call.evaluatedParams);
						}
						else
						{
							// variable lookup -- call.compiledMethod is a constant and call.evaluatedMethod is the method name
							result = symbolTable is Function ? symbolTable(call.evaluatedMethod) : symbolTable[call.evaluatedMethod];
							if (result === undefined)
								result = functions[call.evaluatedMethod] || defaultSymbolTable[call.evaluatedMethod];
						}
					}
					catch (e:Error)
					{
						if (debug) // TODO: add option to throw errors or not
						{
							if (compiledParams && call.evaluatedMethod == null)
							{
								while (call.compiledMethod is CompiledFunctionCall && call.evaluatedMethod == null)
									call = call.compiledMethod as CompiledFunctionCall;
								throw new Error("Undefined method: " + call.evaluatedMethod || (call.compiledMethod as CompiledConstant).value);
							}
							throw e;
						}
						result = undefined;
					}
					// remove this call from the stack
					stack.pop();
					// if there is no parent function call, return the result
					if (stack.length == 0)
						return result;
					// otherwise, store the result in the evaluatedParams array of the parent call
					call = stack[stack.length - 1] as CompiledFunctionCall;
					if (call.evalIndex == METHOD_INDEX)
						call.evaluatedMethod = result;
					else
						call.evaluatedParams[call.evalIndex] = result;
					// advance the evalIndex so the next parameter will be evaluated.
					call.evalIndex++;
				}
				return null; // unreachable
			};
		}
		
		//-----------------------------------------------------------------
		private static function test():void
		{
			var eqs:Array = [
				"1 + '\"abc ' + \"'x\\\"y\\\\\\'z\"",
				'0 ? trace("?: BUG") : -var',
				'1 ? ~-~-var : trace("?: BUG")',
				'!true && trace("&& BUG")',
				'true || trace("|| BUG")',
				'round(.5 - random() < 0 ? "1.6" : "1.4")',
				'(- x * 3) / get("var") + -2 + pow(5,3) +operator**(6,3)',
				'operator+ ( - ( - 2 + 1 ) ** - 4 , - 3 ) - ( - 4 + - 1 * - 7 )',
				'-var---3+var2',
				'(x + var) / operator+ ( - ( 2 + 1 ) ** 4 , 3 ) - ( 4 + 1 )',
				'3',
				'-3',
				'var',
				'-var',
				'roundSignificant(random(),3)',
				'rpad("hello", 4+(var+2)*2, "._,")',
				'lpad("hello", 4+(var+2)*2, "._,")',
				'substr("hello world", var*2, 5)',
				'strlen(random())',
				'concat("(0x", upper(toBase(0xFF00FF,16)), ") ", lpad(toBase(var*20, 2, 4), 9), ", base10: ", rpad(toBase(sign(var) * (var+10),10,3), 6), ", base16: ", toBase(var+10,16))'
			];
			var values:Array = [-2, -1, -0.5, 0, 0.5, 1, 2];
			var vars:Object = {};
			vars['var'] = 123;
			vars['var2'] = 222;
			vars['x'] = 10;
			vars['get'] = function(name:String):*
			{
				//trace("get variable", name, "=", vars[name]);
				return vars[name];
			};
			
			var prevDebug:Boolean = debug;
			debug = true;
			
			for each (var eq:String in eqs)
			{
				trace("expression: "+eq);
				
				var tokens:Array = getTokens(eq);
				trace("    tokens:", tokens.join(' '));
				var decompiled:String = decompileObject(compileTokens(tokens, false));
				trace("decompiled:", decompiled);
				
				var tokens2:Array = getTokens(decompiled);
				trace("   tokens2:", tokens2.join(' '));
				var recompiled:String = decompileObject(compileTokens(tokens2, false));
				trace("recompiled:", recompiled);

				var tokens3:Array = getTokens(recompiled);
				var optimized:String = decompileObject(compileTokens(tokens3, true));
				trace(" optimized:", optimized);
				
				var f:Function = compileToFunction(eq, vars);
				for each (var value:* in values)
				{
					vars['var'] = value;
					trace("f(var="+value+")\t= " + f(value));
				}
			}
			
			debug = prevDebug;
		}
	}
}

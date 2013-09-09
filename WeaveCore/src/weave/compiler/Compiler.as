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
	import avmplus.DescribeType;
	
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.StringUtil;
	
	import weave.utils.fixErrorMessage;
	
	/**
	 * This class can compile simple ActionScript expressions into functions.
	 * 
	 * @author adufilie
	 */
	public class Compiler
	{
		public function Compiler(includeDefaultLibraries:Boolean = true)
		{
			initialize();
			if (includeDefaultLibraries)
				includeLibraries(Math, StringUtil, StandardLib, Dictionary);
		}
		
		/**
		 * Set this to true to enable trace statements for debugging.
		 */
		public var debug:Boolean = false;
		
		private static const INDEX_METHOD:int = -1;
		private static const INDEX_CONDITION:int = 0;
		private static const INDEX_TRUE:int = 1;
		private static const INDEX_FALSE:int = 2;
		
		private static const INDEX_FOR_LIST:int = 0;
		private static const INDEX_FOR_ITEM:int = 1;

		private static const ST_IF:String = 'if';
		private static const ST_ELSE:String = 'else';
		
		private static const ST_FOR:String = 'for';
		private static const ST_EACH:String = 'each';
		
		private static const ST_DO:String = 'do';
		private static const ST_WHILE:String = 'while';
		
		private static const ST_SWITCH:String = 'switch';
		private static const ST_CASE:String = 'case';
		private static const ST_DEFAULT:String = 'default';
		
		private static const ST_TRY:String = 'try';
		private static const ST_CATCH:String = 'catch';
		private static const ST_FINALLY:String = 'finally';
		
		private static const ST_BREAK:String = 'break';
		private static const ST_CONTINUE:String = 'continue';
		
		private static const ST_VAR:String = 'var';
		private static const ST_RETURN:String = 'return';
		private static const ST_THROW:String = 'throw';
		private static const ST_IMPORT:String = 'import';
		
		private static const _statementsWithoutParams:Array = [
			ST_ELSE, ST_DO, ST_BREAK, ST_CONTINUE, ST_CASE, ST_DEFAULT,
			ST_TRY, ST_FINALLY, ST_RETURN, ST_THROW, ST_VAR, ST_IMPORT
		];
		private static const _statementsWithParams:Array = [
			ST_IF, ST_FOR, ST_EACH, ST_FOR_EACH, ST_WHILE, ST_SWITCH, ST_CATCH
		];
		
		/**
		 * Used during compiling only.
		 */		
		private static const _jumpStatements:Array = [ST_BREAK, ST_CONTINUE, ST_RETURN, ST_THROW];
		
		/**
		 * Only used during evaluation and decompiling.
		 */
		private static const ST_FOR_DO:String = 'for do';
		
		/**
		 * Only used during evaluation and decompiling.
		 */
		private static const ST_FOR_IN:String = 'for in';
		
		/**
		 * Used as a single token for simplicity.
		 */
		private static const ST_FOR_EACH:String = 'for each';
		
		/**
		 * must be enclosed in () with expressions separated by ;
		 * Used in conjunction with _validStatementPatterns.
		 */
		private static const PN_PARAMS:String = 'PARAMS';
		
		/**
		 * MUST be a {} code block.
		 * Used in conjunction with _validStatementPatterns.
		 */
		private static const PN_BLOCK:String = 'BLOCK';
		
		/**
		 * may contain either a single statement or a {} code block.
		 * Used in conjunction with _validStatementPatterns.
		 */
		private static const PN_STMT:String = 'STMT';
		
		/**
		 * may only contain one expression, optionally enclosed in (), no statements.
		 * Used in conjunction with _validStatementPatterns.
		 */
		private static const PN_EXPR:String = 'EXPR';
		
		/**
		 * variable names and/or assignments separated by commas
		 * Used in conjunction with _validStatementPatterns.
		 */
		private static const PN_VARS:String = 'VARS';
		
		/**
		 * longer patterns appear earlier so they will match before shorter patterns when checked in order
		 */
		private static const _validStatementPatterns:Array = [
			[ST_IF, PN_PARAMS, PN_STMT, ST_ELSE, PN_STMT],
			[ST_IF, PN_PARAMS, PN_STMT],
			[ST_FOR_EACH, PN_PARAMS, PN_STMT],
			[ST_FOR, PN_PARAMS, PN_STMT],
			[ST_DO, PN_STMT, ST_WHILE, PN_PARAMS],
			[ST_WHILE, PN_PARAMS, PN_STMT],
			[ST_TRY, PN_BLOCK, ST_CATCH, PN_PARAMS, PN_BLOCK, ST_FINALLY, PN_BLOCK],
			[ST_TRY, PN_BLOCK, ST_FINALLY, PN_BLOCK],
			[ST_TRY, PN_BLOCK, ST_CATCH, PN_PARAMS, PN_BLOCK],
			[ST_BREAK],
			[ST_CONTINUE],
			[ST_RETURN, PN_EXPR],
			[ST_RETURN],
			[ST_THROW, PN_EXPR],
			[ST_VAR, PN_VARS],
			[ST_IMPORT, PN_EXPR]
		];

		/**
		 * (statement name):String -> (true if requires parentheses):Boolean
		 */
		private static var statements:Object = null;
		
		private static const OPERATOR_NEW:String = 'new';
		
		/**
		 * This is the prefix used for the function notation of infix operators.
		 * For example, the function notation for ( x + y ) is ( \+(x,y) ).
		 */
		public static const OPERATOR_ESCAPE:String = '\\';
		
		public static const FUNCTION:String = 'function';
		public static const FUNCTION_PARAM_NAMES:String = 'names';
		public static const FUNCTION_PARAM_VALUES:String = 'values';
		public static const FUNCTION_CODE:String = 'code';
		
		/**
		 * This is a String containing all the characters that are treated as whitespace.
		 */
		private static const WHITESPACE:String = '\r\n \t\f';
		/**
		 * This is used to match number tokens.
		 */		
		private static const numberRegex:RegExp = /^(0x[0-9A-Fa-f]+|[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)/;
		
		private const JUMP_LOOKUP:Dictionary = new Dictionary(); // Function -> true
		private const LOOP_LOOKUP:Dictionary = new Dictionary(); // Function -> true or ST_BREAK or ST_CONTINUE
		private const BRANCH_LOOKUP:Dictionary = new Dictionary(); // Function -> Boolean, for short-circuiting
		private const ASSIGN_OP_LOOKUP:Object = new Dictionary(); // Function -> true
		private const PURE_OP_LOOKUP:Dictionary = new Dictionary(); // Function -> true
		private const MAX_OPERATOR_LENGTH:int = 4;
		
		/**
		 * This is a list of objects and/or classes containing functions and constants supported by the compiler.
		 */
		private const libraries:Array = [];
		
		/**
		 * This object maps the name of a predefined constant to its value.
		 */
		private var constants:Object = null;
		/**
		 * This object maps the name of a global symbol to its value.
		 */
		private var globals:Object = null;
		/**
		 * This object maps an operator like "*" to a Function or a valie of true if there is no function.
		 */
		private var operators:Object = null;
		/**
		 * A pure operator is one that always gives the same result when invoked with the same parameters.
		 * This object maps a pure operator like "+" to its corresponding function.
		 */
		private var pureOperators:Object = null;
		/**
		 * This object maps an assignment operator like "=" to its corresponding function.
		 * This object is used as a quick lookup to see if an operator is an assignment operator.
		 */
		private var assignmentOperators:Object = null;
		/**
		 * This is a two-dimensional Array of operator symbols arranged in the order they should be evaluated.
		 * Each nested Array is a group of operators that should be evaluated in the same pass.
		 */
		private var orderedOperators:Array = null;
		/**
		 * This is an Array of all the unary operator symbols.
		 */
		private var unaryOperatorSymbols:Array = null;
		
		/**
		 * This is used to temporarily store the host of the property that was accessed by the last call to the '.' operator.
		 */		
		private var _propertyHost:Object = null;
		/**
		 * This is used to temporarily store the property name that was accessed by the last call to the '.' operator.
		 */		
		private var _propertyName:* = null;

		/**
		 * This function compiles an expression into a Function that evaluates using variables from a symbolTable.
		 * Strings may be surrounded by quotation marks (") and literal quotation marks are escaped by two quote marks together ("").
		 * The escape sequence for a quoted variable name to indicate a quotation mark is two quotation marks together.
		 * @param expression An expression to compile.
		 * @param symbolTable This is a lookup table containing custom variables and functions that can be used in the expression. Multiple lookup tables can be specified in an Array. The values in the lookup tables may be changed outside the function after compiling.
		 * @param errorHandler A function that takes an Error and optionally returns true if execution should continue, behaving as if the current instruction returned undefined.
		 * @param useThisScope If this is set to true, properties of 'this' can be accessed as if they were local variables.
		 * @param paramNames This specifies local variable names to be associated with the arguments passed in as parameters to the compiled function.
		 * @param paramDefaults This specifies default values corresponding to the parameter names.  This must be the same length as the paramNames array.
		 * @return A Function generated from the expression String, or null if the String does not represent a valid expression.
		 */
		public function compileToFunction(expression:String, symbolTable:Object, errorHandler:Function = null, useThisScope:Boolean = false, paramNames:Array = null, paramDefaults:Array = null):Function
		{
			var tokens:Array = getTokens(expression);
			//trace("source:", expression, "tokens:" + tokens.join(' '));
			var compiledObject:ICompiledObject = finalize(compileTokens(tokens, true));
			return compileObjectToFunction(compiledObject, symbolTable, errorHandler, useThisScope, paramNames, paramDefaults);
		}
		
		/**
		 * This function will compile an expression into a compiled object representing a function that takes no parameters and returns a value.
		 * This function is useful for inspecting the structure of the compiled function and decompiling individual parts.
		 * @param expression An expression to parse.
		 * @return A CompiledConstant or CompiledFunctionCall generated from the tokens, or null if the tokens do not represent a valid expression.
		 */
		public function compileToObject(expression:String):ICompiledObject
		{
			return finalize(compileTokens(getTokens(expression), true));
		}
		
		// TODO: includeLibrary(sourceSymbolTable, destinationSymbolTable) where it copies all the properties of source to destination
		
		/**
		 * avmplus.describeTypeJSON(o:*, flags:uint):Object
		 */
		private static const describeTypeJSON:Function = DescribeType.getJSONFunction();
		
		/**
		 * This function will include additional libraries to be supported by the compiler when compiling functions.
		 * @param classesOrObjects An Array of Class definitions or objects containing functions to be supported by the compiler.
		 */
		public function includeLibraries(...classesOrObjects):void
		{
			for each (var library:Object in classesOrObjects)
			{
				// only add this library to the list if it is not already added.
				if (library != null && libraries.indexOf(library) < 0)
				{
					var className:String = null;
					if (library is String)
					{
						className = library as String;
						library = getDefinitionByName(className);
						if (libraries.indexOf(library) >= 0)
							continue;
					}
					else if (library is Class)
					{
						className = getQualifiedClassName(library as Class);
					}
					if (className)
					{
						// save the class name as a symbol
						className = className.substr(Math.max(className.lastIndexOf('.'), className.lastIndexOf(':')) + 1);
						globals[className] = library;
					}
					if (library is Function) // special case for global function like flash.utils.getDefinitionByName
						continue;
					
					libraries.push(library);
				}
			}
		}
		
		/**
		 * This function will add a variable to the constants available in expressions.
		 * @param constantName The name of the constant.
		 * @param constantValue The value of the constant.
		 */
		public function importGlobal(constantName:String, constantValue:*):void
		{
			globals[constantName] = constantValue;
		}

		/**
		 * This function gets a list of all the libraries currently being used by the compiler.
		 * @return A new Array containing a list of all the objects and/or classes used as libraries in the compiler.
		 */		
		public function getAllLibraries():Array
		{
			return libraries.concat(); // make a copy
		}
		/**
		 * This function will initialize the operators and constants.
		 */
		private function initialize():void
		{
			if (!statements)
			{
				statements = {};
				var stmt:String;
				for each (stmt in _statementsWithParams)
					statements[stmt] = true;
				for each (stmt in _statementsWithoutParams)
					statements[stmt] = false;
			}
			constants = {};
			globals = {};
			operators = {};
			pureOperators = {};
			assignmentOperators = {};
			
			// constant, built-in symbols
			for each (var _const:* in [null, true, false, undefined, NaN, Infinity])
				constants[String(_const)] = _const;
			
			// global classes
			var _QName:* = getDefinitionByName('QName'); // workaround to avoid asdoc error
			var _XML:* = getDefinitionByName('XML'); // workaround to avoid asdoc error
			for each (var _class:Class in [Array, Boolean, Class, Date, Error, Function, int, Namespace, Number, Object, _QName, String, uint, _XML])
				globals[getQualifiedClassName(_class)] = _class;
			// global functions
			for each (var _funcName:String in 'decodeURI,decodeURIComponent,encodeURI,encodeURIComponent,escape,isFinite,isNaN,isXMLName,parseFloat,parseInt,trace,unescape'.split(','))
				globals[_funcName] = getDefinitionByName(_funcName);
			
			
			/** operators **/
			// first, make sure all special characters are defined as operators whether or not they have functions associated with them
			var specialChars:String = "`~!#%^&*()-+=[{]}\\|;:'\",<.>/?";
			for (var i:int = 0; i < specialChars.length; i++)
				operators[specialChars.charAt(i)] = true;
			
			// now define the functions
			
			// impure operators
			operators["["] = function(...args):* { return args; }; // array creation
			operators[OPERATOR_NEW] = function(classOrQName:Object, ...params):Object
			{
				var classDef:Class = classOrQName as Class;
				if (!classDef && classOrQName)
					classDef = getDefinitionByName(String(classOrQName)) as Class;
				switch (params.length)
				{
					case 0: return new classDef();
					case 1: return new classDef(params[0]);
					case 2: return new classDef(params[0], params[1]);
					case 3: return new classDef(params[0], params[1], params[2]);
					case 4: return new classDef(params[0], params[1], params[2], params[3]);
					case 5: return new classDef(params[0], params[1], params[2], params[3], params[4]);
					case 6: return new classDef(params[0], params[1], params[2], params[3], params[4], params[5]);
					case 7: return new classDef(params[0], params[1], params[2], params[3], params[4], params[5], params[6]);
					case 8: return new classDef(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7]);
					case 9: return new classDef(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8]);
					case 10: return new classDef(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9]);
					default: throw new Error("Too many constructor parameters (maximum 10)");
				}
			};
			operators[FUNCTION] = function(..._):*{};
			// property access should not be optimized to constants
			operators["."] = function(object:*, ...chain):* {
				var iHost:int = chain.length - 2;
				_propertyHost = object;
				_propertyName = chain[iHost + 1];
				for (var i:int = 0; i < chain.length; i++)
				{
					if (i == iHost)
						_propertyHost = object;
					object = object[chain[i]];
				}
				return object;
			};
			operators[".."] = function(object:*, propertyName:*):* {
				if (typeof(object) == 'xml')
					return object.descendants(propertyName);
				return object.flash_proxy::getDescendants(propertyName);
			};
			operators['in'] = function(...args):* {
				// dual purpose for infix operator and for..in loop initialization
				if (args.length == 2)
					return args[0] in args[1];
				
				var a:Array = [];
				for (var k:* in args[0])
					a.push(k);
				return a;
			};
			operators[ST_VAR] = function(..._):*{};
			operators[ST_IMPORT] = function(..._):*{};
			// loop statements
			operators[ST_DO] = function(x:*, y:*):* { return x && y; };
			operators[ST_WHILE] = function(x:*, y:*):* { return x && y; };
			operators[ST_FOR] = function(x:*, y:*):* { return x && y; };
			operators[ST_FOR_DO] = function(x:*, y:*):* { return x && y; };
			operators[ST_FOR_IN] = function(..._):*{};
			operators[ST_FOR_EACH] = function(..._):*{};
			// jump statements
			operators[ST_BREAK] = function(..._):*{};
			operators[ST_CONTINUE] = function(..._):*{};
			operators[ST_RETURN] = function(..._):*{};
			operators[ST_THROW] = function(e:*):* { throw e; };
			
			// 'if' statement can be considered a pure operator
			pureOperators[ST_IF] = function(c:*, t:*, f:*):* { return c ? t : f; };
			// math
			pureOperators["**"] = Math.pow;
			pureOperators["*"] = function(x:*, y:*):Number { return x * y; };
			pureOperators["/"] = function(x:*, y:*):Number { return x / y; };
			pureOperators["%"] = function(x:*, y:*):Number { return x % y; };
			pureOperators["+"] = function(...args):* {
				// this works as a unary or infix operator
				switch (args.length)
				{
					case 1:
						return +args[0];
					case 2:
						return args[0] + args[1];
				}
			};
			pureOperators["-"] = function(...args):* {
				// this works as a unary or infix operator
				switch (args.length)
				{
					case 1:
						return -args[0];
					case 2:
						return args[0] - args[1];
				}
			};
			// bitwise
			pureOperators["~"] = function(x:*):* { return ~x; };
			pureOperators["&"] = function(x:*, y:*):* { return x & y; };
			pureOperators["|"] = function(x:*, y:*):* { return x | y; };
			pureOperators["^"] = function(x:*, y:*):* { return x ^ y; };
			pureOperators["<<"] = function(x:*, y:*):* { return x << y; };
			pureOperators[">>"] = function(x:*, y:*):* { return x >> y; };
			pureOperators[">>>"] = function(x:*, y:*):* { return x >>> y; };
			// comparison
			pureOperators["<"] = function(x:*, y:*):Boolean { return x < y; };
			pureOperators["<="] = function(x:*, y:*):Boolean { return x <= y; };
			pureOperators[">"] = function(x:*, y:*):Boolean { return x > y; };
			pureOperators[">="] = function(x:*, y:*):Boolean { return x >= y; };
			pureOperators["=="] = function(x:*, y:*):Boolean { return x == y; };
			pureOperators["==="] = function(x:*, y:*):Boolean { return x === y; };
			pureOperators["!="] = function(x:*, y:*):Boolean { return x != y; };
			pureOperators["!=="] = function(x:*, y:*):Boolean { return x !== y; };
			// logic
			pureOperators["!"] = function(x:*):Boolean { return !x; };
			pureOperators["&&"] = function(x:*, y:*):* { return x && y; };
			pureOperators["||"] = function(x:*, y:*):* { return x || y; };
			// branching
			pureOperators["?:"] = function(c:*, t:*, f:*):* { return c ? t : f; };
			// multiple commands - equivalent functionality but must be remembered as different operators
			pureOperators[','] = function(...args):* { return args[args.length - 1]; };
			pureOperators[';'] = function(...args):* { return args[args.length - 1]; };
			pureOperators['('] = function(...args):* { return args[args.length - 1]; };
			// operators with alphabetic names
			pureOperators['void'] = function(..._):void { };
			pureOperators['typeof'] = function(value:*):* { return typeof(value); };
			pureOperators['as'] = function(a:*, b:*):Object { return a as b; };
			pureOperators['is'] = pureOperators['instanceof'] = function(a:*, b:*):Boolean { return a is b; };
			// assignment operators -- first arg is host object, last arg is new value, remaining args are a chain of property names
			assignmentOperators['=']    = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] =    a[i + 1]; };
			assignmentOperators['+=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] +=   a[i + 1]; };
			assignmentOperators['-=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] -=   a[i + 1]; };
			assignmentOperators['*=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] *=   a[i + 1]; };
			assignmentOperators['/=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] /=   a[i + 1]; };
			assignmentOperators['%=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] %=   a[i + 1]; };
			assignmentOperators['<<=']  = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] <<=  a[i + 1]; };
			assignmentOperators['>>=']  = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] >>=  a[i + 1]; };
			assignmentOperators['>>>='] = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] >>>= a[i + 1]; };
			assignmentOperators['&&=']  = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] &&=  a[i + 1]; };
			assignmentOperators['||=']  = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] ||=  a[i + 1]; };
			assignmentOperators['&=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] &=   a[i + 1]; };
			assignmentOperators['|=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] |=   a[i + 1]; };
			assignmentOperators['^=']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]] ^=   a[i + 1]; };
			// special cases: delete, -- and ++ unary operators ignore last parameter
			assignmentOperators['--']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return --o[a[i]]; };
			assignmentOperators['++']   = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return ++o[a[i]]; };
			assignmentOperators['#--']  = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]]--; };
			assignmentOperators['#++']  = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return o[a[i]]++; };
			assignmentOperators['delete'] = function(o:*, ...a):* { for (var i:int = 0; i < a.length - 2; i++) o = o[a[i]]; return delete o[a[i]]; };
			
			// evaluate operators in the same order as ActionScript
			orderedOperators = [
				['*','/','%'],
				['+','-'],
				['<<','>>','>>>'],
				['<','<=','>','>=','as','in','instanceof','is'],
				['==','!=','===','!=='],
				['&'],
				['^'],
				['|'],
				['&&'],
				['||']
			];
			// unary operators
			unaryOperatorSymbols = ['++','--','+','-','~','!','delete','typeof','void']; // '#' not listed because it has special evaluation order

			var op:String;
			
			// copy over pure and assignment operators
			for (op in pureOperators)
				operators[op] = pureOperators[op];
			for (op in assignmentOperators)
				operators[op] = assignmentOperators[op];
			
			// create a corresponding function name for each operator
			for (op in operators)
				if (operators[op] is Function)
					constants[OPERATOR_ESCAPE + op] = operators[op];
			
			// fill reverse-lookup dictionaries
			BRANCH_LOOKUP[operators[ST_IF]] = true;
			BRANCH_LOOKUP[operators[ST_DO]] = true;
			BRANCH_LOOKUP[operators[ST_WHILE]] = true;
			BRANCH_LOOKUP[operators[ST_FOR]] = true;
			BRANCH_LOOKUP[operators[ST_FOR_DO]] = true;
			BRANCH_LOOKUP[operators['?:']] = true;
			BRANCH_LOOKUP[operators['&&']] = true;
			BRANCH_LOOKUP[operators['||']] = false;
			
			LOOP_LOOKUP[operators[ST_DO]] = true;
			LOOP_LOOKUP[operators[ST_WHILE]] = true;
			LOOP_LOOKUP[operators[ST_FOR]] = ST_BREAK; // break target only
			LOOP_LOOKUP[operators[ST_FOR_DO]] = ST_CONTINUE; // continue target only
			LOOP_LOOKUP[operators[ST_FOR_IN]] = true;
			LOOP_LOOKUP[operators[ST_FOR_EACH]] = true;
			
			JUMP_LOOKUP[operators[ST_BREAK]] = true;
			JUMP_LOOKUP[operators[ST_CONTINUE]] = true;
			JUMP_LOOKUP[operators[ST_RETURN]] = true;
			JUMP_LOOKUP[operators[ST_THROW]] = true;

			var func:Function;

			for each (func in pureOperators)
				PURE_OP_LOOKUP[func] = true;
				
			for each (func in assignmentOperators)
				ASSIGN_OP_LOOKUP[func] = true;
		}
		
		/**
		 * This will set the behavior of the '#' operator.
		 * @param hashFunction A function that takes one parameter for use as an infix operator.
		 */		
		public function setHashOperator(hashFunction:Function):void
		{
			constants[OPERATOR_ESCAPE + '#'] = operators['#'] = hashFunction;
		}

		/**
		 * @param expression An expression string to parse.
		 * @return An Array containing all the tokens found in the expression.
		 */
		private function getTokens(expression:String):Array
		{
			var tokens:Array = [];
			if (!expression)
				return tokens;
			var n:int = expression.length;
			// get a flat list of tokens
			var i:int = 0;
			while (i < n)
			{
				var token:String = getToken(expression, i);
				var substr:String = token.substr(0, 2);
				// skip whitespace and comments
				if (substr != '//' && substr != '/*' && WHITESPACE.indexOf(token.charAt(0)) == -1)
					tokens.push(token);
				i += token.length;
			}
			return tokens;
		}
		/**
		 * This function is for internal use only.
		 * @param expression An expression to parse.
		 * @param index The starting index of the token.
		 * @return The token beginning at the specified index, or null if an invalid quoted string was found.
		 */
		private function getToken(expression:String, index:int):String
		{
			var endIndex:int;
			var n:int = expression.length;
			var c:String = expression.charAt(index);
			
			// handle comments
			if (c == '/')
			{
				var c2:String = expression.charAt(index + 1);
				
				if (c2 == '/') // line comment
					return expression.substr(index).split('\r')[0].split('\n')[0];
				
				if (c2 == '*') /* block comment */
				{
					var endBlockComment:int = expression.indexOf("*/", index + 2);
					if (endBlockComment < 0)
						throw new Error('Missing end sequence of block comment ("*/"): ' + expression.substr(index));
					return expression.substring(index, endBlockComment + 2);
				}
			}
			
			// handle quoted string
			if (c == '"' || c == "'" || c == '`')
			{
				var quote:String = c;
				// index points to the opening quote
				// make endIndex point to the matching end quote
				for (c = null, endIndex = index + 1; endIndex < n; endIndex++)
				{
					c = expression.charAt(endIndex);
					// stop when matching quote found, unless there are two together for an escape sequence
					if (c == quote)
					{
						if (endIndex < n - 1 && expression.charAt(endIndex + 1) == quote)
						{
							// skip second quote
							endIndex++;
						}
						else
						{
							// return the quoted string, including the quotes
							return expression.substring(index, endIndex + 1);
						}
					}
					else if (c == '\\') // handle escape sequences
					{
						endIndex++; // skip the next character
					}
				}
				// invalid quoted string
				throw new Error("Missing matching end quote: " + expression.substr(index));
			}
			
			// handle numbers
			var foundNumber:Object = numberRegex.exec(expression.substr(index))
			if (foundNumber)
				return foundNumber[0];

			// handle operators (find the longest matching operator)
			// this function assumes operators has already been initialized
			if (operators.hasOwnProperty(c)) // only handle operator if it begins with operator character (doesn't include as,in,instanceof,is)
				for (var opLength:int = MAX_OPERATOR_LENGTH; opLength > 0; opLength--)
					if (operators.hasOwnProperty(c = expression.substr(index, opLength)))
						return c;
			
			// handle whitespace (find the longest matching sequence)
			endIndex = index;
			while (endIndex < n && WHITESPACE.indexOf(expression.charAt(endIndex)) >= 0)
				endIndex++;
			if (index < endIndex)
				return expression.substring(index, endIndex);

			// handle everything else (go until a special character is found)
			for (endIndex = index + 1; endIndex < n; endIndex++)
			{
				c = expression.charAt(endIndex);
				// whitespace terminates a token
				if (WHITESPACE.indexOf(c) >= 0)
					break;
				// operator terminates a token
				if (operators.hasOwnProperty(c))
					break;
			}
			return expression.substring(index, endIndex);
		}

		/**
		 * This function will recursively compile a set of tokens into a compiled object representing a function that takes no parameters and returns a value.
		 * Example set of input tokens:  pow ( - ( - 2 + 1 ) ** - 4 , 3 ) - ( 4 + - 1 )
		 * @param tokens An Array of tokens for an expression.  This array will be modified in place.
		 * @param allowSemicolons Set to true to allow multiple statements and empty expressions.
		 * @return A CompiledConstant or CompiledFunctionCall generated from the tokens, or null if the tokens do not represent a valid expression.
		 */
		private function compileTokens(tokens:Array, allowSemicolons:Boolean):ICompiledObject
		{
			// there are no more parentheses, so the remaining tokens are operators, constants, and variable names.
			if (debug)
				trace("compiling tokens", tokens.join(' '));

			var i:int;
			var token:String;
			var str:String;
			
			// first step: compile quoted Strings and Numbers
			for (i = 0; i < tokens.length; i++)
			{
				str = tokens[i] as String;
				if (!str)
					continue;
				
				// if the token starts with a quote, treat it as a String
				if (str.charAt(0) == '"' || str.charAt(0) == "'" || str.charAt(0) == '`')
				{
					tokens[i] = compileStringLiteral(str);
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
			
			// next step: compile escaped operators
			for (i = 0; i < tokens.length - 1; i++)
			{
				token = tokens[i];
				if (token == OPERATOR_ESCAPE && operators[tokens[i + 1]] is Function)
				{
					token = tokens[i + 1];
					tokens.splice(i, 2, new CompiledConstant(OPERATOR_ESCAPE + token, operators[token]));
				}
			}
			
			// next step: combine 'for each' into a single token
			for (i = tokens.length; i > 0; i--)
				if (tokens[i] == ST_EACH && tokens[i - 1] == ST_FOR)
					tokens.splice(i - 1, 2, ST_FOR_EACH);
			if (tokens[0] == ST_EACH)
				throw new Error("Invalid statement 'each'");
			
			// next step: compile unary '#' operators (except those immediately followed by other operators)
			if (operators.hasOwnProperty('#'))
				compileUnaryOperators(tokens, ['#']);
			
			// next step: handle operators "..[]{}()"
			compileBracketsAndProperties(tokens);

			// next step: handle stray operators "..[](){}"
			for (i = 0; i < tokens.length; i++)
				if (tokens[i] is String && '..[](){}'.indexOf(tokens[i] as String) >= 0)
					throw new Error("Misplaced '" + tokens[i] + "'" + _betweenTwoTokens(tokens[i - 1], tokens[i + 1]));

			// next step: compile constants and variable names
			for (i = 0; i < tokens.length; i++)
			{
				token = tokens[i] as String;
				// skip tokens that have already been compiled and skip operator tokens
				if (token == null || operators.hasOwnProperty(token))
					continue;
				// evaluate constants
				if (constants.hasOwnProperty(token))
				{
					tokens[i] = new CompiledConstant(token, constants[token]);
					continue;
				}
				// treat everything else as a variable name.
				// make a copy of the variable name that is safe for the wrapper function to use
				// compile the token as a call to variableGetter.
				tokens[i] = compileVariable(token);
			}
			
			// next step: compile new operator used as a unary operator (missing parentheses)
			compileUnaryOperators(tokens, [OPERATOR_NEW]);
			
			// next step: compile unary '#' operators
			if (operators.hasOwnProperty('#'))
				compileUnaryOperators(tokens, ['#']);
			
			compilePostfixOperators(tokens, ['--', '++']);
			
			// next step: compile infix '**' operators
			compileInfixOperators(tokens, ['**']);
			
			// next step: compile unary operators
			compileUnaryOperators(tokens, unaryOperatorSymbols);
			
			// next step: compile remaining infix operators in order
			for (i = 0; i < orderedOperators.length; i++)
				compileInfixOperators(tokens, orderedOperators[i]);
			
			// next step: compile conditional branches
			conditionals: while (true)
			{
				// true branch includes everything between the last '?' and the next ':'
				var left:int = tokens.lastIndexOf('?');
				var right:int = tokens.indexOf(':', left);
				
				var terminators:Array = [',', ';'];
				for each (var terminator:String in terminators)
				{
					var terminatorIndex:int = tokens.indexOf(terminator, left);
					if (terminatorIndex >= 0 && terminatorIndex < right)
						throw new Error("Expecting colon before '" + terminator + "'");
					if (terminatorIndex == right + 1)
						break conditionals; // missing expression
				}
				
				// stop if operator missing or any section has no tokens
				if (right < 0 || left < 1 || left + 1 == right || right + 1 == tokens.length)
					break;
				
				// false branch includes everything after ':' and up until the next ?:,;
				var end:int = right + 2;
				while (end < tokens.length)
				{
					token = tokens[end] as String;
					if (token && '?:,;'.indexOf(token) >= 0)
						break;
					end++;
				}
				if (debug)
					trace("compiling conditional branch:", tokens.slice(left - 1, right + 2).join(' '));
				
				// condition includes only the token to the left of the '?'
				var condition:ICompiledObject = compileTokens(tokens.slice(left - 1, left), false);
				var trueBranch:ICompiledObject = compileTokens(tokens.slice(left + 1, right), false);
				var falseBranch:ICompiledObject = compileTokens(tokens.slice(right + 1, end), false);
				tokens.splice(left - 1, end - left + 1, compileOperator('?:', [condition, trueBranch, falseBranch]));
			}
			// stop if any branch operators remain
			if (Math.max(tokens.indexOf('?'), tokens.indexOf(':')) >= 0)
				throw new Error('Invalid conditional branch');
			
			// next step: variable assignment, right to left
			while (true)
			{
				i = tokens.length;
				while (i--)
					if (assignmentOperators.hasOwnProperty(tokens[i]))
						break;
				if (i < 0)
					break;
				if (i == 0 || i + 1 == tokens.length)
					throw new Error("Misplaced '" + tokens[i] + "'");
				tokens.splice(i - 1, 3, compileVariableAssignment.apply(null, tokens.slice(i - 1, i + 2)));
			}
			
			// next step: commas
			compileInfixOperators(tokens, [',']);
			
			// next step: handle statements
			if (allowSemicolons)
			{
				var call:CompiledFunctionCall;
				// remove leading ';'
				while (tokens[0] == ';')
					tokens.shift();
				// convert EXPR; to {EXPR}
				for (i = 1; i < tokens.length; i++)
				{
					if (tokens[i] == ';')
					{
						call = tokens[i - 1] as CompiledFunctionCall;
						
						if (_jumpStatements.indexOf(tokens[i - 1]) >= 0 || (call && call.evaluatedMethod == operators['(']))
						{
							// support for "return;" and "while (cond);"
							tokens[i] = compileOperator(';', []);
						}
						else if (tokens[i - 1] is CompiledConstant || (call && call.evaluatedMethod != operators[';']))
						{
							// support for "while (cond) expr;"
							tokens.splice(i - 1, 2, compileOperator(';', [tokens[i - 1]]));
						}
					}
				}
				
				// if there are any remaining ';', compile separate statements
				if (tokens.indexOf(';') >= 0)
					return compileOperator(';', compileArray(tokens, ';'));
				
				// there are no more ';'
				assertValidStatementParams(tokens);
				for (i = 0; i < tokens.length; i++)
					compileStatement(tokens, i);
				
				// group multiple statements in {}
				if (tokens.length > 1)
					return compileOperator(';', tokens);
			}
			else if (tokens.indexOf(';') >= 0)
				throw new Error("Misplaced ';'");
			
			// last step: verify there is only one token left
			if (tokens.length == 1)
				return tokens[0];

			if (tokens.length > 1)
				throw new Error("Missing operator" + _betweenTwoTokens(tokens[0], tokens[1]));

			if (allowSemicolons)
				return compileOperator(';', tokens);
			
			throw new Error("Empty expression");
		}
		
		/**
		 * Used for generating a portion of an error message like " between token1 and token2"
		 */
		private function _betweenTwoTokens(token1:Object, token2:Object):String
		{
			if (token1 is ICompiledObject)
				token1 = decompileObject(token1 as ICompiledObject);
			if (token2 is ICompiledObject)
				token2 = decompileObject(token2 as ICompiledObject);
			if (token1 && token2)
				return ' between ' + token1 + ' and ' + token2;
			if (token1)
				return ' after ' + token1;
			if (token2)
				return ' before ' + token2;
			return '';
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
		private static const ENCODE_LOOKUP:Object = {'\b':'b', '\f':'f', '\n':'n', '\r':'r', '\t':'t', '\\':'\\', '{':'{'};
		private static const DECODE_LOOKUP:Object = {'b':'\b', 'f':'\f', 'n':'\n', 'r':'\r', 't':'\t'};
		
		/**
		 * This function surrounds a String with quotes and escapes special characters using ActionScript string literal format.
		 * @param string A String that may contain special characters.
		 * @param useDoubleQuotes If this is true, double-quote will be used.  If false, single-quote will be used.
		 * @return The given String formatted for ActionScript.
		 */
		public static function encodeString(string:String, quote:String = '"'):String
		{
			var result:Array = new Array(string.length);
			for (var i:int = 0; i < string.length; i++)
			{
				var chr:String = string.charAt(i);
				var esc:String = chr == quote ? quote : ENCODE_LOOKUP[chr];
				result[i] = esc ? '\\' + esc : chr;
			}
			return quote + result.join('') + quote;
		}
		
		/**
		 * This function is for internal use only.  It assumes the string it receives is valid.
		 * @param encodedString A quoted String with special characters escaped using ActionScript string literal format.
		 * @return The compiled string.
		 */
		private function compileStringLiteral(encodedString:String):ICompiledObject
		{
			// remove quotes
			var quote:String = encodedString.charAt(0);
			var input:String = encodedString.substr(1, encodedString.length - 2);
			input = input.split(quote + quote).join(quote); // handle doubled quote escape sequences
			var output:String = "";
			var searchIndex:int = 0;
			var compiledObjects:Array = [];
			while (true)
			{
				var escapeIndex:int = input.indexOf("\\", searchIndex);
				if (escapeIndex < 0)
					escapeIndex = input.length;
				// only support expressions inside { } if the string literal is surrounded by the '`' quote symbol.
				var bracketIndex:int = quote == '`' ? input.indexOf("{", searchIndex) : -1;
				if (bracketIndex < 0)
					bracketIndex = input.length;
				
				if (bracketIndex == escapeIndex) // handle end of string
				{
					output += input.substring(searchIndex);
					input = encodeString(output, quote); // use original quote symbol
					
					var compiledString:CompiledConstant = new CompiledConstant(input, output);
					
					if (compiledObjects.length == 0)
						return compiledString;
					
					compiledObjects.unshift(compiledString);
					return new CompiledFunctionCall(new CompiledConstant('substitute', StandardLib.substitute), compiledObjects);
				}
				else if (escapeIndex < bracketIndex) // handle '\'
				{
					// append everything before the escaped character
					output += input.substring(searchIndex, escapeIndex);
					
					// look up escaped character
					var c:String = input.charAt(escapeIndex + 1);
					c = DECODE_LOOKUP[c] || c;
					
					if ('0123'.indexOf(c) >= 0)
					{
						// \000 .. \377        a byte specified in octal
						var oct:String = input.substr(escapeIndex + 1, 3);
						c = String.fromCharCode(parseInt(oct, 8));
						searchIndex = escapeIndex + 4; // skip over escape sequence
					}
					else if (c == 'x')
					{
						// \x00 .. \xFF        a byte specified in hexadecimal
						var hex:String = input.substr(escapeIndex + 2, 2);
						c = String.fromCharCode(parseInt(hex, 16));
						searchIndex = escapeIndex + 4; // skip over escape sequence
					}
					else if (c == 'u')
					{
						// \u0000 .. \uFFFF    a 16-bit Unicode character specified in hexadecimal
						var unicode:String = input.substr(escapeIndex + 2, 4);
						c = String.fromCharCode(parseInt(unicode, 16));
						searchIndex = escapeIndex + 6; // skip over escape sequence
					}
					else
					{
						searchIndex = escapeIndex + 2; // skip over escape sequence
					}
					
					// append the escaped character
					output += c;
				}
				else if (bracketIndex < escapeIndex) // handle '{'
				{
					// handle { } brackets for inline code
					var tokens:Array = [];
					var token:String = null;
					var depth:int = 1;
					escapeIndex = bracketIndex + 1;
					while (escapeIndex < input.length)
					{
						token = getToken(input, escapeIndex);
						if (token == '{')
							depth++;
						if (token == '}')
							depth--;
						if (depth == 0)
							break;
						if (WHITESPACE.indexOf(token.charAt(0)) == -1)
							tokens.push(token);
						escapeIndex += token.length;
					}
					if (escapeIndex == input.length)
						throw new Error("Missing '}' in string literal inline code: " + input);
					
					// now bracketIndex points to '{' and escapeIndex points to matching '}'
					//replace code between brackets with an int like {0} so the resulting string can be passed to StandardLib.substitute() with compiledObject as the next parameter
					output += input.substring(searchIndex, bracketIndex) + '{' + compiledObjects.length + '}';
					searchIndex = escapeIndex + 1;
					compiledObjects.push(compileTokens(tokens, true));
				}
			}
			throw new Error("unreachable");
		}
		
		/**
		 * 
		 * @param leftBracket
		 * @param rightBracket
		 * @param tokens
		 */
		private function compileBracketsAndProperties(tokens:Array):void
		{
			var token:Object;
			var compiledToken:ICompiledObject;
			var compiledParams:Array;
			var open:int;
			var close:int;
			var leftBracket:String;
			var rightBracket:String;
			while (true)
			{
				// find first closing bracket or '.' or '..'
				for (close = 0; close < tokens.length; close++)
					if ('..])}'.indexOf(tokens[close]) >= 0)
						break;
				if (close == tokens.length || close == 0)
					break; // possible error, or no operator found
				
				// use matching brackets
				rightBracket = tokens[close];
				if (rightBracket == '..')
					leftBracket = '..';
				else
					leftBracket = '.[({'.charAt('.])}'.indexOf(rightBracket));
				
				// work backwards to the preceeding, matching opening bracket or stop if '.'
				for (open = close; open >= 0; open--)
					if (tokens[open] == leftBracket)
						break;
				if (open < 0 || open + 1 == tokens.length)
					break; // possible error, or no operator found
				
				// unless it's an operator, compile the token to the left
				token = open > 0 ? tokens[open - 1] : null;
				compiledToken = token as ICompiledObject;
				if (open > 0 && !compiledToken && !operators.hasOwnProperty(token))
				{
					// The function token hasn't been compiled yet.
					if (constants.hasOwnProperty(token))
						compiledToken = new CompiledConstant(token as String, constants[token]);
					else
						compiledToken = compileVariable(token as String) as ICompiledObject;
				}

				// handle access and descendants operators
				if ('..'.indexOf(tokens[open]) == 0)
				{
					var propertyToken:String = tokens[open + 1] as String;
					
					if (!compiledToken || !propertyToken || operators.hasOwnProperty(propertyToken))
						throw new Error("Misplaced '" + tokens[open] + "' " + _betweenTwoTokens(token, tokens[open + 1]));
					
					// the token on the right is a variable name, but we will store it as a String because it's a property lookup
					compiledParams = [compiledToken, new CompiledConstant(encodeString(propertyToken), propertyToken)];
					tokens.splice(open - 1, 3, compileOperator(tokens[open], compiledParams));
					continue;
				}
				
				// cut out tokens between brackets
				var subArray:Array = tokens.splice(open + 1, close - open - 1);
				
				if (debug)
					trace("compiling tokens", leftBracket, subArray.join(' '), rightBracket);
				
				if (leftBracket == '{')
				{
					// It's ok if it creates an extra {} wrapper because finalize() will take care of that.
					// It's important to remember that the brackets existed for statement processing.
					tokens.splice(open, 2, compileOperator(';', [compileTokens(subArray, true)]));
					
					// compile inline function
					if (open >= 2 && tokens[open - 2] == FUNCTION)
					{
						var call:CompiledFunctionCall = compiledToken as CompiledFunctionCall;
						if (!call || call.evaluatedMethod != operators[','])
							throwInvalidSyntax(FUNCTION);
						
						// verify that each parameter inside operator ',' is a variable name or a local assignment to a constant.
						var variableNames:Array = [];
						var variableValues:Array = [];
						for each (token in call.compiledParams)
						{
							var variable:CompiledFunctionCall = token as CompiledFunctionCall;
							if (!variable)
								throwInvalidSyntax(FUNCTION);
							
							if (!variable.compiledParams)
							{
								// local variable
								variableNames.push(variable.evaluatedMethod);
								variableValues.push(undefined);
							}
							else if (variable.evaluatedMethod == operators['='] && variable.compiledParams.length == 2 && variable.compiledParams[1] is CompiledConstant)
							{
								// local variable assignment
								variableNames.push(variable.evaluatedParams[0]);
								variableValues.push(variable.evaluatedParams[1]);
							}
							else
								throwInvalidSyntax(FUNCTION);
						}
						var functionParams:Object = {};
						functionParams[FUNCTION_PARAM_NAMES] = variableNames;
						functionParams[FUNCTION_PARAM_VALUES] = variableValues;
						functionParams[FUNCTION_CODE] = finalize(tokens[open]);
						call = compileOperator(FUNCTION, [new CompiledConstant(null, functionParams)]);
						call.originalTokens = tokens.splice(open - 2, 3, call);
						continue;
					}
					
					continue;
				}
				
				var separator:String = ',';
				if (leftBracket == '(' && statements.hasOwnProperty(token) && statements[token])
					separator = ';'; // statement parameters are separated by ';'
				compiledParams = compileArray(subArray, separator);

				if (leftBracket == '[') // this is either an array or a property access
				{
					if (compiledToken)
					{
						// property access
						if (compiledParams.length == 0)
							throw new Error("Missing parameter for bracket operator: " + decompileObject(compiledToken) + "[]");
						// the token on the left becomes the first parameter of the access operator
						compiledParams.unshift(compiledToken);
						// replace the token to the left and the brackets with the operator call
						tokens.splice(open - 1, 3, compileOperator('.', compiledParams));
					}
					else
					{
						// array initialization -- replace '[' and ']' tokens
						tokens.splice(open, 2, compileOperator('[', compiledParams));
					}
					continue;
				}
				
				if (leftBracket == '(' && compiledToken) // if there is a compiled token to the left, this is a function call
				{
					if (open >= 2)
					{
						var prevToken:Object = tokens[open - 2];
						if (prevToken == OPERATOR_NEW)
						{
							compiledParams.unshift(compiledToken);
							tokens.splice(open - 2, 4, compileOperator(OPERATOR_NEW, compiledParams));
							continue;
						}
					}
					if (debug)
						trace("compiling function call", decompileObject(compiledToken));
					
					// the token to the left is the method
					// replace the function token, '(', and ')' tokens with a compiled function call
					tokens.splice(open - 1, 3, new CompiledFunctionCall(compiledToken, compiledParams));
					continue;
				}
				
				// '{' or '(' group that does not correspond to a function call
				
				if (leftBracket == '(' && compiledParams.length == 0 && token != FUNCTION)
					throw new Error("Missing expression inside parentheses");
				
				if (leftBracket == '(' && statements.hasOwnProperty(token) && statements[token])
					separator = '('; // statement params
				tokens.splice(open, 2, compileOperator(separator, compiledParams));
			}
		}
		
		/**
		 * This function will compile a list of expressions separated by ',' or ';' tokens.
		 * @param tokens
		 * @return 
		 */
		private function compileArray(tokens:Array, separator:String):Array
		{
			// avoid compiling an empty set of tokens
			if (tokens.length == 0)
				return [];
			
			var compiledObjects:Array = [];
			while (true)
			{
				var index:int = tokens.indexOf(separator);
				if (index >= 0)
				{
					// compile the tokens before the comma as a parameter
					if (index == 0 && separator == ',')
						throw new Error("Expecting expression before comma");
					compiledObjects.push(compileTokens(tokens.splice(0, index), separator == ';'));
					tokens.shift(); // remove comma
				}
				else
				{
					if (tokens.length == 0 && separator == ',')
						throw new Error("Expecting expression after comma");
					// compile remaining group of tokens as a parameter
					compiledObjects.push(compileTokens(tokens, separator == ';'));
					break;
				}
			}
			return compiledObjects;
		}

		/**
		 * This function is for internal use only.
		 * This function is necessary because variableName needs to be a new Flash variable each time a wrapper function is created.
		 * @param variableName The name of the variable to get when the resulting wrapper function is evaluated.
		 * @param A CompiledFunctionCall for getting the variable.
		 * @return If the variable name is valid, returns an ICompiledObject.  If not valid, the same variableName String is returned.
		 */
		private function compileVariable(variableName:String):Object
		{
			// do not treat statement keywords as variable names
			if (statements.hasOwnProperty(variableName) || operators.hasOwnProperty(variableName))
				return variableName;
			return new CompiledFunctionCall(new CompiledConstant(variableName, variableName), null); // params are null as a special case
		}
		
		private function newTrueConstant():CompiledConstant
		{
			return new CompiledConstant('true', true);
		}
		
		private function newUndefinedConstant():CompiledConstant
		{
			return new CompiledConstant('undefined', undefined);
		}
		
		private function compilePostfixOperators(compiledTokens:Array, operatorSymbols:Array):void
		{
			for (var i:int = 1; i < compiledTokens.length; i++)
			{
				var op:String = compiledTokens[i] as String;
				if (operatorSymbols.indexOf(op) < 0)
					continue;
				
				var call:CompiledFunctionCall = compiledTokens[i - 1] as CompiledFunctionCall;
				if (!call)
					continue;
				
				if (!call.compiledParams) // variable lookup
				{
					// 2 parameters for assignment/postfix operator means local variable assignment
					// last parameter is ignored but required for postfix operator
					compiledTokens.splice(--i, 2, compileOperator('#' + op, [call.compiledMethod, newUndefinedConstant()]));
					continue;
				}
				else if (call.evaluatedMethod == operators['.'])
				{
					// switch to the postfix operator
					// last parameter is ignored but required for postfix operator
					call.compiledParams.push(newUndefinedConstant());
					compiledTokens.splice(--i, 2, compileOperator('#' + op, call.compiledParams));
					continue;
				}
			}
		}
		
		/**
		 * This function is for internal use only.
		 * This will compile unary operators of the given type from right to left.
		 * @param compiledTokens An Array of compiled tokens for an expression.  No '(' ')' or ',' tokens should appear in this Array except when compiling '#' operator.
		 * @param operatorSymbols An Array containing all the infix operator symbols to compile.
		 */
		private function compileUnaryOperators(compiledTokens:Array, operatorSymbols:Array):void
		{
			var call:CompiledFunctionCall;
			var index:int = compiledTokens.length;
			while (index--) // right to left
			{
				var token:String = compiledTokens[index] as String;
				
				// skip tokens that are not listed unary operators
				if (operatorSymbols.indexOf(token) < 0)
					continue;
				
				var nextToken:* = compiledTokens[index + 1];
				
				if (token == '#')
				{
					// do not compile unary '#' if immediately followed by an uncompiled operator
					if (operators.hasOwnProperty(nextToken))
						continue;
					
					if (nextToken !== undefined)
						nextToken = compileTokens([nextToken], false);
				}
				
				// fail when next token is not a compiled object, unless we're compiling '#'
				if ((nextToken === undefined && token != '#') || nextToken is String)
					throw new Error("Misplaced unary operator '" + token + "'");
				
				// skip infix operator
				if (index > 0 && compiledTokens[index - 1] is ICompiledObject)
				{
					call = compiledTokens[index - 1] as CompiledFunctionCall;
					if (!call || call.evaluatedMethod != operators[';'])
						continue;
				}
				
				// compile unary operator
				if (debug)
					trace("compile unary operator", compiledTokens.slice(index, index + 2).join(' '));
				
				if (assignmentOperators.hasOwnProperty(token)) // unary assignment operators
				{
					call = nextToken as CompiledFunctionCall;
					if (call && !call.compiledParams) // variable lookup
					{
						compiledTokens.splice(index, 2, compileOperator(token, [call.compiledMethod, newUndefinedConstant()]));
					}
					else if (call && call.evaluatedMethod == operators['.'])
					{
						// switch '.' to the unary assignment operator
						call.compiledParams.push(newUndefinedConstant());
						compiledTokens.splice(index, 2, compileOperator(token, call.compiledParams));
					}
					else
					{
						throw new Error("Invalid operand for unary operator " + token);
					}
				}
				else
				{
					compiledTokens.splice(index, 2, compileOperator(token, nextToken === undefined ? [] : [nextToken]));
				}
			}
		}
		
		/**
		 * This function is for internal use only.
		 * This will compile infix operators of the given type from left to right.
		 * @param compiledTokens An Array of compiled tokens for an expression.  No '(' ')' or ',' tokens should appear in this Array.
		 * @param operatorSymbols An Array containing all the infix operator symbols to compile.
		 */
		private function compileInfixOperators(compiledTokens:Array, operatorSymbols:Array):void
		{
			var index:int = 0;
			while (index < compiledTokens.length)
			{
				// skip tokens that are not in the list of infix operators
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
					compileUnaryOperators(rhs, unaryOperatorSymbols);
					if (rhs.length != 1)
						throw new Error("Unable to parse second parameter of infix operator '" + compiledTokens[index] + "'");
					compiledTokens.splice(index + 1, 0, rhs[0]);
				}
				
				// stop if infix operator does not have compiled objects on either side
				if (index == 0 || index + 1 == compiledTokens.length || compiledTokens[index - 1] is String || compiledTokens[index + 1] is String)
					throw new Error("Misplaced infix operator '" + compiledTokens[index] + "'");
				
				// replace the tokens for this infix operator call with the compiled operator call
				if (debug)
					trace("compile infix operator", compiledTokens.slice(index - 1, index + 2).join(' '));
				
				// special case for comma - simplify multiple commas into one operator ',' call
				var call:CompiledFunctionCall = compiledTokens[index - 1] as CompiledFunctionCall;
				if (compiledTokens[index] == ',' && call && call.evaluatedMethod == operators[','])
				{
					// append next parameter to existing ',' operator call
					call.compiledParams.push(compiledTokens[index + 1]);
					call.evaluateConstants(); // must be called after modifying compiledParams
					compiledTokens.splice(index, 2); // remove the comma and the next token
				}
				else
				{
					// replace three tokens "lhs op rhs" with one CompiledFunctionCall "\op(lhs,rhs)"
					compiledTokens.splice(index - 1, 3, compileOperator(compiledTokens[index], [compiledTokens[index - 1], compiledTokens[index + 1]]));
				}
			}
		}
		
		/**
		 * @param operatorName
		 * @param compiledParams
		 * @return 
		 */
		private function compileOperator(operatorName:String, compiledParams:Array):CompiledFunctionCall
		{
			operatorName = OPERATOR_ESCAPE + operatorName;
			return new CompiledFunctionCall(new CompiledConstant(operatorName, constants[operatorName]), compiledParams);
		}
		
		private function compileVariableAssignment(variableToken:*, assignmentOperator:String, valueToken:*):CompiledFunctionCall
		{
			var lhs:CompiledFunctionCall = variableToken as CompiledFunctionCall;
			var rhs:ICompiledObject = valueToken as ICompiledObject;

			if (!rhs)
				throw new Error("Invalid right-hand-side of '" + assignmentOperator + "': " + (valueToken as String || decompileObject(valueToken)));
			
			// lhs should either be a variable lookup or a call to operator '.'
			if (lhs && !lhs.compiledParams) // lhs is a variable lookup
			{
				return compileOperator(assignmentOperator, [lhs.compiledMethod, rhs]);
			}
			else if (lhs && lhs.evaluatedMethod == operators['.'])
			{
				// switch to the assignment operator
				lhs.compiledParams.push(rhs);
				return compileOperator(assignmentOperator, lhs.compiledParams);
			}
			else
				throw new Error("Invalid left-hand-side of '" + assignmentOperator + "': " + (variableToken as String || decompileObject(variableToken)));
		}
		
		/**
		 * This function assumes that every token except statements have already been compiled.
		 * @param tokens
		 * @param startIndex The index of the first token to compile
		 */
		private function compileStatement(tokens:Array, startIndex:int):void
		{
			var stmt:String = tokens[startIndex] as String;
			var call:CompiledFunctionCall;
			
			// stop if tokens does not start with a statement
			if (!statements.hasOwnProperty(stmt))
			{
				// complain about missing ';' after non-statement except for last token
				if (startIndex < tokens.length - 1)
				{
					call = tokens[startIndex] as CompiledFunctionCall;
					if (!call || (call.evaluatedMethod != operators[';'] && !tokenIsStatement(call)))
					{
						if (stmt)
							throw new Error("Unexpected " + stmt);
						var next:Object = tokens[startIndex + 1];
						if (next is ICompiledObject)
							next = decompileObject(next as ICompiledObject);
						throw new Error("Missing ';' before " + next);
					}
				}
				return;
			}
			
			var varNames:Array;
			
			// find a matching statement pattern
			nextPattern: for each (var pattern:Array in _validStatementPatterns)
			{
				for (var iPattern:int = 0; iPattern < pattern.length; iPattern++)
				{
					if (startIndex + iPattern >= tokens.length)
						continue nextPattern;
					
					var type:String = pattern[iPattern];
					var token:Object = tokens[startIndex + iPattern];
					call = token as CompiledFunctionCall;
					
					if (statements.hasOwnProperty(type) && token != type)
						continue nextPattern;
					
					if (type == PN_PARAMS)
						continue; // params have already been verified
					
					// if we get past a statement and its params, if compiling something fails we don't need to check any more patterns
					
					if (type == PN_EXPR) // non-statement
					{
						if (tokenIsStatement(token))
							throw new Error('Unexpected ' + token);
						if (call && call.evaluatedMethod == operators[';'] && call.compiledParams.length > 1)
							throwInvalidSyntax(stmt);
					}
					
					if (type == PN_STMT)
					{
						compileStatement(tokens, startIndex + iPattern);
					}
					
					if (type == PN_BLOCK)
					{
						if (!call || call.evaluatedMethod != operators[';'])
							throwInvalidSyntax(stmt);
					}
					
					if (type == PN_VARS)
					{
						// must be function call
						if (tokenIsStatement(token) || !call)
							throwInvalidSyntax(stmt);
						
						// must be local variable/assignment or list of local variables/assignments
						
						// special case for "y, x = 3;" which at this point is stored as {y, x = 3}
						if (call.evaluatedMethod == operators[';'])
						{
							if (call.evaluatedParams.length != 1 || !(call.compiledParams[0] is CompiledFunctionCall))
								throwInvalidSyntax(stmt);
							// remove the operator ';' wrapper
							tokens[startIndex + iPattern] = token = call = call.compiledParams[0];
						}
						
						// if there is only a single variable, wrap it in an operator ',' call
						if (!call.compiledParams || call.evaluatedMethod == operators['='])
							tokens[startIndex + iPattern] = token = call = compileOperator(',', [call]);
						
						// special case for "for (var x in y) { }"
						if (call.evaluatedMethod == operators['in'] && call.compiledParams.length == 2)
						{
							// check the variable
							call = call.compiledParams[0] as CompiledFunctionCall;
							if (!call || call.compiledParams) // not a variable?
								throwInvalidSyntax(stmt);
							// save single variable name
							varNames = [call.evaluatedMethod];
							continue;
						}
						
						if (call.evaluatedMethod != operators[','] || call.compiledParams.length == 0)
							throwInvalidSyntax(stmt);
						
						varNames = [];
						for (var iParam:int = 0; iParam < call.compiledParams.length; iParam++)
						{
							var variable:CompiledFunctionCall = call.compiledParams[iParam] as CompiledFunctionCall;
							if (!variable)
								throwInvalidSyntax(stmt);
							
							if (!variable.compiledParams) // local initialization
							{
								// variable initialization only -- remove from ',' params
								call.compiledParams.splice(iParam--, 1);
								varNames.push(variable.evaluatedMethod);
							}
							else if (variable.evaluatedMethod == operators['='] && variable.compiledParams.length == 2) // local assignment
							{
								varNames.push(variable.evaluatedParams[0]);
							}
							else
								throwInvalidSyntax(stmt);
						}
						call.evaluateConstants();
					}
				}
				
				// found matching pattern
				var originalTokens:Array = tokens.slice(startIndex, startIndex + pattern.length);
				var params:Array = tokens.splice(startIndex + 1, pattern.length - 1);
				
				if (stmt == ST_VAR)
				{
					token = compileOperator(ST_VAR, [new CompiledConstant(null, varNames)]);
					call = params[0];
					if (call.evaluatedMethod == operators['in'])
					{
						call.compiledParams[0] = compileOperator(',', [token, call.compiledParams[0]]);
						call.evaluateConstants();
						token = call;
					}
					else if (call.compiledParams.length > 0)
					{
						call.compiledParams.unshift(token);
						call.evaluateConstants();
						token = call;
					}
					originalTokens = null; // avoid infinite decompile recursion
					tokens[startIndex] = token;
				}
				else if (stmt == ST_IMPORT)
				{
					originalTokens = null;
					
					// support multiple imports separated by commas
					if ((call = params[0] as CompiledFunctionCall) && call.evaluatedMethod == operators[';'] && call.compiledParams.length == 1)
						params[0] = call.compiledParams[0];
					if ((call = params[0] as CompiledFunctionCall) && call.evaluatedMethod == operators[','])
						params = call.compiledParams;
					
					for (var i:int = 0; i < params.length; i++)
					{
						var _lib:CompiledConstant = params[i] as CompiledConstant;
						if (_lib && _lib.value is String)
						{
							try
							{
								var def:Object = getDefinitionByName(_lib.value);
								if (def is Class)
									_lib.value = def;
							}
							catch (e:Error)
							{
								/*e.message = 'import ' + decompileObject(_lib) + '\n' + e.message;
								throw e;*/
								// ignore compile-time error, hoping it will work at run-time
							}
						}
					}
					tokens[startIndex] = compileOperator(ST_IMPORT, params);
				}
				else if (stmt == ST_IF) // if (cond) {stmt} else {stmt}
				{
					// implemented as "cond ? true_stmt : false_stmt"
					params.splice(2, 1); // works whether or not else is present
					tokens[startIndex] = compileOperator(ST_IF, params);
				}
				else if (stmt == ST_DO) // do {stmt} while (cond);
				{
					// implemented as "while (cond && (stmt, true))" with first evaluation of 'cond' skipped
					params = [params[2], compileOperator(',', [params[0], newTrueConstant()])];
					tokens[startIndex] = compileOperator(ST_DO, params);
				}
				else if (stmt == ST_WHILE) // while (cond) {stmt}
				{
					// implemented as "while (cond && (stmt, true));"
					params[1] = compileOperator(',', [params[1], newTrueConstant()]);
					tokens[startIndex] = compileOperator(ST_WHILE, params);
				}
				else if (stmt == ST_FOR || stmt == ST_FOR_EACH) // for (params) {stmt}
				{
					var forParams:CompiledFunctionCall = params[0]; // statement params wrapper
					if (forParams.compiledParams.length == 3) // for (init; cond; inc) {stmt}
					{
						// implemented as "(init, cond) && while((inc, cond) && (stmt, true))" with first evaluation of "(inc, cond)" skipped
						
						var _init:ICompiledObject = forParams.compiledParams[0];
						var _cond:ICompiledObject = forParams.compiledParams[1];
						var _inc:ICompiledObject = forParams.compiledParams[2];
						
						var _init_cond:ICompiledObject = compileOperator(',', [_init, _cond]);
						var _inc_cond:ICompiledObject = compileOperator(',', [_inc, _cond]);
						var _stmt_true:ICompiledObject = compileOperator(',', [params[1], newTrueConstant()]);
						var _forDo:ICompiledObject = compileOperator(ST_FOR_DO, [_inc_cond, _stmt_true]);
						
						tokens[startIndex] = compileOperator(ST_FOR, [_init_cond, _forDo]);
					}
					else // for [each] (item in list) {stmt}
					{
						// differentiate from 'for' with 3 statement params
						if (stmt == ST_FOR)
							stmt = ST_FOR_IN;
						
						// implemented as "for (each|in)(\in(list), item=undefined, stmt)
						var _in:CompiledFunctionCall = forParams.compiledParams[0];
						var _item:ICompiledObject;
						var _var:CompiledFunctionCall = _in.compiledParams[0] as CompiledFunctionCall;
						if (_var.evaluatedMethod == operators[','] && _var.compiledParams.length == 2) // represented as (var x, x)
						{
							_var.compiledParams[1] = compileVariableAssignment(_var.compiledParams[1], '=', newUndefinedConstant());
						}
						else
						{
							_var = compileVariableAssignment(_in.compiledParams[0], '=', newUndefinedConstant());
						}
						var _list:ICompiledObject = compileOperator('in', [_in.compiledParams[1]]);
						tokens[startIndex] = compileOperator(stmt, [_list, _var, params[1]]);
					}
				}
				else if (_jumpStatements.indexOf(stmt) >= 0)
				{
					tokens[startIndex] = compileOperator(stmt, params);
				}
				else
				{
					throw new Error(stmt + " not supported");
				}
				
				// save original token list for correct decompiling
				(tokens[startIndex] as CompiledFunctionCall).originalTokens = originalTokens;
				
				return;
			}
			
			// no matching pattern found
			throwInvalidSyntax(stmt);
		}
		
		private function assertValidStatementParams(tokens:Array):void
		{
			for (var index:int = 0; index < tokens.length; index++)
			{
				var statement:String = tokens[index] as String;
				if (statements[statement]) // requires parameters?
				{
					// statement parameters must be wrapped in operator ';' call
					var params:CompiledFunctionCall = tokens[index + 1] as CompiledFunctionCall;
					if (!params || params.evaluatedMethod != operators['('])
						throwInvalidSyntax(statement);
					
					var cpl:int = params.compiledParams.length;
					
					// 'for' can have 3 statement params
					if (statement == ST_FOR && cpl == 3)
						continue;
					
					// all other statements must have only one param
					if (cpl != 1)
						throwInvalidSyntax(statement);
					
					if (statement == ST_FOR || statement == ST_FOR_EACH)
					{
						// if 'for' or 'for each' has only one param, it must be the 'in' operator
						var call:CompiledFunctionCall = params.compiledParams[0] as CompiledFunctionCall; // the first statement param
						if (!call || call.evaluatedMethod != operators['in'] || call.compiledParams.length != 2)
							throwInvalidSyntax(statement);
						
						// check the first parameter of the 'in' operator
						call = call.compiledParams[0] as CompiledFunctionCall;
						
						if (call.evaluatedMethod == operators[','] && call.compiledParams.length == 2)
						{
							var _var:CompiledFunctionCall = call.compiledParams[0] as CompiledFunctionCall;
							if (!_var || _var.evaluatedMethod != operators[ST_VAR])
								throwInvalidSyntax(statement);
							call = call.compiledParams[1]; // should be the variable
						}
							
						// the 'in' operator must have a variable or property reference as its first parameter
						if (!(call.compiledParams == null || call.evaluatedMethod == operators['.'])) // not a variable and not a property
							throwInvalidSyntax(statement);
					}
					
				}
			}
		}
		
		private function throwInvalidSyntax(statement:String):void
		{
			throw new Error("Invalid '" + statement + "' syntax");
		}
		
		private function tokenIsStatement(token:Object):Boolean
		{
			var call:CompiledFunctionCall = token as CompiledFunctionCall;
			if (!call)
				return statements.hasOwnProperty(token);
			
			var method:* = call.evaluatedMethod;
			return (JUMP_LOOKUP[method] || LOOP_LOOKUP[method])
		}
		
		/**
		 * Call this to move all var declarations at the beginning of the code and perform optimizations on the compiled objects.
		 * @param compiledObject An ICompiledObject to finalize.
		 * @return A finialized/optimized version of compiledObject.
		 */
		private function finalize(compiledObject:ICompiledObject):ICompiledObject
		{
			var varLookup:Object = {};
			
			var final:ICompiledObject = _finalize(compiledObject, varLookup);
			if (!final)
				return compiledObject;
			
			compiledObject = final;
			
			var names:Array = [];
			for (var name:String in varLookup)
				names.push(name);
			
			if (names.length > 0)
			{
				// there is at least one var declaration, so we need to include it at the beginning.
				var varDeclarations:CompiledFunctionCall = compileOperator(ST_VAR, [new CompiledConstant(null, names)]);
				var call:CompiledFunctionCall = compiledObject as CompiledFunctionCall
				if (call && call.evaluatedMethod == operators[';'])
				{
					call.compiledParams.unshift(varDeclarations);
					call.evaluateConstants();
				}
				else
					compiledObject = compileOperator(';', [varDeclarations, compiledObject]);
			}
			return compiledObject;
		}
		/**
		 * @private helper function
		 */
		private function _finalize(compiledObject:ICompiledObject, varLookup:Object):ICompiledObject
		{
			if (compiledObject is CompiledConstant)
				return compiledObject;
			
			var i:int;
			var call:CompiledFunctionCall = compiledObject as CompiledFunctionCall;
			call.compiledMethod = _finalize(call.compiledMethod, varLookup);
			if (!call.compiledMethod)
				throw new Error("Misplaced variable declaration");
			var params:Array = call.compiledParams;
			if (params)
			{
				for (i = 0; i < params.length; i++)
				{
					params[i] = _finalize(params[i], varLookup);
					if (params[i] == null) // variable declaration eliminated?
						params.splice(i--, 1);
				}
			}
			call.evaluateConstants();
			
			var method:Object = call.evaluatedMethod;
			
			// remove var declarations from their current locations
			if (method == operators[ST_VAR])
			{
				for each (var name:String in call.evaluatedParams[0])
					varLookup[name] = true;
				return null;
			}
			
			if (method == operators[';'] || method == operators[','] || method == operators['('])
			{
				if (params.length == 0)
				{
					if (debug)
						trace('optimized empty expression to undefined constant:',decompileObject(compiledObject));
					return newUndefinedConstant();
				}
				if (params.length == 1)
				{
					if (debug)
						trace('optimized unnecessary wrapper function call:',decompileObject(compiledObject));
					return _finalize(params[0], varLookup);
				}
				
				// flatten nested grouping operators
				i = params.length;
				while (i--)
				{
					var nestedCall:CompiledFunctionCall = params[i] as CompiledFunctionCall;
					if (!nestedCall)
						continue;
					var nestedMethod:Object = nestedCall.evaluatedMethod;
					if (nestedMethod == operators[';'] || nestedMethod == operators[','] || nestedMethod == operators['('])
					{
						if (debug)
							trace('flattened nested grouped expressions:',decompileObject(nestedCall));
						nestedCall.compiledParams.unshift(i, 1);
						params.splice.apply(null, nestedCall.compiledParams);
					}
				}
				call.evaluateConstants();
			}
			
			if ((method == operators[ST_IF] || method == operators['?:']) && params[INDEX_CONDITION] is CompiledConstant)
			{
				if (debug)
					trace('optimized short-circuited ?: operator:',decompileObject(compiledObject));
				
				var index:int = call.evaluatedParams[INDEX_CONDITION] ? INDEX_TRUE : INDEX_FALSE;
				return index < params.length ? params[index] : newUndefinedConstant();
			}
			
			if (method == operators['&&'] && params.length == 2 && params[INDEX_CONDITION] is CompiledConstant && !call.evaluatedParams[INDEX_CONDITION])
			{
				if (debug)
					trace('optimized short-circuited && operator:',decompileObject(compiledObject));
				return params[INDEX_CONDITION];
			}
			
			if (method == operators['||'] && params.length == 2 && params[INDEX_CONDITION] is CompiledConstant && call.evaluatedParams[INDEX_CONDITION])
			{
				if (debug)
					trace('optimized short-circuited || operator:',decompileObject(compiledObject));
				return params[INDEX_CONDITION];
			}
			
			if (PURE_OP_LOOKUP[method])
			{
				// if all parameters are constants, just evaluate the pure operator as a constant.
				for each (var param:Object in params)
					if (!(param is CompiledConstant))
						return call; // cannot be optimized
					
				if (debug)
					trace('optimized pure operator call to constant:',decompileObject(compiledObject));
				return new CompiledConstant(decompileObject(call), (method as Function).apply(null, call.evaluatedParams));
			}
			
			return call;
		}
		
		/**
		 * @param compiledObject A CompiledFunctionCall or CompiledConstant to decompile into an expression String.
		 * @return The expression String generated from the compiledObject.
		 */
		public function decompileObject(compiledObject:ICompiledObject):String
		{
			// special case for constants
			if (compiledObject is CompiledConstant)
				return (compiledObject as CompiledConstant).name;
			
			var i:int;
			var call:CompiledFunctionCall = compiledObject as CompiledFunctionCall;
			
			// if originalTokens is specified, decompile those instead.
			if (call.originalTokens)
			{
				var tokens:Array = call.originalTokens.concat();
				for (i = 0; i < tokens.length; i++)
					if (tokens[i] is ICompiledObject)
						tokens[i] = decompileObject(tokens[i]);
				return tokens.join(' ');
			}
			
			// special case for variable lookup
			if (!call.compiledParams)
				return decompileObject(call.compiledMethod);
			
			var cMethod:CompiledConstant = call.compiledMethod as CompiledConstant
			var cParams:Array = call.compiledParams;
			
			// decompile each param
			var params:Array = [];
			for (i = 0; i < cParams.length; i++)
				params[i] = decompileObject(cParams[i]);
			
			var op:String;
			if (cMethod)
			{
				op = cMethod.name;
				if (op.substr(0, OPERATOR_ESCAPE.length) == OPERATOR_ESCAPE)
					op = op.substr(OPERATOR_ESCAPE.length);
			}
			if (cMethod && constants[cMethod.name] == cMethod.value && operators[op] == cMethod.value)
			{
				var n:int = cParams.length;
				if (n > 0 && (ASSIGN_OP_LOOKUP[cMethod.value] || op == '.' || op == '..'))
				{
					var result:String = params[0];
					for (i = 1; i < n; i++)
					{
						// assignment op has last parameter as right-hand-side value
						if (i == n - 1 && op != '.' && op != '..')
							break;
						// if the evaluated param compiles as a variable, use the '.' syntax
						var constant:CompiledConstant = cParams[i] as CompiledConstant;
						var variable:CompiledFunctionCall = null;
						try {
							variable = compileToObject(constant.value) as CompiledFunctionCall;
							if (variable.compiledParams)
								variable = null;
						} catch (e:Error) { }
						
						if (op == '..')
							result += '.descendants(' + params[i] + ')';
						else if (variable)
							result += '.' + variable.evaluatedMethod;
						else
							result += '[' + params[i] + ']';
					}
					if (op == '.' || op == '..')
						return result;
					if (op == '#++' || op == '#--')
						return result + op.substr(1);
					if (op == '++' || op == '--')
						return op + result;
					if (op == 'delete')
						return op + ' ' + result;
					
					return StandardLib.substitute("({0} {1} {2})", result, op, params[n - 1]); // example:  "(a.b = c)"
				}
				
				// variable number of params
				if (op == '[')
					return '[' + params.join(', ') + ']';
				
				if (op == ';')
					return '{' + params.join('; ') + '}';
				
				if (op == ',' && n > 0) // zero params not allowed for this syntax
					return '(' + params.join(', ') + ')';
				
				if (op == '(' && n > 0) // zero params not allowed for this syntax
					return '(' + params.join('; ') + ')';
				
				if (PURE_OP_LOOKUP[cMethod.value] || op == 'in')
				{
					if (n == 1) // unary op
					{
						var param:String = params[0];
						var c:String = op.charAt(0);
						if (operators.hasOwnProperty(c) && c != param.charAt(0))
							return op + param;
						// need a space between operators with identical characters
						return op + ' ' + param;
					}
					
					if (n == 2) // infix op
						return StandardLib.substitute("({0} {1} {2})", params[0], op, params[1]);
					
					if (n == 3 && op == '?:') // ternary op
						return StandardLib.substitute("({0} ? {1} : {2})", params);
				}
				
				if (op == ST_VAR)
				{
					return ST_VAR + ' ' + ((cParams[0] as CompiledConstant).value as Array).join(', ');
				}
				
				if (op == ST_IMPORT)
					return ST_IMPORT + ' ' + params.join(', ');
			}
			
			// normal function syntax
			return decompileObject(call.compiledMethod) + '(' + params.join(', ') + ')';
		}
		
		/**
		 * This function is for internal use only.
		 * @param compiledObject Either a CompiledConstant or a CompiledFunctionCall.
		 * @param symbolTable This is a lookup table containing custom variables and functions that can be used in the expression. Multiple lookup tables can be specified in an Array. The values in the lookup tables may be changed outside the function after compiling.
		 * @param errorHandler A function that takes an Error and optionally returns true if execution should continue, behaving as if the current instruction returned undefined.  This may be set to null, which will cause the Error to be thrown.
		 * @param useThisScope If this is set to true, properties of 'this' can be accessed as if they were local variables.
		 * @param paramNames This specifies local variable names to be associated with the arguments passed in as parameters to the compiled function.
		 * @param paramDefaults This specifies default values corresponding to the parameter names.  This must be the same length as the paramNames array.
		 * @return A Function that takes any number of parameters and returns the result of evaluating the ICompiledObject.
		 */
		public function compileObjectToFunction(compiledObject:ICompiledObject, symbolTable:Object, errorHandler:Function, useThisScope:Boolean, paramNames:Array = null, paramDefaults:Array = null):Function
		{
			if (compiledObject == null)
				return null;
			if (paramNames)
			{
				if (!paramDefaults)
					paramDefaults = new Array(paramNames.length);
				else if (paramNames.length != paramDefaults.length)
					throw new Error("paramNames and paramDefaults Arrays must have same length");
			}
			
			if (symbolTable == null)
				symbolTable = {};
			
			if (compiledObject is CompiledConstant)
			{
				// create a new variable for the value to avoid the overhead of
				// accessing a member variable of the CompiledConstant object.
				const value:* = (compiledObject as CompiledConstant).value;
				return function(...args):* { return value; };
			}
			
			// create the variables that will be used inside the wrapper function

			const builtInSymbolTable:Object = {};
			builtInSymbolTable['eval'] = undefined;
			
			// set up Array of symbol tables in the correct scope order: built-in, local, params, this, global
			const allSymbolTables:Array = [builtInSymbolTable]; // buit-in first
			const LOCAL_SYMBOL_TABLE_INDEX:int = allSymbolTables.push(null) - 1; // placeholder
			
			// add custom symbol table(s)
			if (symbolTable is Array)
			{
				for each (var _symbolTable:Object in symbolTable)
					allSymbolTables.push(_symbolTable);
			}
			else
			{
				allSymbolTables.push(symbolTable);
			}
			
			// push placeholder for 'this' symbol table
			const THIS_SYMBOL_TABLE_INDEX:int = allSymbolTables.push(null) - 1;
			
			// add libraries in reverse order so the last one will be checked first
			var i:int = libraries.length;
			while (i--)
				allSymbolTables.push(libraries[i]);
			// check globals last
			allSymbolTables.push(globals);
			
			// this function avoids unnecessary function call overhead by keeping its own call stack rather than using recursion.
			var wrapperFunction:Function = function():*
			{
				const stack:Array = []; // used as a queue of function calls
				const localSymbolTable:Object = {};
				var call:CompiledFunctionCall;
				var subCall:CompiledFunctionCall;
				var compiledParams:Array;
				var method:Object;
				var result:*;
				var symbolName:String;
				var i:int;
				var propertyHost:Object;
				var propertyName:String;
				
				allSymbolTables[LOCAL_SYMBOL_TABLE_INDEX] = localSymbolTable;
				if (useThisScope)
					allSymbolTables[THIS_SYMBOL_TABLE_INDEX] = this;
				
				builtInSymbolTable['this'] = this;
				builtInSymbolTable['arguments'] = arguments;
				
				// make function parameters available under the specified parameter names
				if (paramNames)
					for (i = 0; i < paramNames.length; i++)
						localSymbolTable[paramNames[i] as String] = i < arguments.length ? arguments[i] : paramDefaults[i];
				
				// initialize top-level function and push it onto the stack
				call = compiledObject as CompiledFunctionCall;
				call.evalIndex = INDEX_METHOD;
				stack.length = 1;
				stack[0] = call;
				stackLoop: while (true)
				{
					// evaluate the CompiledFunctionCall on top of the stack
					call = stack[stack.length - 1] as CompiledFunctionCall;
					
					// if we got here because of a break, advance evalIndex
					if (method == operators[ST_BREAK])
						call.evalIndex++;
					
					method = call.evaluatedMethod;
					compiledParams = call.compiledParams;
					
					if (compiledParams)
					{
						if (LOOP_LOOKUP[method] && call.evalIndex == INDEX_METHOD)
						{
							if (method == operators[ST_DO] || method == operators[ST_FOR_DO])
							{
								// skip first evaluation of loop condition
								call.evaluatedParams[INDEX_CONDITION] = true;
								call.evalIndex = INDEX_TRUE;
							}
						}
						
						// check which parameters should be evaluated
						for (; call.evalIndex < compiledParams.length; call.evalIndex++)
						{
							//trace(StringLib.lpad('', stack.length, '\t') + "[" + call.evalIndex + "] " + compiledParams[call.evalIndex].name);
							
							// handle branching and short-circuiting
							// skip evaluation of true or false branch depending on condition and branch operator
							if (BRANCH_LOOKUP[method] !== undefined && call.evalIndex > INDEX_CONDITION)
								if (BRANCH_LOOKUP[method] == (call.evalIndex != (call.evaluatedParams[INDEX_CONDITION] ? INDEX_TRUE : INDEX_FALSE)))
									continue;
							
							if (call.evalIndex == INDEX_METHOD)
								subCall = call.compiledMethod as CompiledFunctionCall;
							else
								subCall = compiledParams[call.evalIndex] as CompiledFunctionCall;
							
							if (subCall != null)
							{
								// special case for for-in and for-each
								// implemented as "for (each|in)(\in(list), item=undefined, stmt)
								if (LOOP_LOOKUP[method] && call.evalIndex == INDEX_FOR_ITEM && (method == operators[ST_FOR_IN] || method == operators[ST_FOR_EACH]))
								{
									if ((call.evaluatedParams[INDEX_FOR_LIST] as Array).length > 0)
									{
										// next item
										result = (call.evaluatedParams[INDEX_FOR_LIST] as Array).shift(); // property name
										if (method == operators[ST_FOR_EACH])
										{
											// get property value from property name
											var _in:CompiledFunctionCall = call.compiledParams[INDEX_FOR_LIST] as CompiledFunctionCall;
											result = _in.evaluatedParams[0][result]; // property value
										}
										// set item value
										subCall.evaluatedParams[subCall.evaluatedParams.length - 1] = result;
									}
									else
									{
										// break out of loop
										method = operators[ST_BREAK];
										break;
									}
								}
								
								// initialize subCall and push onto stack
								subCall.evalIndex = INDEX_METHOD;
								stack.push(subCall);
								continue stackLoop;
							}
						}
					}
					// no parameters need to be evaluated, so make the function call now
					try
					{
						// reset _propertyHost and _propertyName prior to method apply in case we are calling operator '.'
						propertyHost = _propertyHost = null;
						propertyName = _propertyName = null;
						
						if (!compiledParams) // no compiled params means it's a variable lookup
						{
							// call.compiledMethod is a constant and call.evaluatedMethod is the method name
							symbolName = method as String;
							// find the variable
							for (i = 0; i < allSymbolTables.length; i++) // max i after loop will be length
							{
								if (allSymbolTables[i] && allSymbolTables[i].hasOwnProperty(symbolName))
								{
									if (i == THIS_SYMBOL_TABLE_INDEX || allSymbolTables[i] is Proxy)
									{
										propertyHost = allSymbolTables[i];
										propertyName = symbolName;
									}
									result = allSymbolTables[i][symbolName];
									break;
								}
							}
							
							if (i == allSymbolTables.length)
								result = getDefinitionByName(symbolName);
						}
						else if (JUMP_LOOKUP[method])
						{
							if (method == operators[ST_RETURN])
							{
								return compiledParams.length ? call.evaluatedParams[0] : undefined;
							}
							else if (method == operators[ST_CONTINUE])
							{
								while (true)
								{
									stack.pop();
									if (stack.length == 0)
										return result; // executing continue at top level of script
									
									call = stack[stack.length - 1] as CompiledFunctionCall;
									method = call.evaluatedMethod;
									if (LOOP_LOOKUP[method] && LOOP_LOOKUP[method] != ST_BREAK)
										break; // loop will be handled below.
								}
							}
							else if (method == operators[ST_BREAK])
							{
								while (stack.length > 1)
								{
									call = stack.pop() as CompiledFunctionCall;
									method = call.evaluatedMethod;
									if (LOOP_LOOKUP[method] && LOOP_LOOKUP[method] != ST_CONTINUE)
									{
										method = operators[ST_BREAK];
										continue stackLoop;
									}
								}
								return result; // executing break at top level
							}
							else if (method == operators[ST_THROW])
							{
								//TODO - find try/catch/finally
								throw call.evaluatedParams[0];
							}
						}
						else if (ASSIGN_OP_LOOKUP[method] && compiledParams.length == 2) // two params means local assignment
						{
							// local assignment
							symbolName = call.evaluatedParams[0];
							if (builtInSymbolTable.hasOwnProperty(symbolName))
								throw new Error("Cannot assign built-in symbol: " + symbolName);
							
							// find the most local symbol table that has the variable
							for (i = LOCAL_SYMBOL_TABLE_INDEX; i <= THIS_SYMBOL_TABLE_INDEX; i++)
								if (allSymbolTables[i] && allSymbolTables[i].hasOwnProperty(symbolName))
									break;
							// if no symbol table has the variable, create a new local variable
							if (i > THIS_SYMBOL_TABLE_INDEX)
								i = LOCAL_SYMBOL_TABLE_INDEX;
							
							// assignment operator expects parameters like (host, ...chain, value)
							result = method(allSymbolTables[i], symbolName, call.evaluatedParams[1]);
						}
						else if (method == operators[ST_IMPORT])
						{
							for each (result in call.evaluatedParams)
							{
								symbolName = result as String;
								if (symbolName)
									result = getDefinitionByName(result);
								else if (!(result is Class))
									throw new Error("Unable to import non-Class: " + decompileObject(call));
								
								if (!symbolName)
									symbolName = getQualifiedClassName(result);
								
								symbolName = symbolName.substr(Math.max(symbolName.lastIndexOf('.'), symbolName.lastIndexOf(':')) + 1);
								allSymbolTables[LOCAL_SYMBOL_TABLE_INDEX][symbolName] = result;
							}
						}
						else if (method is Class)
						{
							// type casting
							if (method == Array) // special case for Array
							{
								result = call.evaluatedParams.concat();
							}
							else if (call.evaluatedParams.length != 1)
							{
								// special case for Object('prop1', value1, ...)
								if (method === Object)
								{
									var params:Array = call.evaluatedParams;
									result = {}
									for (i = 0; i < params.length - 1; i += 2)
										result[params[i]] = params[i + 1];
								}
								else
									throw new Error("Incorrect number of arguments for type casting.  Expected 1.");
							}
							// special case for Class('some.qualified.ClassName')
							else if (method === Class && call.evaluatedParams[0] is String)
							{
								result = getDefinitionByName(call.evaluatedParams[0]);
							}
							else // all other single-parameter type casting operations
							{
								result = method(call.evaluatedParams[0]);
							}
						}
						else if (method == operators[ST_VAR]) // variable initialization
						{
							for each (result in call.evaluatedParams[0])
								if (!localSymbolTable.hasOwnProperty(result))
									localSymbolTable[result] = undefined;
							result = undefined;
						}
						else if (method == operators[FUNCTION]) // inline function definition
						{
							var _symbolTables:Array = [localSymbolTable].concat(symbolTable); // works whether symbolTable is an Array or Object
							if (useThisScope)
								_symbolTables.push(this);
							
							var funcParams:Object = call.evaluatedParams[0];
							result = compileObjectToFunction(
								funcParams[FUNCTION_CODE],
								_symbolTables,
								errorHandler,
								useThisScope,
								funcParams[FUNCTION_PARAM_NAMES],
								funcParams[FUNCTION_PARAM_VALUES]
							);
						}
						else if (call.evaluatedHost is Proxy)
						{
							// use Proxy.flash_proxy::callProperty
							var proxyParams:Array = call.evaluatedParams.concat();
							proxyParams.unshift(call.evaluatedMethodName);
							result = (call.evaluatedHost as Proxy).flash_proxy::callProperty.apply(call.evaluatedHost, proxyParams);
						}
						else
						{
							// normal function call
							result = method.apply(call.evaluatedHost, call.evaluatedParams);
							propertyHost = _propertyHost;
							propertyName = _propertyName;
						}
					}
					catch (e:*)
					{
						var decompiled:String = decompileObject(call);
						var err:Error = e as Error;
						if (err)
						{
							fixErrorMessage(err);
							err.message = decompiled + '\n' + err.message;
						}
						else
							trace(decompiled);
						
						if (errorHandler == null)
							throw e;
						
						if (errorHandler(e))
							result = undefined; // ignore and continue
						else
							return undefined; // halt
					}
					
					// handle while and for loops
					if (LOOP_LOOKUP[method])
					{
						if (method == operators[ST_FOR_IN] || method == operators[ST_FOR_EACH])
						{
							// skip evaluation of list to avoid infinite loop
							call.evalIndex = INDEX_FOR_ITEM;
							continue;
						}
						else if (result)
						{
							// skip evaluation of method to avoid infinite 'do' loop
							call.evalIndex = INDEX_METHOD + 1;
							continue;
						}
					}
					
					// remove this call from the stack
					stack.pop();
					// if there is no parent function call, return the result
					if (stack.length == 0)
						return result;
					// otherwise, store the result in the evaluatedParams array of the parent call
					call = stack[stack.length - 1] as CompiledFunctionCall;
					if (call.evalIndex == INDEX_METHOD)
					{ 
						call.evaluatedHost = propertyHost;
						call.evaluatedMethodName = propertyName;
						call.evaluatedMethod = result;
					}
					else
						call.evaluatedParams[call.evalIndex] = result;
					// advance the evalIndex so the next parameter will be evaluated.
					call.evalIndex++;
				}
				throw new Error("unreachable");
			};
			
			// if the compiled object is a function definition, return that function definition instead of the wrapper.
			if (compiledObjectIsFunctionDefinition(compiledObject))
				return wrapperFunction() as Function;
			
			return wrapperFunction;
		}
		
		/**
		 * This will check if the compiled object is a function definition.
		 * @param compiledObject A compiled object returned by compileToObject().
		 * @return true if the compiledObject is a function definition.
		 */		
		public function compiledObjectIsFunctionDefinition(compiledObject:ICompiledObject):Boolean
		{
			return compiledObject is CompiledFunctionCall && (compiledObject as CompiledFunctionCall).evaluatedMethod == operators[FUNCTION];
		}

		public static const _do_continue_test:String = <![CDATA[
			var test = true;
			do
			{
				if (test)
				{
					trace('do');
					test = false;
					continue;
				}
				trace('done');
				break;
			}
			while (trace('condition'), true);
		]]>;

		
		//-----------------------------------------------------------------
		// Class('weave.compiler.Compiler').test()
		public static function test():void
		{
			var compiler:Compiler = new Compiler();
			var eqs:Array = [
				"(a = 1, 0) ? (a = 2, a + 1) : (4, a + 100), a",
				"1 + '\"abc ' + \"'x\\\"y\\\\\\'z\"",
				'0 ? trace("?: BUG") : -v',
				'1 ? ~-~-v : trace("?: BUG")',
				'!true && trace("&& BUG")',
				'true || trace("|| BUG")',
				'round(.5 - random() < 0 ? "1.6" : "1.4")',
				'(- x * 3) / get("v") + -2 + pow(5,3) +\\**(6,3)',
				'\\+ ( - ( - 2 + 1 ) ** - 4 , - 3 ) - ( - 4 + - 1 * - 7 )',
				'-v- - -3+v2',
				'(x + v) / \\+ ( - ( 2 + 1 ) ** 4 , 3 ) - ( 4 + 1 )',
				'3',
				'-3',
				'v',
				'-v',
				'roundSignificant(random(),3)',
				'rpad("hello", 4+(v+2)*2, "._,")',
				'lpad("hello", 4+(v+2)*2, "._,")',
				'"hello world".substr(v*2, 5)',
				'asString(random()).length',
				'"(0x" + numberToBase(0xFF00FF,16).toUpperCase() + ") " + lpad(numberToBase(v*20, 2, 4), 9) + ", base10: " + rpad(numberToBase(sign(v) * (v+10),10,3), 6) + ", base16: " + numberToBase(v+10,16)',
				'if (false) { trace(3) } else trace(4)',
				'do {} while (random());',
				'if (random()) while (random()); if (random()) 1',
				"x = 10; while (x--) trace('x =',x);",
				"for (y = 0; y < 10; y++) trace('y =',y);",
				"x = 0; do { trace('do',x++); } while (trace('cond'), x < 10);",
				_do_continue_test,
				"for (trace('y =',0), y = 0; trace(y,'<',10), y < 10; trace('y++'), y++) { trace('loop y =',y); }",
				"for (i = 0; i < 10; i++) if (i == 5) return ; else trace(i);",
				"if (true) return ; else trace('test'); trace('BUG');",
				"for (i = 0; i < 10; i++) { if (i == 3) continue; trace(i); if (i == 5) break; } trace('done');",
				"i = 0; do { if (i == 3) continue; trace(i); if (i == 5) break; } while (i >= 0 && ++i < 10) trace('done');",
				"i = -1; while (++i < 10) { if (i == 3) continue; trace(i); if (i == 5) break; } trace('done');",
				"a = []; o = Object('a',1,'b',2,'c',3,'d',4,'e',5); for (k in o) { a.push(`{k} = {o[k]}`); o['?'+k]=k+'!'; delete o[k]; } for each (p in o) a.push(p); return [a,o];",
				"y = 4; x = 3; var x = 4, y; [x, y]",
				"`abc { function(x,y) { return x+y; } } xyz`",
				"var obj = Object('f', function() { return this == obj; }); var ff = obj.f; [obj.f(), (obj.f)(), ff()]",
				"x = 'x'; function(){ x = 3; return x; }() == x"
			];
			var values:Array = [-2, -1, -0.5, 0, 0.5, 1, 2];
			var vars:Object = {};
			vars['v'] = 123;
			vars['v2'] = 222;
			vars['x'] = 10;
			vars['get'] = function(name:String):*
			{
				//trace("get variable", name, "=", vars[name]);
				return vars[name];
			};
			
			compiler.debug = true;
			for each (var eq:String in eqs)
			{
				trace("expression: "+eq);
				
				var tokens:Array = compiler.getTokens(eq);
				trace("    tokens:", tokens.join(' '));
				var decompiled:String = compiler.decompileObject(compiler.compileTokens(tokens, true));
				trace("decompiled:", decompiled);
				
				var tokens2:Array = compiler.getTokens(decompiled);
				trace("   tokens2:", tokens2.join(' '));
				var recompiled:String = compiler.decompileObject(compiler.compileTokens(tokens2, true));
				trace("recompiled:", recompiled);

				var tokens3:Array = compiler.getTokens(recompiled);
				var decompiled2:String = compiler.decompileObject(compiler.compileTokens(tokens3, true));
				trace("decompiled(2):", decompiled2);
				
				var f:Function = compiler.compileToFunction(eq, vars);
				for each (var value:* in values)
				{
					vars['v'] = value;
					trace("f(v="+value+")\t= " + f(value));
				}
			}
		}
	}
}

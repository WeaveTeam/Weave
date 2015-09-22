/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.data.KeySets
{
	import flash.utils.Dictionary;
	
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObjectWithNewProperties;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.ui.IObjectWithDescription;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.ColumnUtils;

	public class ColumnDataFilter implements IKeyFilter, ILinkableObjectWithNewProperties, IObjectWithDescription
	{
		public function getDescription():String
		{
			return lang("Filter for {0}", ColumnUtils.getTitle(column));
		}
		
		public static const REGEXP:String = 'regexp';
		private static const ALTERNATE_REGEX_PROPERTY:String = 'regex';
		
		public const enabled:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), _cacheVars);
		public const includeMissingKeyTypes:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), _cacheVars);
		public const column:DynamicColumn = newLinkableChild(this, DynamicColumn, _resetKeyLookup);
		
		/**
		 * An Array of Numbers, Strings and/or Range objects specifying numeric ranges.
		 * A Range object contains two properties: "min" and "max".
		 * Alternatively, you can specify "minInclusive" or "minExclusive" in place of "min"
		 * and "minInclusive" or "maxExclusive" in place of "max".
		 */
		public const values:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), _resetKeyLookup);
		
		private var _enabled:Boolean;
		private var _includeMissingKeyTypes:Boolean;
		private var _stringLookup:Object;
		private var _numberLookup:Object;
		private var _ranges:Array;
		private var _regexps:Array;
		private var _keyType:String;
		private var _keyLookup:Dictionary = new Dictionary(true);
		
		private function _cacheVars():void
		{
			_enabled = enabled.value;
			_includeMissingKeyTypes = includeMissingKeyTypes.value;
		}
		private function _resetKeyLookup():void
		{
			var state:Array = values.getSessionState() as Array;
			var value:*;
			var range:Range;
			var regexp:RegExp;
			
			_keyType = column.getMetadata(ColumnMetadata.KEY_TYPE);
			_keyLookup = new Dictionary(true);
			_numberLookup = null;
			_stringLookup = null;
			_ranges = null;
			_regexps = null;
			
			for each (value in state)
			{
				if (value is Number)
				{
					if (!_numberLookup)
						_numberLookup = {};
					_numberLookup[value] = true;
				}
				else if (value is String)
				{
					if (!_stringLookup)
						_stringLookup = {};
					_stringLookup[value] = true;
				}
				else if (Range.isRange(value))
				{
					try
					{
						range = new Range(value);
						if (!_ranges)
							_ranges = [];
						_ranges.push(range);
					}
					catch (e:Error)
					{
						// ignore this value
					}
				}
				else if (isRegExp(value))
				{
					if (!_regexps)
						_regexps = [];
					regexp = toRegExp(value);
					_regexps.push(regexp);
				}
			}
			
			// last step - canonicalize session states containing ranges
			if (_ranges)
			{
				var newState:Array = [];
				for each (value in state)
				{
					if (value is Number || value is String)
						newState.push(value);
				}
				for each (range in _ranges)
				{
					newState.push(range.getState());
				}
				for each (regexp in _regexps)
				{
					value = {};
					value[REGEXP] = regexp.source;
					newState.push(value);
				}
				values.setSessionState(newState);
			}
		}
		
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (!_enabled)
				return true;
			
			var number:Number;
			var string:String;
			var result:* = _keyLookup[key];
			if (result === undefined)
			{
				result = false;
				
				if (_numberLookup || _ranges)
					number = column.getValueFromKey(key, Number);
				if (_stringLookup || _regexps)
					string = column.getValueFromKey(key, String);
				
				if (_numberLookup)
					result = _numberLookup.hasOwnProperty(number);
				
				if (!result && _stringLookup)
					result = _stringLookup.hasOwnProperty(string);
				
				if (!result && _includeMissingKeyTypes && key.keyType != _keyType)
					result = true;
				
				if (!result && _ranges)
				{
					for each (var range:Range in _ranges)
					{
						if (range.minInclusive ? number < range.min : number <= range.min)
							continue;
						if (range.maxInclusive ? number > range.max : number >= range.max)
							continue;
						result = true;
						break;
					}
				}
				
				if (!result && _regexps)
				{
					for each (var regexp:RegExp in _regexps)
					{
						if (regexp.test(string))
						{
							result = true;
							break;
						}
					}
				}
				
				_keyLookup[key] = result;
			}
			return result;
		}
		
		public function stringifyValues():Array
		{
			var result:Array = values.getSessionState() as Array || [];
			return result.map(stringifyValue);
		}
		
		private function stringifyValue(value:*, ..._):String
		{
			if (value is String)
			{
				return value;
			}
			else if (value is Number)
			{
				return ColumnUtils.deriveStringFromNumber(column, value);
			}
			else if (Range.isRange(value))
			{
				var range:Range = new Range(value);
				var leftBracket:String = range.minInclusive ? "[" : "(";
				var rightBracket:String = range.maxInclusive ? "]" : ")";
				return leftBracket + stringifyValue(range.min) + ", " + stringifyValue(range.max) + rightBracket;
			}
			else if (isRegExp(value))
			{
				return toRegExp(value).toString();
			}
			
			return null;
		}
		
		private static function isRegExp(obj:Object):Boolean
		{
			return obj != null && typeof obj == 'object'
				&& (obj.hasOwnProperty(REGEXP) || obj.hasOwnProperty(ALTERNATE_REGEX_PROPERTY));
		}
		
		private static function toRegExp(value:Object):RegExp
		{
			return new RegExp(value[REGEXP] || value[ALTERNATE_REGEX_PROPERTY]);
		}
		
		private var _deprecatedRangeState:Object;
		public function handleMissingSessionStateProperty(newState:Object, property:String):void
		{
			// handle deprecated StringDataFilter single-string value
			if (property == 'stringValue')
				values.setSessionState([newState[property]]);
			// handle deprecated StringDataFilter array of strings
			if (property == 'stringValues')
				values.setSessionState(newState[property]);
			// handle deprecated NumberDataFilter state
			if (property == 'min' || property == 'max')
			{
				if (!_deprecatedRangeState)
					_deprecatedRangeState = {};
				_deprecatedRangeState[property] = newState[property];
				values.setSessionState([_deprecatedRangeState]);
			}
		}
	}
}

internal class Range
{
	public static function isRange(obj:Object):Boolean
	{
		var count:int = 0;
		var prop:String;
		
		for each (prop in [MIN, MIN_INCLUSIVE, MIN_EXCLUSIVE])
			if (obj.hasOwnProperty(prop))
				count++;
		if (!count)
			return false;
		
		count = 0;
		for each (prop in [MAX, MAX_INCLUSIVE, MAX_EXCLUSIVE])
			if (obj.hasOwnProperty(prop))
				count++;
		
		return count > 0;
	}
	
	public static const MIN:String = 'min';
	public static const MIN_INCLUSIVE:String = 'minInclusive';
	public static const MIN_EXCLUSIVE:String = 'minExclusive';
	public static const MAX:String = 'max';
	public static const MAX_INCLUSIVE:String = 'maxInclusive';
	public static const MAX_EXCLUSIVE:String = 'maxExclusive';
	
	public function Range(obj:Object)
	{
		var prop:String;
		for each (prop in [MIN, MIN_INCLUSIVE, MIN_EXCLUSIVE])
			if (obj.hasOwnProperty(prop))
				min = Math.max(min, obj[prop]);
		for each (prop in [MAX, MAX_INCLUSIVE, MAX_EXCLUSIVE])
			if (obj.hasOwnProperty(prop))
				max = Math.min(max, obj[prop]);
		if (obj.hasOwnProperty(MIN_EXCLUSIVE))
			minInclusive = false;
		if (obj.hasOwnProperty(MAX_EXCLUSIVE))
			maxInclusive = false;
	}
	
	public var min:* = -Infinity;
	public var max:* = Infinity;
	public var minInclusive:Boolean = true;
	public var maxInclusive:Boolean = true;
	
	public function getState():Object
	{
		var state:Object = {};
		state[minInclusive ? MIN : MIN_EXCLUSIVE] = min;
		state[maxInclusive ? MAX : MAX_EXCLUSIVE] = max;
		return state;
	}
}

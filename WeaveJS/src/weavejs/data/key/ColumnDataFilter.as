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

package weavejs.data.key
{
	import weavejs.api.core.ILinkableObjectWithNewProperties;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IKeyFilter;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.ui.IObjectWithDescription;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableVariable;
	import weavejs.data.ColumnUtils;
	import weavejs.data.column.DynamicColumn;
	import weavejs.util.JS;

	public class ColumnDataFilter implements IKeyFilter, ILinkableObjectWithNewProperties, IObjectWithDescription
	{
		public function getDescription():String
		{
			return Weave.lang("Filter for {0}", ColumnUtils.getTitle(column));
		}
		
		public static const REGEXP:String = 'regexp';
		private static const ALTERNATE_REGEX_PROPERTY:String = 'regex';
		
		public const enabled:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true), _cacheVars);
		public const includeMissingKeyTypes:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true), _cacheVars);
		public const column:DynamicColumn = Weave.linkableChild(this, DynamicColumn, _resetKeyLookup);
		
		/**
		 * An Array of Numbers, Strings and/or Range objects specifying numeric ranges.
		 * A Range object contains two properties: "min" and "max".
		 * Alternatively, you can specify "minInclusive" or "minExclusive" in place of "min"
		 * and "minInclusive" or "maxExclusive" in place of "max".
		 */
		public const values:LinkableVariable = Weave.linkableChild(this, new LinkableVariable(Array), _resetKeyLookup);
		
		private var _enabled:Boolean;
		private var _includeMissingKeyTypes:Boolean;
		private var _stringLookup:Object;
		private var _numberLookup:Object;
		private var _ranges:Array;
		private var _regexps:Array;
		private var _keyType:String;
		private var map_key:Object = new JS.WeakMap();
		
		private function _cacheVars():void
		{
			_enabled = enabled.value;
			_includeMissingKeyTypes = includeMissingKeyTypes.value;
		}
		private function _resetKeyLookup():void
		{
			var state:Array = values.getSessionState() as Array;
			var value:*;
			var range:ColumnDataFilterRange;
			var regexp:RegExp;
			
			_keyType = column.getMetadata(ColumnMetadata.KEY_TYPE);
			map_key = new JS.WeakMap();
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
				else if (ColumnDataFilterRange.isRange(value))
				{
					try
					{
						range = new ColumnDataFilterRange(value);
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
			var result:* = map_key.get(key);
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
					for each (var range:ColumnDataFilterRange in _ranges)
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
				
				map_key.set(key, result);
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
			else if (ColumnDataFilterRange.isRange(value))
			{
				var range:ColumnDataFilterRange = new ColumnDataFilterRange(value);
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
		
		public function get deprecatedStateMapping():Object
		{
			return this.handleMissingSessionStateProperties;
		}
		
		private var _deprecatedRangeState:Object;
		private function handleMissingSessionStateProperties(newState:Object):void
		{
			// handle deprecated StringDataFilter single-string value
			const STRING_VALUE:String = 'stringValue';
			if (newState.hasOwnProperty(STRING_VALUE))
				values.setSessionState([newState[STRING_VALUE]]);
			
			// handle deprecated StringDataFilter array of strings
			const STRING_VALUES:String = 'stringValues';
			if (newState.hasOwnProperty(STRING_VALUES))
				values.setSessionState(newState[STRING_VALUES]);
			
			// handle deprecated NumberDataFilter state
			for each (var property:String in ['min', 'max'])
			{
				if (newState.hasOwnProperty(property))
				{
					if (!_deprecatedRangeState)
						_deprecatedRangeState = {};
					_deprecatedRangeState[property] = newState[property];
					values.setSessionState([_deprecatedRangeState]);
				}
			}
		}
	}
}

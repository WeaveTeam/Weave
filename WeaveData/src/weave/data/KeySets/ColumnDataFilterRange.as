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
	internal class ColumnDataFilterRange
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
		
		public function ColumnDataFilterRange(obj:Object)
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
}

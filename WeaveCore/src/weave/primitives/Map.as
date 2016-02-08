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

package weave.primitives
{
	import flash.utils.Dictionary;

	/**
	 * A wrapper for flash.utils.Dictionary which can be used to aid transition to FlexJS.
	 */
	public class Map
	{
		private var d:Dictionary = new Dictionary();
		private var ks:Array = [];
		
		public function has(k:*):Boolean
		{
			return d[k] !== undefined;
		}
		
		public function get(k:*):*
		{
			return d[k];
		}
		
		public function set(k:*, v:*):void
		{
			d[k] = v;
		}
		
		public function remove(k:*):void
		{
			delete d[k];
		}
		
		public function get size():int
		{
			var n:int = 0;
			for (var k:* in d)
				++n;
			return n;
		}
		
		public static function keys(map:Map):Array
		{
			var ks:Array = map.ks;
			var i:int = 0;
			for (var k:* in map.d)
				ks[i++] = k;
			ks.length = i;
			return ks;
		}
	}
}

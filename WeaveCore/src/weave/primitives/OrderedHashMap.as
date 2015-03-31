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
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	use namespace flash_proxy;
	
	/**
	 * The names and values in this object are enumerated in the order they were added.
	 * 
	 * @author adufilie
	 */
	public class OrderedHashMap extends Proxy
	{
		protected var names:Array = [];
		protected var values:Object = {};
		
		override flash_proxy function callProperty(name:*, ...parameters):*
		{
			return values[name].apply(this, parameters);
		}
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return values.hasOwnProperty(name);
		}
		override flash_proxy function getProperty(name:*):*
		{
			return values[name];
		}
		override flash_proxy function setProperty(name:*, value:*):void
		{
			var nameStr:String = name;
			var i:int = names.indexOf(nameStr);
			if (i >= 0)
				names.splice(i, 1);
			
			values[nameStr] = value;
			names.push(nameStr);
		}
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			var nameStr:String = name;
			var i:int = names.indexOf(nameStr);
			if (i >= 0)
				names.splice(i, 1);
			
			return delete values[nameStr];
		}
		override flash_proxy function nextNameIndex(index:int):int
		{
			if (index < names.length)
				return index + 1;
			return 0;
		}
		override flash_proxy function nextName(index:int):String
		{
			return names[index - 1];
		}
		override flash_proxy function nextValue(index:int):*
		{
			return values[index - 1];
		}
	}
}

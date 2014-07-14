/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.utils
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
		protected var values:Array = [];
		
		override flash_proxy function callProperty(name:*, ...parameters):*
		{
			var i:int = names.indexOf(String(name));
			var value:Function = values[i];
			return value.apply(this, parameters);
		}
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return names.indexOf(String(name)) >= 0;
		}
		override flash_proxy function getProperty(name:*):*
		{
			var i:int = names.indexOf(String(name));
			if (i >= 0)
				return values[i];
			return null;
		}
		override flash_proxy function setProperty(name:*, value:*):void
		{
			deleteProperty(name);
			
			names.push(String(name));
			values.push(value);
		}
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			var i:int = names.indexOf(String(name));
			if (i >= 0)
			{
				names.splice(i, 1);
				values.splice(i, 1);
			}
			return i >= 0;
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

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

package weave.core
{
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import weave.api.core.ILinkableObject;
	
	/**
	 * This contains an ordered list of name-to-object mappings.
	 * 
	 * @TODO implement this class
	 * 
	 * @author adufilie
	 */
	public class LinkableProxyObject extends Proxy implements ILinkableObject
	{
		override flash_proxy function callProperty(name:*, ...parameters):*
		{
		}
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			return false;
		}
		override flash_proxy function getDescendants(name:*):*
		{
		}
		override flash_proxy function getProperty(name:*):*
		{
		}
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return false;
		}
		override flash_proxy function isAttribute(name:*):Boolean
		{
			return false;
		}
		override flash_proxy function nextName(index:int):String
		{
			return null;
		}
		override flash_proxy function nextNameIndex(index:int):int
		{
			return 0;
		}
		override flash_proxy function nextValue(index:int):*
		{
		}
		override flash_proxy function setProperty(name:*, value:*):void
		{
		}
	}
}

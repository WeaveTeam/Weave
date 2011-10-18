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
	
	/**
	 * This class provides a convenient way for creating a Proxy object.
	 * @author adufilie
	 */
	public class ProxyObject extends Proxy
	{
		public function ProxyObject(hasProperty:Function, getProperty:Function, setProperty:Function)
		{
			super();
			if (hasProperty != null)
				_has = hasProperty;
			if (getProperty != null)
				_get = getProperty;
			if (setProperty != null)
				_set = setProperty;
		}
		
		private var _has:Function = super.flash_proxy::hasProperty as Function;
		private var _get:Function = super.flash_proxy::getProperty as Function;
		private var _set:Function = super.flash_proxy::setProperty as Function;
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return _has.call(this, name);
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			return _get.call(this, name);
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			_set.call(this, name, value);
		}
	}
}

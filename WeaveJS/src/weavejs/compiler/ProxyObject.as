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

package weavejs.compiler
{
	/**
	 * This class provides a convenient way for creating a Proxy object to be used as a symbol table.
	 * 
	 * @author adufilie
	 */
	public class ProxyObject
	{
		/**
		 * This constructor allows you to specify the three most important flash_proxy functions
		 * and an optional custom flash_proxy::callProperty function.
		 * @param hasProperty function hasProperty(name:*):Boolean
		 * @param getProperty function getProperty(name:*):*
		 * @param setProperty function setProperty(name:*, value:*):void
		 * @param callProperty function callProperty(name:*, ...parameters):*
		 */		
		public function ProxyObject(hasProperty:Function, getProperty:Function, setProperty:Function, callProperty:Function = null)
		{
			super();
			if (hasProperty != null)
				_has = hasProperty;
			if (getProperty != null)
				_get = getProperty;
			if (setProperty != null)
				_set = setProperty;
			if (callProperty != null)
				_call = callProperty;
		}
		
		private var _has:Function = null;
		private var _get:Function = null;
		private var _set:Function = null;
		private var _call:Function = null;
		
		/**
		 * @inheritDoc
		 */
		public function hasProperty(name:*):Boolean
		{
			return _has.call(this, name);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getProperty(name:*):*
		{
			return _get.call(this, name);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setProperty(name:*, value:*):void
		{
			_set.call(this, name, value);
		}
		
		/**
		 * @inheritDoc
		 */
		public function callProperty(name:*, ...parameters):*
		{
			if (_call == null)
				return _get.call(this, name).apply(this, parameters);
			
			parameters.unshift(name);
			return _call.apply(this, parameters);
		}
	}
}

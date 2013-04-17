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

package weave.utils
{
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getQualifiedClassName;

	/**
	 * This is a Proxy object that wraps function calls in a way that allows method chaining (<code>obj.f(1).g(2).h(3)</code>).
	 * Multiple objects can be wrapped in a single MethodChainProxy object.
	 * In that case, method calls will use the first object with a matching property name.
	 * If a wrapped function returns a value, it can be accessed using valueOf():  <code>obj.f(1).g(2).valueOf()</code>
	 * Non-function properties are automatically wrapped in setter/getter functions that will set the value if given one parameter
	 * and get the value if given zero parameters.
	 * 
	 * @example
	 * <listing version="3.0">
	 * var shape:Shape = new Shape();
	 * var graphicsChain:MethodChainProxy = new MethodChainProxy(shape, shape.graphics);
	 * 
	 * this.rawChildren.addChild(shape);
	 * 
	 * graphicsChain.lineStyle(1,1,1)
	 *  .moveTo(0,0)
	 *  .lineTo(10,10)
	 *  .lineTo(10,0)
	 *  .lineTo(0,0)
	 *  .x(20)
	 *  .y(40)
	 *  .scaleX(3)
	 *  .scaleY(4);
	 * 
	 * trace( 'Width of shape is:', graphicsChain.width() );
	 * trace( 'getRect() returns:', graphicsChain.getRect(this).valueOf() );
	 * </listing>
	 * 
	 * @author adufilie
	 */
	public class MethodChainProxy extends Proxy
	{
		/**
		 * Constructor.
		 * @param objects A list of objects to be checked in order when accessing properties or calling methods of the MethodChainProxy.
		 */		
		public function MethodChainProxy(...objects):void
		{
			_objectsToCheck = objects;
			
			_classNames = _objectsToCheck.map(function(o:*):* { return getQualifiedClassName(o); });
			
			_thisQName = getQualifiedClassName(this);
			var i:int = _classNames.indexOf('Object');
			if (i >= 0)
				_classNames[i] = _thisQName;
			else
				_classNames.push(_thisQName);
		}
		
		private var _thisQName:String;
		private var _objectsToCheck:Array;
		private var _classNames:Array;
		private var _wrappers:Object = {};
		private var _result:*;
		
		/**
		 * Gets the value returned from the last function call.
		 */		
		public function valueOf():*
		{
			return _result;
		}
		
		private function _getWrapper(host:Object, property:String):*
		{
			// used cached wrapper function if it exists
			if (_wrappers.hasOwnProperty(property))
				return _wrappers[property] as Function;
			
			// cache a new wrapper function
			var wrapper:*;
			if (host[property] is Function)
				wrapper = _newFunctionWrapper(host, property);
			else
				wrapper = _newSetterGetter(host, property);
			
			return _wrappers[property] = wrapper;
		}
		
		private function _newFunctionWrapper(host:Object, property:String):Function
		{
			// create a wrapper function that supports method chaining
			var _this:* = this;
			return function(...args):* {
				_this._result = undefined; // in case error is thrown
				_this._result = host[property].apply(null, args);
				return _this;
			};
		}
		
		private function _newSetterGetter(host:Object, property:String):Function
		{
			// create a property setter/getter
			var _this:* = this;
			return function(...args):* {
				_this._result = undefined; // in case error is thrown
				if (args.length == 0)
				{
					// 'getter' mode - return the value
					return _this._result = host[property];
				}
				if (args.length == 1)
				{
					// 'setter' mode - allows method chaining
					_this._result = host[property] = args[0];
					return _this;
				}
				throw new Error(_thisQName + '.' + property + '(): Invalid number of arguments.  Expecting 0 or 1.');
			};
		}
		
		private function _throwError(propertyName:String):void
		{
			throw new Error('There is no property named "' + propertyName + '" on ' + _classNames.join(' or '));
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			for each (var obj:Object in _objectsToCheck)
			{
				if (obj.hasOwnProperty(name))
					return true;
			}
			return false;
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			if (name == 'valueOf')
				return _result;
			
			for each (var obj:Object in _objectsToCheck)
			{
				if (obj.hasOwnProperty(name))
					return _getWrapper(obj, name);
			}
			_throwError(name);
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			for each (var obj:Object in _objectsToCheck)
			{
				if (obj.hasOwnProperty(name))
				{
					obj[name] = value;
					return;
				}
			}
			_throwError(name);
		}
		
		override flash_proxy function callProperty(name:*, ...parameters):*
		{
			var wrapperMethod:* = this.flash_proxy::getProperty(name); // throws error if property does not exist
			try
			{
				return wrapperMethod.apply(this, parameters);
			}
			catch (e:Error)
			{
				e.message = _thisQName + '.' + name + '(): ' + e.message;
				throw e;
			}
		}
	}
}

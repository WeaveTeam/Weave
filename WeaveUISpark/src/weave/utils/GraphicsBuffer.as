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
	import avmplus.getQualifiedClassName;
	
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	/**
	 * This is a class uses method chaining to draw vector graphics onto a destination BitmapData.
	 * You can call any function normally available on a Graphics object.
	 * 
	 * @author adufilie
	 * @see flash.display.Graphics
	 */
	public class GraphicsBuffer extends Proxy
	{
		public function GraphicsBuffer(destination:BitmapData)
		{
			_destination = destination;
			_shape = new Shape();
			_properties = {'flush': flush, 'result': true};
			_objectsToCheck = [_properties, _shape, _shape.graphics]
		}
		
		private var _destination:BitmapData;
		private var _shape:Shape;
		private var _objectsToCheck:Array;
		private var _properties:Object;
		private var _wrappers:Object = {};
		private var _result:*;
		
		private function _getWrapper(host:Object, property:String):*
		{
			if (property == 'result')
				return _result;
			
			if (_wrappers.hasOwnProperty(property))
				return _wrappers[property];
			
			var value:* = host[property];
			if (value is Function)
				_wrappers[property] = value = newWrapper(value);
			
			return value;
		}
		
		private function newWrapper(func:Function):Function
		{
			var _this:GraphicsBuffer = this;
			return function(...args):* {
				_this._result = func.apply(null, args);
				return _this;
			};
		}
		
		private function _throwError(propertyName:String):void
		{
			throw new Error('There is no property named "' + propertyName + '" on ' + getQualifiedClassName(this) + ' or flash.display.Shape');
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			for each (var obj:* in _objectsToCheck)
			if (obj.hasOwnProperty(name))
				return true;
			return false;
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			for each (var obj:* in _objectsToCheck)
			if (obj.hasOwnProperty(name))
				return _getWrapper(obj, name);
			
			_throwError(name);
		}
		
		override flash_proxy function callProperty(name:*, ...parameters):*
		{
			try
			{
				_result = this[name].apply(this, parameters);
				return this;
			}
			catch (e:Error)
			{
				e.message = 'GraphicsBuffer.' + name + '(): ' + e.message;
				throw e;
			}
			
			throw new Error('There is no function named "' + name + '" on flash.display.Graphics.');
		}
		
		/**
		 * Flush the vector graphics to the destination BitmapData.
		 */
		public function flush():GraphicsBuffer
		{
			_destination.draw(_shape);
			_shape.graphics.clear();
			return this;
		}
		
		/**
		 * Gets the result of the last function call.
		 */		
		public function get result():*
		{
			return _result;
		}
	}
}

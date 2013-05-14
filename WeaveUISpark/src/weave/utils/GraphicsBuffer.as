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
	import flash.display.BitmapData;
	import flash.display.Shape;

	/**
	 * This is a class uses method chaining to draw vector graphics onto a destination BitmapData.
	 * You can call any function normally available on a Graphics object or a Shape object.
	 * 
	 * @author adufilie
	 * @see flash.display.Graphics
	 * @see flash.display.Shape
	 */
	public dynamic class GraphicsBuffer extends MethodChainProxy
	{
		public function GraphicsBuffer(destination:BitmapData = null)
		{
			_destination = destination;
			_shape = new Shape();
			_properties = {'flush': this.flush, 'destination': this.destination};
			super(_properties, _shape, _shape.graphics);
		}
		
		private var _properties:Object;
		private var _destination:BitmapData;
		private var _shape:Shape;
		
		/**
		 * Sets or gets the current destination BitmapData.
		 * @param value If specified, this will be the new destination BitmapData.
		 * @return Either this if value was specified, or the current destination BitmapData if not.
		 */		
		public function destination(value:* = undefined):*
		{
			if (value === undefined)
				return _destination;
			
			_destination = value;
			return this;
		}
		
		/**
		 * Draws the vector graphics to the destination BitmapData and then calls Graphics.clear().
		 * @param destination Optional new destination.
		 */
		public function flush(destination:BitmapData = null):GraphicsBuffer
		{
			if (destination)
				_destination = destination;
			if (_destination)
				_destination.draw(_shape);
			_shape.graphics.clear();
			if (!_destination)
				throw new Error("destination not set");
			return this;
		}
	}
}

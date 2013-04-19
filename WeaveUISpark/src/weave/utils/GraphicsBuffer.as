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
	 */
	public class GraphicsBuffer extends MethodChainProxy
	{
		public function GraphicsBuffer(destination:BitmapData)
		{
			_destination = destination;
			_shape = new Shape();
			_properties = {'flush': flush};
			super(_properties, _shape, _shape.graphics);
		}
		
		private var _properties:Object;
		private var _destination:BitmapData;
		private var _shape:Shape;
		
		/**
		 * Draws the vector graphics to the destination BitmapData and then calls Graphics.clear().
		 */
		public function flush():GraphicsBuffer
		{
			_destination.draw(_shape);
			_shape.graphics.clear();
			return this;
		}
	}
}

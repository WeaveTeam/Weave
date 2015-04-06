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

package weave.utils
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	
	import weave.primitives.MethodChainProxy;

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

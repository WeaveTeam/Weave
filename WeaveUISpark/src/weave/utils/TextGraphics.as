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

	/**
	 * This is a class uses method chaining to draw text onto a BitmapData object.
	 * 
	 * @author adufilie
	 */
	public class TextGraphics
	{
		public function TextGraphics()
		{
			bt = new BitmapText();
		}
		
		private var bt:BitmapText;
		private var _destination:BitmapData;
		private var _text:*;
		private var _formatter:*;
		
		/**
		 * Returns internal BitmapText object.
		 */
		public function getBitmapText():BitmapText
		{
			return bt;
		}
		
		/**
		 * Set the destination for drawing.
		 */
		public function destination(value:BitmapData):TextGraphics
		{
			_destination = value;
			return this;
		}
		/**
		 * Set the text.
		 */
		public function text(value:*):TextGraphics
		{
			_text = value;
			bt.text = _formatter == null ? _text : _formatter(_text);
			return this;
		}
		/**
		 * Sets a text formatter function which accepts a value and returns a String.
		 */
		public function formatter(func:Function):TextGraphics
		{
			_formatter = func;
			
			// null pointer error is likely to occur if _text hasn't been set yet
			try {
				bt.text = _formatter(_text);
			} catch (e:*) { }
			
			return this;
		}
		/**
		 * Draw current text using current settings.
		 */
		public function draw():TextGraphics
		{
			if (!_destination)
				throw new Error("Must set destination first");
			bt.draw(_destination);
			return this;
		}
		/**
		 * Draws text at current position, or new position and angle if specified.
		 */
		public function drawText(text:*):TextGraphics
		{
			return this.text(text).draw();
		}
		/**
		 * Set angle mode to radians.
		 * @param value Optional new angle, in radians.
		 */
		public function radians(value:Number = NaN):TextGraphics
		{
			if (isFinite(value))
				bt.angle = value;
			else if (bt.angleIsDegrees)
				bt.angle = bt.angle * Math.PI / 180;
			bt.angleIsDegrees = false;
			return this;
		}
		/**
		 * Set angle mode to degrees (the default).
		 * @param value Optional new angle, in degrees.
		 */
		public function degrees(value:Number = NaN):TextGraphics
		{
			if (isFinite(value))
				bt.angle = value;
			else if (!bt.angleIsDegrees)
				bt.angle = bt.angle * 180 / Math.PI;
			bt.angleIsDegrees = true;
			return this;
		}
		/**
		 * Sets current angle in degrees or radians, depending on current mode.
		 */		
		public function angle(a:Number):TextGraphics
		{
			bt.angle = a;
			return this;
		}
		/**
		 * Rotate by a number of degrees or radians, depending on the current mode.
		 */
		public function rotate(angle:Number):TextGraphics
		{
			var a:Number = bt.angle + angle;
			var max:Number = bt.angleIsDegrees ? 360 : Math.PI * 2;
			if (a >= max || a < 0)
				a = a % max;
			bt.angle = a;
			return this;
		}
		/**
		 * Move to an x,y position.
		 */		
		public function moveTo(x:Number, y:Number):TextGraphics
		{
			bt.x = x;
			bt.y = y;
			return this;
		}
		/**
		 * Adjust x and y position by relative coordinates.
		 */		
		public function move(dx:Number, dy:Number):TextGraphics
		{
			bt.x += dx;
			bt.y += dy;
			return this;
		}
		/**
		 * Set the x position.
		 */
		public function x(value:Number):TextGraphics
		{
			bt.x = value;
			return this;
		}
		/**
		 * Set the y position.
		 */
		public function y(value:Number):TextGraphics
		{
			bt.y = value;
			return this;
		}
		/**
		 * Use integer-rounded x,y coordinates (true or false).
		 */
		public function roundCoords(value:Boolean):TextGraphics
		{
			bt.roundCoords = value;
			return this;
		}
		/**
		 * Trim whitespace around text (true or false).
		 */
		public function trim(value:Boolean):TextGraphics
		{
			bt.trim = value;
			return this;
		}
		/**
		 * Text should appear above the y position, optionally specified.
		 */
		public function above(y:Number = NaN):TextGraphics
		{
			bt.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM;
			if (isFinite(y))
				bt.y = y;
			return this;
		}
		/**
		 * Text should appear vertically centered at the y position, optionally specified
		 */
		public function middle(y:Number = NaN):TextGraphics
		{
			bt.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
			if (isFinite(y))
				bt.y = y;
			return this;
		}
		/**
		 * Text should appear below the y position, optionally specified.
		 */
		public function below(y:Number = NaN):TextGraphics
		{
			bt.verticalAlign = BitmapText.VERTICAL_ALIGN_TOP;
			if (isFinite(y))
				bt.y = y;
			return this;
		}
		/**
		 * Text should appear before (to the left of) the x position, optionally specified.
		 */
		public function before(x:Number = NaN):TextGraphics
		{
			bt.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
			if (isFinite(x))
				bt.x = x;
			return this;
		}
		/**
		 * Text should appear horizontally centered at the x position, optionally specified.
		 */
		public function center(x:Number = NaN):TextGraphics
		{
			bt.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
			if (isFinite(x))
				bt.x = x;
			return this;
		}
		/**
		 * Text should appear after (to the right of) the x position, optionally specified.
		 */
		public function after(x:Number = NaN):TextGraphics
		{
			bt.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
			if (isFinite(x))
				bt.x = x;
			return this;
		}
		/**
		 * Ellipsis ("...") should appear at the beginning of cropped text.
		 */
		public function ellipsisLeft():TextGraphics
		{
			bt.ellipsisLocation = BitmapText.ELLIPSIS_LOCATION_LEFT;
			return this;
		}
		/**
		 * Ellipsis ("...") should appear in the middle of cropped text.
		 */
		public function ellipsisCenter():TextGraphics
		{
			bt.ellipsisLocation = BitmapText.ELLIPSIS_LOCATION_CENTER;
			return this;
		}
		/**
		 * Ellipsis ("...") should appear at the end of cropped text.
		 */
		public function ellipsisRight():TextGraphics
		{
			bt.ellipsisLocation = BitmapText.ELLIPSIS_LOCATION_RIGHT;
			return this;
		}
		/**
		 * Sets maxWidth in pixels.
		 */
		public function maxWidth(value:Number):TextGraphics
		{
			bt.maxWidth = value;
			return this;
		}
		/**
		 * Sets maxHeight in pixels.
		 */
		public function maxHeight(value:Number):TextGraphics
		{
			bt.maxHeight = value;
			return this;
		}
		/**
		 * Sets width in pixels.
		 */
		public function width(value:Number):TextGraphics
		{
			bt.width = value;
			return this;
		}
		/**
		 * Sets height in pixels.
		 */
		public function height(value:Number):TextGraphics
		{
			bt.height = value;
			return this;
		}
		/**
		 * Sets a property of TextFormat.
		 * @see flash.text.TextFormat
		 */
		public function textFormat(propertyName:String, value:*):TextGraphics
		{
			bt.textFormat[propertyName] = value;
			return this;
		}
		/**
		 * Sets font size in pixels.
		 */		
		public function size(pixels:Number):TextGraphics
		{
			bt.textFormat.size = pixels;
			return this;
		}
		/**
		 * Sets font color.
		 */		
		public function color(c:*):TextGraphics
		{
			bt.textFormat.color = c;
			return this;
		}
	}
}

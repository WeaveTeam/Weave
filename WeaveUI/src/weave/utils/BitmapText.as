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
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextLineMetrics;
	import flash.utils.Dictionary;
	
	import mx.core.Application;
	import mx.events.CollectionEvent;
	import mx.managers.SystemManager;
	import mx.utils.StringUtil;
	
	import weave.Weave;
	import weave.WeaveProperties;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableHashMap;
	import weave.resources.fonts.EmbeddedFonts;
	
	/**
	 * This is a class used to draw text onto BitmapData objects.
	 * 
	 * @author adufilie
	 */
	public class BitmapText
	{
		public function BitmapText()
		{
			_textField.embedFonts = true; // without this, rotated text is not possible.
			
			textFormat.font = WeaveProperties.DEFAULT_FONT_FAMILY;
			textFormat.size = 10;
			textFormat.bold = false;
			textFormat.italic = false;
			textFormat.underline = false;
			textFormat.align = TextFormatAlign.LEFT;
			textFormat.color = 0x000000;
			

			
		}
		
		private var debug:Boolean = false; // set to true to draw debug graphics
		
		public static const HORIZONTAL_ALIGN_LEFT:String = "left";
		public static const HORIZONTAL_ALIGN_CENTER:String = "center";
		public static const HORIZONTAL_ALIGN_RIGHT:String = "right";
		public static const VERTICAL_ALIGN_TOP:String = "top";
		public static const VERTICAL_ALIGN_MIDDLE:String = "middle";
		public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";
		public static const ELLIPSIS_LOCATION_LEFT:String = "left";
		public static const ELLIPSIS_LOCATION_CENTER:String = "center";
		public static const ELLIPSIS_LOCATION_RIGHT:String = "right";
		
		private var _textField:TextField = new TextField(); // private, used to render the text
		private var _matrix:Matrix = new Matrix(); // private, used to move & rotate the graphics
		private var _width:Number = NaN; // exposed through public set/get functions
		private var _maxWidth:Number = NaN; // exposed through public set/get functions
		private var _height:Number = NaN; // exposed through public set/get functions
		private var _maxHeight:Number = NaN; // exposed through public set/get functions
		
		public var text:String = null; // the text to display when calling draw()
		public var x:Number = 0; // align text to this x coordinate before rotating
		public var y:Number = 0; // align text to this y coordinate before rotating
		public var angle:Number = 0; // rotation angle in degrees
		public var roundCoords:Boolean = true; // round x,y values to integers
		public var trim:Boolean = true; // trim leading/trailing whitespace
		public var horizontalAlign:String = HORIZONTAL_ALIGN_LEFT; // default: align x to left side of text
		
		private var _verticalAlign:String = VERTICAL_ALIGN_TOP; // default: align y to top of text
		public function set verticalAlign(value:String):void
		{
			_verticalAlign = value;
			// BACKWARDS COMPATIBILITY
			if (value == "center")
				_verticalAlign = VERTICAL_ALIGN_MIDDLE;
		}
		
		public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		
		public var ellipsisLocation:String = ELLIPSIS_LOCATION_CENTER; // location of '...' when text gets truncated
		public var textFormat:TextFormat = new TextFormat(); // This is the TextFormat that will be used when rendering text.

		/**
		 * This value is an absolute width to use when drawing text.
		 */
		public function get width():Number { return _width; }
		public function set width(value:Number):void { _width = value; _maxWidth = NaN; }
		
		/**
		 * Setting this value will unset the absolute width value and instead use a maximum width to autoSize to when drawing text.
		 */
		public function get maxWidth():Number { return _maxWidth; }
		public function set maxWidth(value:Number):void { _maxWidth = value; _width = NaN; }

		/**
		 * This value is an absolute height to use when drawing text.
		 */
		public function get height():Number { return _height; }
		public function set height(value:Number):void { _height = value; _maxHeight = NaN; }
		
		/**
		 * Setting this value will unset the absolute height value and instead use a maximum height to autoSize to when drawing text.
		 */
		public function get maxHeight():Number { return _maxHeight; }
		public function set maxHeight(value:Number):void { _maxHeight = value; _height = NaN; }

		private static const AUTOSIZE_ENABLE:String = TextFieldAutoSize.LEFT; // we always want the text field to expand to the right.
		private static const AUTOSIZE_DISABLE:String = TextFieldAutoSize.NONE;
		
		/**
		 * This function will prepare the TextField object, setting all the necessary properties for rendering or calculating the bounds.
		 */
		private function prepareTextField():void
		{
			
			if(!(Application.application as Application).systemManager.isFontFaceEmbedded(textFormat))
				
			{
				textFormat.font = WeaveProperties.DEFAULT_FONT_FAMILY;
				
			}
			
			//------------------------------------------------------------
			// Step 1:
			// Reset text because we don't want the TextField to expand
			// beyond what we want.
			//------------------------------------------------------------
			_textField.text = '';
			if (text == null)
				text = '';
			
			//------------------------------------------------------------
			// Step 2:
			// Enable/disable word wrap and set explicit width.
			//------------------------------------------------------------
			var initialWidth:Number = isNaN(_width) ? _maxWidth : _width; // only one will be defined
			_textField.wordWrap = !isNaN(initialWidth); // enable wordWrap when width or maxWidth is specified
			_textField.width = initialWidth;
			
			//------------------------------------------------------------
			// Step 3:
			// Unless the width and/or height are set, we want the TextField
			// to automatically expand with the text so the graphics do not
			// get clipped.  Setting the autoSize property accomplishes that.
			//------------------------------------------------------------
			var initialHeight:Number = isNaN(_height) ? _maxHeight : _height; // only one will be defined
			// if both width and height are specified, we don't want to expand at all
			if (!isNaN(initialWidth) && !isNaN(_height)) // we still need to autoSize when _maxHeight is defined
			{
				_textField.autoSize = AUTOSIZE_DISABLE;
				_textField.height = _height;
			}
			else // autoSize even when _maxHeight is defined
			{
				_textField.autoSize = AUTOSIZE_ENABLE;
				_textField.height = 0; // allow TextField to expand vertically as necessary
			}
			
			//------------------------------------------------------------
			// Step 4:
			// Set text AFTER all other options have been set, so autoSize
			// will work as we want it to.
			//------------------------------------------------------------
			_textField.defaultTextFormat = textFormat; // set defaultTextFormat BEFORE setting the text property, so it will take this format.
			_textField.text = trim ? StringUtil.trim(text) : text; // set text AFTER setting defaultTextFormat
			_textField.width; // this forces the textWidth to be recalculated -- DO NOT REMOVE
			//trace("BitmapText debug: ",_textField.textWidth, _textField.width, _textField.textWidth, text); // uncomment this to see why we need to access _textField.width
			
			//------------------------------------------------------------
			// Step 5:
			// If maxWidth or maxHeight was set, handle this behavior now.
			//------------------------------------------------------------
			// check if the text has wrapped to too many lines (more than 1).
			if (!isNaN(initialHeight) && _textField.textHeight > initialHeight && _textField.numLines > 1) // false when no height was set, true when text has wrapped to too many lines
			{
				// text wrapped to more than 1 line and is now too tall.
				// disable auto size and set maximum height before we perform truncation.
				_textField.autoSize = AUTOSIZE_DISABLE;
				_textField.height = initialHeight;
			}
			
			//------------------------------------------------------------
			// Step 6:
			// If the wrapped text does not fit in the specified height,
			// append "..." and truncate the text until it fits.
			//------------------------------------------------------------
			if (!_textFits && _textField.autoSize == AUTOSIZE_DISABLE)
			{
				var fullText:String = _textField.text;
				var cropLength:int = Math.ceil(fullText.length / 2);
				var step:int = cropLength;
				var lastStep:Boolean = false;
				while (true)
				{
					if (cropLength == 0)
						_textField.text = '';
					else if (ellipsisLocation == ELLIPSIS_LOCATION_CENTER)
						_textField.text = fullText.slice(0, Math.ceil(cropLength / 2)) + '...' + fullText.slice(fullText.length - Math.floor(cropLength / 2));
					else if (ellipsisLocation == ELLIPSIS_LOCATION_LEFT) 
						_textField.text = '...' + fullText.slice(fullText.length - cropLength);
					else // right
						_textField.text = fullText.slice(0, cropLength) + '...';

					step = Math.ceil(step / 2); // binary search

					if (_textFits)
					{
						// if text fits and this is the last step, we are done
						if (lastStep)
							break;
						
						cropLength += step; // include more text
					}
					else
					{
						cropLength -= step; // include less text
						if (!lastStep && cropLength < 1)
							cropLength = 1;
					}
					// when step size is 1, begin the last step
					if (step == 1)
						lastStep = true;
				}
				// if we truncated to 1 character plus "...", just use one character.
				if (cropLength == 1)
				{
					if (ellipsisLocation == ELLIPSIS_LOCATION_LEFT)
						_textField.text = fullText.slice(fullText.length - 1, 1);
					else
						_textField.text = fullText.slice(0, 1);
				}
			}

			//------------------------------------------------------------
			// Step 7:
			// After the text fits vertically, if maxWidth was set,
			// compact the text horizontally to remove empty space.
			//------------------------------------------------------------
			if (!isNaN(_maxWidth) && _textField.textWidth < _maxWidth) // false when _maxWidth is NaN, true when text hasn't wrapped.
			{
				// check if text hasn't wrapped to a second line
				if (_textField.numLines == 1)
				{
					// text didn't wrap, so don't keep width at maximum.
					// make TextField fit the size of the text.
					_textField.autoSize = AUTOSIZE_ENABLE;
					_textField.wordWrap = false;
					
					// if absolute height is specified, enforce it now.
					if (!isNaN(_height))
					{
						_textField.autoSize = AUTOSIZE_DISABLE;
						_textField.height = _height;
					}
				}
				else // more than one line, and textWidth < _maxWidth
				{
					// remember the original height we want to preserve
					var originalHeight:Number = _textField.textHeight;
					// resize text field to be the appropriate width.
					// setting width equal to textWidth causes the words to wrap differently.
					// this may cause the text to become more compact without changing textHeight.
					// keep doing this as long as the textWidth changes and height is the same (text becomes more compact).
					while (_textField.width > _textField.textWidth && _textField.textHeight == originalHeight)
						_textField.width = _textField.textWidth;
					// textHeight is now different.  increase the width until textHeight becomes originalHeight.
					while (_textField.textHeight > originalHeight)
					{
						_textField.width++;
						// prevent an infinite loop just in case.
						if (_textField.width > _maxWidth)
						{
							_textField.width = _maxWidth;
							break;
						}
					}
				}
			}
			
			//------------------------------------------------------------
			// Step 8:
			// After truncation and word-wrapping is finalized, enable
			// autoSize so the last line of text does not get clipped
			// due to a slight difference between height and textHeight.
			//------------------------------------------------------------
			_textField.autoSize = AUTOSIZE_ENABLE;
		}
		
		/**
		 * @private
		 * This function checks if the text currently set in the _textField fits, given the width/height settings.
		 * This function assumes _textField has already been updated to have the correct values.
		 */
		private function get _textFits():Boolean
		{
			_textField.width; // this forces the textWidth to be recalculated -- DO NOT REMOVE
			if (_textField.numLines > 1)
				return _textField.textHeight <= _textField.height;
			else
				return _textField.textWidth <= _textField.width;
		}
		
		
		/**
		 * This function will prepare the Matrix object for use with BitmapData.draw() to rotate and translate the TextField graphics.
		 */
		private function prepareMatrix():void
		{
			// prepare Matrix for translation & rotation
			_matrix.identity();
			
			// align 0,0 coordinate to right or center of text, if specified
			if (horizontalAlign == HORIZONTAL_ALIGN_CENTER)
				_matrix.translate(- _textField.width / 2, 0);
			else if (horizontalAlign == HORIZONTAL_ALIGN_RIGHT) // x is aligned to right side of text
				_matrix.translate(- _textField.width, 0);
			
			if (verticalAlign == VERTICAL_ALIGN_MIDDLE)
				_matrix.translate(0, - _textField.height / 2);
			else if (verticalAlign == VERTICAL_ALIGN_BOTTOM)
				_matrix.translate(0, - _textField.height);
			
			// rotate text around alignment point
			_matrix.rotate(angle * Math.PI / 180);
			// move rotated text
			if (roundCoords)
				_matrix.translate(Math.round(x), Math.round(y));
			else
				_matrix.translate(x, y);
		}

		
		/**
		 * This function sets up the internal TextField and calls destination.draw() using all the given parameters.
		 * @param destination
		 * @param matrix
		 * @param colorTransform
		 * @param blendMode
		 * @param clipRect
		 * @param smoothing
		 */
		public function draw(
				destination:BitmapData,
				matrix:Matrix=null,
				colorTransform:ColorTransform=null,
				blendMode:String=null,
				clipRect:Rectangle=null,
				smoothing:Boolean=false,
				wordWrap:Boolean=false 
			):void
		{
			// if text is empty, do nothing
			if (text == null || text == '')
				return;

			prepareTextField();

			prepareMatrix();
			
			
			
			if (matrix != null)
				_matrix.concat(matrix);

			if (debug)
			{
				//draw corners for debugging
				var p1:Point = _matrix.transformPoint(new Point(0, 0));
				var p2:Point = _matrix.transformPoint(new Point(_textField.width, _textField.height));
				var p3:Point = _matrix.transformPoint(new Point(_textField.width, 0));
				var p4:Point = _matrix.transformPoint(new Point(0, _textField.height));
				for each (var p:Point in [p1,p2,p3,p4])
					destination.fillRect(new Rectangle(int(p.x)-1,int(p.y)-1,3,3), 0xFF000000);
				_textField.border = true;
			}
			else
				_textField.border = false;
			
			destination.draw(_textField, _matrix, colorTransform, blendMode, clipRect, smoothing);
		}

		/**
		 * This function retrieves unrotated min,max coordinates corresponding to the text that is currently saved in the BitmapText object.
		 * Rotation is not considered when generating these coordinates.
		 * @param outputBounds A Bounds2D object to store the resulting coordinates in.
		 */
		public function getUnrotatedBounds(outputBounds:IBounds2D):void
		{
			prepareTextField();
			
			var x:Number = this.x;
			var y:Number = this.y;
			if (roundCoords)
			{
				x = Math.round(x);
				y = Math.round(y);
			}
			
			switch (verticalAlign)
			{
				default: // default vertical align: top
				case VERTICAL_ALIGN_TOP: 
					outputBounds.setYRange(y, y + _textField.height);
					break;
				case VERTICAL_ALIGN_MIDDLE: 
					outputBounds.setYRange(y - _textField.height / 2, y + _textField.height / 2);
					break;
				case VERTICAL_ALIGN_BOTTOM:
					outputBounds.setYRange(y - _textField.height, y);
					break;
			}
			
			switch (horizontalAlign)
			{
				default: // default horizontal align: left
				case HORIZONTAL_ALIGN_LEFT: // x is aligned to left side of text
					outputBounds.setXRange(x, x + _textField.width);
					break;
				case HORIZONTAL_ALIGN_CENTER: 
					outputBounds.setXRange(x - _textField.width / 2, x + _textField.width / 2);
					break;
				case HORIZONTAL_ALIGN_RIGHT: // x is aligned to right side of text
					outputBounds.setXRange(x - _textField.width, x);
					break;
			}
		}
		
		/**
		 * This function will get the TextLineMetrics of the text at a specified line.
		 * @param lineIndex The index of the line.
		 * @return The TextLineMetrics of the specified line in the text. 
		 */			
		public function getLineMetrics(lineIndex:uint):TextLineMetrics
		{
			return _textField.getLineMetrics(lineIndex);
		}
		
//		public function set wordWrap(val:Boolean):void
//		{
//			_textField.wordWrap = val;
//		}
//		public function get wordWrap():Boolean
//		{
//			return _textField.wordWrap;
//		}
	}
}
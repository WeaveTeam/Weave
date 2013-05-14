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
	import flash.geom.Point;
	
	import weave.api.primitives.IBounds2D;

	/**
	 * 
	 * @author adufilie
	 */
	public class PointGraphics
	{
		public function PointGraphics(screenBounds:IBounds2D, dataBounds:IBounds2D)
		{
			_screenBounds = screenBounds;
			_dataBounds = dataBounds;
		}
		
		private var _dataBounds:IBounds2D;
		private var _screenBounds:IBounds2D;
		
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _isData:Boolean = true;

		private var _angle:Number = 0;
		private var _isDegrees:Boolean = true;
		
		private var _point:Point = new Point();
		
		public function getX():Number
		{
			return _x;
		}
		public function getY():Number
		{
			return _y;
		}
		public function getPoint(output:Point = null):Point
		{
			if (output == null)
				output = _point;
			output.x = _x;
			output.y = _y;
			return output;
		}
		public function getScreenPoint(output:Point = null):Point
		{
			if (output == null)
				output = _point;
			output.x = _x;
			output.y = _y;
			if (_isData)
				_dataBounds.projectPointTo(output, _screenBounds);
			return output;
		}
		public function getDataPoint(output:Point = null):Point
		{
			if (output == null)
				output = _point;
			output.x = _x;
			output.y = _y;
			if (!_isData)
				_screenBounds.projectPointTo(output, _dataBounds);
			return output;
		}
		public function getScreenBounds():IBounds2D
		{
			return _screenBounds;
		}
		public function getDataBounds():IBounds2D
		{
			return _screenBounds;
		}
		
		public function screenBounds(b:IBounds2D):PointGraphics
		{
			_screenBounds = b;
			return this;
		}
		public function dataBounds(b:IBounds2D):PointGraphics
		{
			_screenBounds = b;
			return this;
		}
		public function data(x:Number = NaN, y:Number = NaN):PointGraphics
		{
			if (!_isData)
			{
				_point.x = _x;
				_point.y = _y;
				_screenBounds.projectPointTo(_point, _dataBounds);
				_x = _point.x;
				_y = _point.y;
			}
			if (isFinite(x))
				x = _x;
			if (isFinite(y))
				y = _y;
			_isData = true;
			return this;
		}
		public function screen(x:Number = NaN, y:Number = NaN):PointGraphics
		{
			if (_isData)
			{
				_point.x = _x;
				_point.y = _y;
				_dataBounds.projectPointTo(_point, _screenBounds);
				_x = _point.x;
				_y = _point.y;
			}
			if (isFinite(x))
				x = _x;
			if (isFinite(y))
				y = _y;
			_isData = false;
			return this;
		}
		public function point(input:Point):PointGraphics
		{
			_x = input.x;
			_y = input.y;
			return this;
		}
		
		public function x(value:Number):PointGraphics
		{
			_x = value;
			return this;
		}
		public function y(value:Number):PointGraphics
		{
			_y = value;
			return this;
		}
		public function move(deltaX:Number, deltaY:Number):PointGraphics
		{
			if (isFinite(deltaX))
				_x += deltaX;
			if (isFinite(deltaY))
				_y += deltaY;
			return this;
		}
		public function moveTo(x:Number, y:Number):PointGraphics
		{
			if (isFinite(x))
				_x = x;
			if (isFinite(y))
				_y = y;
			return this;
		}
		public function moveToPoint(point:Point):PointGraphics
		{
			_x = point.x;
			_y = point.y;
			return this;
		}
		
		public function angle(a:Number):PointGraphics
		{
			_angle = a;
			return this;
		}
		public function radians(angle:Number = NaN):PointGraphics
		{
			if (isFinite(angle))
				_angle = angle;
			else if (_isDegrees)
				_angle = _angle * 180 / Math.PI;
			_isDegrees = false;
			return this;
		}
		public function degrees(angle:Number = NaN):PointGraphics
		{
			if (isFinite(angle))
				_angle = angle;
			else if (!_isDegrees)
				_angle = _angle * Math.PI / 180;
			_isDegrees = true;
			return this;
		}
		public function rotate(angle:Number):PointGraphics
		{
			_angle += angle;
			return this;
		}
		public function polarMove(distance:Number, angle:Number = NaN):PointGraphics
		{
			if (isFinite(angle))
				_angle = angle;
			_x += distance * Math.cos(_angle);
			_y += distance * Math.sin(_angle);
			return this;
		}
		public function polarMoveTo(radius:Number, angle:Number = NaN):PointGraphics
		{
			if (isFinite(angle))
				_angle = angle;
			_x = radius * Math.cos(_angle);
			_y = radius * Math.sin(_angle);
			return this;
		}
	}
}

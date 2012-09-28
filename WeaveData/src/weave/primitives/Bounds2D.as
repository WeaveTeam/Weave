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

package weave.primitives
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import weave.api.primitives.IBounds2D;
	
	/**
	 * Bounds2D provides a flexible interface to a Rectangle-like object.
	 * The bounds values are stored as xMin,yMin,xMax,yMax instead of x,y,width,height
	 * because information is lost when storing as width,height and it causes rounding
	 * errors when using includeBounds() & includePoint(), depending on the order you
	 * include multiple points.
	 * 
	 * @author adufilie
	 */
	public class Bounds2D implements IBounds2D
	{
		/**
		 * The default coordinates are all NaN so that includeCoords() will behave as expected after
		 * creating an empty Bounds2D.
		 * @param xMin The starting X coordinate.
		 * @param yMin The starting Y coordinate.
		 * @param xMax The ending X coordinate.
		 * @param yMax The ending Y coordinate.
		 */		
		public function Bounds2D(xMin:Number=NaN, yMin:Number=NaN, xMax:Number=NaN, yMax:Number=NaN)
		{
			setBounds(xMin, yMin, xMax, yMax);
		}
		
		/**
		 * These are the values defining the bounds.
		 */
		public var xMin:Number, yMin:Number, xMax:Number, yMax:Number;
		
		public function getXMin():Number
		{
			return xMin;
		}
		public function getYMin():Number
		{
			return yMin;
		}
		public function getXMax():Number
		{
			return xMax;
		}
		public function getYMax():Number
		{
			return yMax;
		}
		public function setXMin(value:Number):void
		{
			xMin = value;
		}
		public function setYMin(value:Number):void
		{
			yMin = value;
		}
		public function setXMax(value:Number):void
		{
			xMax = value;
		}
		public function setYMax(value:Number):void
		{
			yMax = value;
		}
		
		/**
		 * This function copies the bounds from another Bounds2D object.
		 * @param A Bounds2D object to copy the bounds from.
		 */
		public function copyFrom(other:IBounds2D):void
		{
			if (other == null)
			{
				reset();
				return;
			}
			var o:Bounds2D = other as Bounds2D;
			if (o)
			{
				this.xMin = o.xMin;
				this.yMin = o.yMin;
				this.xMax = o.xMax;
				this.yMax = o.yMax;
			}
			else
			{
				other.getMinPoint(tempPoint);
				setMinPoint(tempPoint);
				other.getMaxPoint(tempPoint);
				setMaxPoint(tempPoint);
			}
		}
		
		/**
		 * This function makes a copy of the Bounds2D object.
		 * @return An equivalent copy of this Bounds2D object.
		 */
		public function cloneBounds():IBounds2D
		{
			return new Bounds2D(xMin, yMin, xMax, yMax);
		}

		/**
		 * For the x and y dimensions, this function swaps min and max values if min > max.
		 */
		public function makeSizePositive():void
		{
			var temp:Number;
			// make width positive
			if (xMin > xMax)
			{
				temp = xMin;
				xMin = xMax;
				xMax = temp;
			}
			// make height positive
			if (yMin > yMax)
			{
				temp = yMin;
				yMin = yMax;
				yMax = temp;
			}
		}
		
		/**
		 * This function resets all coordinates to NaN.
		 */
		public function reset():void
		{
			xMin = NaN;
			yMin = NaN;
			xMax = NaN;
			yMax = NaN;
		}
		
		/**
		 * This function checks if any coordinates are undefined or infinite.
		 * @return true if any coordinate is not a finite number.
		 */
		public function isUndefined():Boolean
		{
			return !isFinite(xMin) || !isFinite(yMin) || !isFinite(xMax) || !isFinite(yMax);
		}
		
		/**
		 * This function checks if the Bounds2D is empty.
		 * @return true if the width or height is 0, or is undefined.
		 */
		public function isEmpty():Boolean
		{
			return xMin == xMax
				|| yMin == yMax
				|| isUndefined();
		}
		
		/**
		 * This function compares the Bounds2D with another Bounds2D.
		 * @param other Another Bounds2D to compare to
		 * @return true if given Bounds2D is equivalent, even if values are undefined
		 */
		public function equals(other:IBounds2D):Boolean
		{
			if (other == null)
				return isUndefined();
			var o:Bounds2D = other as Bounds2D;
			if (!o)
				return other.equals(this);
			return (xMin == o.xMin || (isNaN(xMin) && isNaN(o.xMin)))
				&& (yMin == o.yMin || (isNaN(yMin) && isNaN(o.yMin)))
				&& (xMax == o.xMax || (isNaN(xMax) && isNaN(o.xMax)))
				&& (yMax == o.yMax || (isNaN(yMax) && isNaN(o.yMax)));
		}
		
		/**
		 * This function sets the four coordinates that define the bounds.
		 * @param xMin The new xMin value.
		 * @param yMin The new yMin value.
		 * @param xMax The new xMax value.
		 * @param yMax The new yMax value.
		 */
		public function setBounds(xMin:Number, yMin:Number, xMax:Number, yMax:Number):void
		{
			// allow any values for fastest performance
			this.xMin = xMin;
			this.yMin = yMin;
			this.xMax = xMax;
			this.yMax = yMax;
		}

		/**
		 * This function sets the bounds coordinates using x, y, width and height values.
		 * @param x The new xMin value.
		 * @param y The new yMin value.
		 * @param width The new width of the bounds.
		 * @param height The new height of the bounds.
		 */
		public function setRectangle(x:Number, y:Number, width:Number, height:Number):void
		{
			// allow any values for fastest performance
			this.xMin = x;
			this.yMin = y;
			this.xMax = x + width;
			this.yMax = y + height;
		}
		
		/**
		 * This function copies the values from this Bounds2D object into a Rectangle object.
		 * @param output A Rectangle to store the result in.
		 * @param makeSizePositive If true, this will give the Rectangle positive width/height values.
		 * @return Either the given output Rectangle, or a new Rectangle if none was specified.
		 */
		public function getRectangle(output:Rectangle = null, makeSizePositive:Boolean = true):Rectangle
		{
			if (output == null)
				output = new Rectangle();
			if (makeSizePositive)
			{
				output.x = getXNumericMin();
				output.y = getYNumericMin();
				output.width = getXCoverage();
				output.height = getYCoverage();
			}
			else
			{
				output.x = xMin;
				output.y = yMin;
				output.width = getWidth();
				output.height = getHeight();
			}
			return output;
		}
		
		/**
		 * This will apply transformations to an existing Matrix for projecting coordinates from this bounds to another.
		 * @param destinationBounds The destination bounds used to calculate the transformation.
		 * @param outputMatrix The Matrix used to store the transformation.
		 * @param startWithIdentity If this is true, then outputMatrix.identity() will be applied first.
		 */
		public function transformMatrix(destinationBounds:IBounds2D, outputMatrix:Matrix, startWithIdentity:Boolean):void
		{
			if (startWithIdentity)
				outputMatrix.identity();
			outputMatrix.translate(-xMin, -yMin);
			outputMatrix.scale(
				destinationBounds.getWidth() / getWidth(),
				destinationBounds.getHeight() / getHeight()
			);
			outputMatrix.translate(destinationBounds.getXMin(), destinationBounds.getYMin());
		}

		/**
		 * This function will expand this Bounds2D to include a point.
		 * @param newPoint A point to include in this Bounds2D.
		 */
		public function includePoint(newPoint:Point):void
		{
			includeCoords(newPoint.x, newPoint.y);
		}

		/**
		 * This function will expand this Bounds2D to include a point.
		 * @param newX The X coordinate of a point to include in this Bounds2D.
		 * @param newY The Y coordinate of a point to include in this Bounds2D.
		 */
		public function includeCoords(newX:Number, newY:Number):void
		{
			if (isFinite(newX))
			{
				// If x coordinates are undefined, define them now.
				if (isNaN(this.xMin))
				{
					if (isNaN(this.xMax))
						this.xMin = this.xMax = newX;
					else
						this.xMin = this.xMax;
				}
				else if (isNaN(this.xMax))
					this.xMax = this.xMin;
				// update min,max values for both positive and negative width values
				if (xMin > xMax) // negative width
				{
					if (newX > xMin) xMin = newX; // xMin = Math.max(xMin, newX);
					if (newX < xMax) xMax = newX; // xMax = Math.min(xMax, newX);
				}
				else // positive width
				{
					if (newX < xMin) xMin = newX; // xMin = Math.min(xMin, newX);
					if (newX > xMax) xMax = newX; // xMax = Math.max(xMax, newX);
				}
			}
			if (isFinite(newY))
			{
				// If y coordinates are undefined, define them now.
				if (isNaN(this.yMin))
				{
					if (isNaN(this.yMax))
						this.yMin = this.yMax = newY;
					else
						this.yMin = this.yMax;
				}
				else if (isNaN(this.yMax))
					this.yMax = this.yMin;
				// update min,max values for both positive and negative height values
				if (yMin > yMax) // negative height
				{
					if (newY > yMin) yMin = newY; // yMin = Math.max(yMin, newY);
					if (newY < yMax) yMax = newY; // yMax = Math.min(yMax, newY);
				}
				else // positive height
				{
					if (newY < yMin) yMin = newY; // yMin = Math.min(yMin, newY);
					if (newY > yMax) yMax = newY; // yMax = Math.max(yMax, newY);
				}
			}
		}
		
		/**
		 * This function will expand this Bounds2D to include another Bounds2D.
		 * @param otherBounds Another Bounds2D object to include within this Bounds2D.
		 */
		public function includeBounds(otherBounds:IBounds2D):void
		{
			var o:Bounds2D = otherBounds as Bounds2D;
			if (o)
			{
				includeCoords(o.xMin, o.yMin);
				includeCoords(o.xMax, o.yMax);
			}
			else
			{
				otherBounds.getMinPoint(tempPoint);
				includePoint(tempPoint);
				otherBounds.getMaxPoint(tempPoint);
				includePoint(tempPoint);
			}
		}

		// re-usable temporary objects
		private static const staticBounds2D_A:Bounds2D = new Bounds2D();
		private static const staticBounds2D_B:Bounds2D = new Bounds2D();

		// this function supports comparisons of bounds with negative width/height
		public function overlaps(other:IBounds2D, includeEdges:Boolean = true):Boolean
		{
			// load re-usable objects and make sizes positive to make it easier to compare
			var a:Bounds2D = staticBounds2D_A;
			a.copyFrom(this);
			a.makeSizePositive();

			var b:Bounds2D = staticBounds2D_B;
			b.copyFrom(other);
			b.makeSizePositive();

			// test for overlap
			if (includeEdges)
				return a.xMin <= b.xMax && b.xMin <= a.xMax
					&& a.yMin <= b.yMax && b.yMin <= a.yMax;
			else
				return a.xMin < b.xMax && b.xMin < a.xMax
					&& a.yMin < b.yMax && b.yMin < a.yMax;
		}


		/**
		 * This function supports a Bounds2D object having negative width & height, unlike the Rectangle object
		 * @param point A point to test.
		 * @return A value of true if the point is contained within this Bounds2D.
		 */
		public function containsPoint(point:Point):Boolean
		{
			return contains(point.x, point.y);
		}
		
		/**
		 * This function supports a Bounds2D object having negative width & height, unlike the Rectangle object
		 * @param x An X coordinate for a point.
		 * @param y A Y coordinate for a point.
		 * @return A value of true if the point is contained within this Bounds2D.
		 */
		public function contains(x:Number, y:Number):Boolean
		{
			return ( (xMin < xMax) ? (xMin <= x && x <= xMax) : (xMax <= x && x <= xMin) )
				&& ( (yMin < yMax) ? (yMin <= y && y <= yMax) : (yMax <= y && y <= yMin) );
		}
		
		/**
		 * This function supports a Bounds2D object having negative width & height, unlike the Rectangle object
		 * @param other Another Bounds2D object to check.
		 * @return A value of true if the other Bounds2D is contained within this Bounds2D.
		 */
		public function containsBounds(other:IBounds2D):Boolean
		{
			var o:Bounds2D = other as Bounds2D;
			if (o)
			{
				return contains(o.xMin, o.yMin)
					&& contains(o.xMax, o.yMax);
			}
			
			other.getMinPoint(tempPoint);
			if (containsPoint(tempPoint))
			{
				other.getMaxPoint(tempPoint);
				return containsPoint(tempPoint);
			}
			return false;
		}
		
		/**
		 * This function is used to determine which vertices of a polygon can be skipped when rendering within the bounds of this Bounds2D.
		 * While iterating over vertices, test each one with this function.
		 * If (firstGridTest & secondGridTest & thirdGridTest) is non-zero, then the second vertex can be skipped.
		 * @param x The x-coordinate to test.
		 * @param y The y-coordinate to test.
		 * @return A value to be ANDed with other results of getGridTest().
		 */
		public function getGridTest(x:Number, y:Number):uint
		{
			// Note: This function is optimized for speed
			
			// If three consecutive vertices all share one of (X_HI, X_LO, Y_HI, Y_LO) test results,
			// then the middle point can be skipped when rendering inside the bounds.
			
			var xPositive:Boolean = xMin < xMax;
			var yPositive:Boolean = yMin < yMax;
			var xTest:uint = 0;
			
			if (x < (xPositive ? xMin : xMax))
				xTest = 0x0001; // X_LO
			else if (x > (xPositive ? xMax : xMin))
				xTest = 0x0010; // X_HI
			
			if (y < (yPositive ? yMin : yMax))
				return xTest | 0x0100; // Y_LO
			else if (y > (yPositive ? yMax : yMin)) 
				return xTest | 0x1000; // Y_HI
			
			return xTest;
		}
		
		/**
		 * This function projects the coordinates of a Point object from this bounds to a
		 * destination bounds. The specified point object will be modified to contain the result.
		 * @param point The Point object containing coordinates to project.
		 * @param toBounds The destination bounds.
		 */
		public function projectPointTo(point:Point, toBounds:IBounds2D):void
		{
			// this function is optimized for speed
			var toXMin:Number;
			var toXMax:Number;
			var toYMin:Number;
			var toYMax:Number;
			var tb:Bounds2D = toBounds as Bounds2D;
			if (tb)
			{
				toXMin = tb.xMin;
				toXMax = tb.xMax;
				toYMin = tb.yMin;
				toYMax = tb.yMax;
			}
			else
			{
				toBounds.getMinPoint(tempPoint);
				toXMin = tempPoint.x;
				toYMin = tempPoint.y;
				toBounds.getMaxPoint(tempPoint);
				toXMax = tempPoint.x;
				toYMax = tempPoint.y;
			}
			
			var x:Number = toXMin + (point.x - xMin) / (xMax - xMin) * (toXMax - toXMin);

			if (x < Infinity) // alternative to !isNaN()
				point.x = x;
			else
				point.x = (toXMin + toXMax) / 2;

			var y:Number = toYMin + (point.y - yMin) / (yMax - yMin) * (toYMax - toYMin);
			
			if (y < Infinity) // alternative to !isNaN()
				point.y = y;
			else
				point.y = (toYMin + toYMax) / 2;
		}
		
		/**
		 * This function projects all four coordinates of a Bounds2D object from this bounds
		 * to a destination bounds. The specified coords object will be modified to contain the result.
		 * @param inputAndOutput A Bounds2D object containing coordinates to project.
		 * @param toBounds The destination bounds.
		 */		
		public function projectCoordsTo(coords:IBounds2D, toBounds:IBounds2D):void
		{
			// project min coords
			coords.getMinPoint(tempPoint);
			projectPointTo(tempPoint, toBounds);
			coords.setMinPoint(tempPoint);
			// project max coords
			coords.getMaxPoint(tempPoint);
			projectPointTo(tempPoint, toBounds);
			coords.setMaxPoint(tempPoint);
		}

		/**
		 * This constrains a point to be within this Bounds2D. The specified point object will be modified to contain the result.
		 * @param point The point to constrain.
		 */
		public function constrainPoint(point:Point):void
		{
			// find numerical min,max x values and constrain x coordinate
			if (!isNaN(xMin) && !isNaN(xMax)) // do not constrain point if bounds is undefined
				point.x = Math.max(Math.min(xMin, xMax), Math.min(point.x, Math.max(xMin, xMax)));
			
			// find numerical min,max y values and constrain y coordinate
			if (!isNaN(yMin) && !isNaN(yMax)) // do not constrain point if bounds is undefined
				point.y = Math.max(Math.min(yMin, yMax), Math.min(point.y, Math.max(yMin, yMax)));
		}

		// reusable temporary objects
		private static const tempPoint:Point = new Point();
		private static const staticRange_A:Range = new Range();
		private static const staticRange_B:Range = new Range();
		
		/**
		 * This constrains the center point of another Bounds2D to be overlapping the center of this Bounds2D.
		 * The specified boundsToConstrain object will be modified to contain the result.
		 * @param boundsToConstrain The Bounds2D objects to constrain.
		 */
		public function constrainBoundsCenterPoint(boundsToConstrain:IBounds2D):void
		{
			if (isUndefined())
				return;
			// find the point in the boundsToConstrain closest to the center point of this bounds
			// then offset the boundsToConstrain so it overlaps the center point of this bounds
			boundsToConstrain.getCenterPoint(tempPoint);
			constrainPoint(tempPoint);
			boundsToConstrain.setCenterPoint(tempPoint);
		}

		/**
		 * This function will reposition a bounds such that for the x and y dimensions of this
		 * bounds and another bounds, at least one bounds will completely contain the other bounds.
		 * The specified boundsToConstrain object will be modified to contain the result.
		 * @param boundsToConstrain the bounds we want to constrain to be within this bounds
		 * @param preserveSize if set to true, width,height of boundsToConstrain will remain the same
		 */
		public function constrainBounds(boundsToConstrain:IBounds2D, preserveSize:Boolean = true):void
		{
			if (preserveSize)
			{
				var b2c:Bounds2D = boundsToConstrain as Bounds2D;
				if (!b2c)
				{
					staticBounds2D_A.copyFrom(boundsToConstrain);
					b2c = staticBounds2D_A;
				}
				// constrain x values
				staticRange_A.setRange(this.xMin, this.xMax);
				staticRange_B.setRange(b2c.xMin, b2c.xMax);
				staticRange_A.constrainRange(staticRange_B);
				boundsToConstrain.setXRange(staticRange_B.begin, staticRange_B.end);
				// constrain y values
				staticRange_A.setRange(this.yMin, this.yMax);
				staticRange_B.setRange(b2c.yMin, b2c.yMax);
				staticRange_A.constrainRange(staticRange_B);
				boundsToConstrain.setYRange(staticRange_B.begin, staticRange_B.end);
			}
			else
			{
				// constrain min point
				boundsToConstrain.getMinPoint(tempPoint);
				constrainPoint(tempPoint);
				boundsToConstrain.setMinPoint(tempPoint);
				// constrain max point
				boundsToConstrain.getMaxPoint(tempPoint);
				constrainPoint(tempPoint);
				boundsToConstrain.setMaxPoint(tempPoint);
			}
		}

		public function offset(xOffset:Number, yOffset:Number):void
		{
			xMin += xOffset;
			xMax += xOffset;
			yMin += yOffset;
			yMax += yOffset;
		}

		public function setXRange(xMin:Number, xMax:Number):void
		{
			this.xMin = xMin;
			this.xMax = xMax;
		}
		
		public function setYRange(yMin:Number, yMax:Number):void
		{
			this.yMin = yMin;
			this.yMax = yMax;
		}
		
		public function setCenteredXRange(xCenter:Number, width:Number):void
		{
			this.xMin = xCenter - width / 2;
			this.xMax = xCenter + width / 2;
		}

		public function setCenteredYRange(yCenter:Number, height:Number):void
		{
			this.yMin = yCenter - height / 2;
			this.yMax = yCenter + height / 2;
		}

		public function setCenteredRectangle(xCenter:Number, yCenter:Number, width:Number, height:Number):void
		{
			setCenteredXRange(xCenter, width);
			setCenteredYRange(yCenter, height);
		}

		/**
		 * This function will set the width and height to the new values while keeping the
		 * center point constant.  This function works with both positive and negative values.
		 */
		public function centeredResize(width:Number, height:Number):void
		{
			setCenteredXRange(getXCenter(), width);
			setCenteredYRange(getYCenter(), height);
		}

		public function getXCenter():Number
		{
			return (xMin + xMax) / 2;
		}
		public function setXCenter(xCenter:Number):void
		{
			if (isNaN(xMin) || isNaN(xMax))
				xMin = xMax = xCenter;
			else
			{
				var xShift:Number = xCenter - (xMin + xMax) / 2;
				xMin += xShift;
				xMax += xShift;
			}
		}
		
		public function getYCenter():Number
		{
			return (yMin + yMax) / 2;
		}
		public function setYCenter(yCenter:Number):void
		{
			if (isNaN(yMin) || isNaN(yMax))
				yMin = yMax = yCenter;
			else
			{
				var yShift:Number = yCenter - (yMin + yMax) / 2;
				yMin += yShift;
				yMax += yShift;
			}
		}
		
		/**
		 * This function stores the xCenter and yCenter coordinates into a Point object.
		 * @param value The Point object to store the xCenter and yCenter coordinates in.
		 */
		public function getCenterPoint(output:Point):void
		{
			output.x = getXCenter();
			output.y = getYCenter();
		}
		
		/**
		 * This function will shift the bounds coordinates so that the xCenter and yCenter
		 * become the coordinates in a specified Point object.
		 * @param value The Point object containing the desired xCenter and yCenter coordinates.
		 */
		public function setCenterPoint(value:Point):void
		{
			this.setXCenter(value.x);
			this.setYCenter(value.y);
		}
		
		/**
		 * This function will shift the bounds coordinates so that the xCenter and yCenter
		 * become the specified values.
		 * @param xCenter The desired value for xCenter.
		 * @param yCenter The desired value for yCenter.
		 */
		public function setCenter(xCenter:Number, yCenter:Number):void
		{
			this.setXCenter(xCenter);
			this.setYCenter(yCenter);
		}
		
		/**
		 * This function stores the xMin and yMin coordinates in a Point object. 
		 * @param output The Point to store the xMin and yMin coordinates in.
		 */		
		public function getMinPoint(output:Point):void
		{
			output.x = xMin;
			output.y = yMin;
		}
		/**
		 * This function sets the xMin and yMin values from a Point object. 
		 * @param value The Point containing new xMin and yMin coordinates.
		 */		
		public function setMinPoint(value:Point):void
		{
			xMin = value.x;
			yMin = value.y;
		}

		/**
		 * This function stores the xMax and yMax coordinates in a Point object. 
		 * @param output The Point to store the xMax and yMax coordinates in.
		 */		
		public function getMaxPoint(output:Point):void
		{
			output.x = xMax;
			output.y = yMax;
		}
		/**
		 * This function sets the xMax and yMax values from a Point object. 
		 * @param value The Point containing new xMax and yMax coordinates.
		 */		
		public function setMaxPoint(value:Point):void
		{
			xMax = value.x;
			yMax = value.y;
		}
		
		/**
		 * This function sets the xMin and yMin values.
		 * @param x The new xMin coordinate.
		 * @param y The new yMin coordinate.
		 */		
		public function setMinCoords(x:Number, y:Number):void
		{
			xMin = x;
			yMin = y;
		}
		/**
		 * This function sets the xMax and yMax values.
		 * @param x The new xMax coordinate.
		 * @param y The new yMax coordinate.
		 */		
		public function setMaxCoords(x:Number, y:Number):void
		{
			xMax = x;
			yMax = y;
		}

		/**
		 * This is equivalent to ObjectUtil.numericCompare(xMax, xMin)
		 */		
		public function getXDirection():Number
		{
			if (xMin > xMax)
				return -1;
			if (xMin < xMax)
				return 1;
			return 0;
		}
		
		/**
		 * This is equivalent to ObjectUtil.numericCompare(yMax, yMin)
		 */		
		public function getYDirection():Number
		{
			if (yMin > yMax)
				return -1;
			if (yMin < yMax)
				return 1;
			return 0;
		}

		/**
		 * The width of the bounds is defined as xMax - xMin.
		 */		
		public function getWidth():Number
		{
			var _width:Number = xMax - xMin;
			return isNaN(_width) ? 0 : _width;
		}
		
		/**
		 * The height of the bounds is defined as yMax - yMin.
		 */		
		public function getHeight():Number
		{
			var _height:Number = yMax - yMin;
			return isNaN(_height) ? 0 : _height;
		}

		/**
		 * This function will set the width by adjusting the xMin and xMax values relative to xCenter.
		 * @param value The new width value.
		 */
		public function setWidth(value:Number):void
		{
			setCenteredXRange(getXCenter(), value);
		}
		/**
		 * This function will set the height by adjusting the yMin and yMax values relative to yCenter.
		 * @param value The new height value.
		 */
		public function setHeight(value:Number):void
		{
			setCenteredYRange(getYCenter(), value);
		}

		/**
		 * Area is defined as the absolute value of width * height.
		 * @return The area of the bounds.
		 */		
		public function getArea():Number
		{
			var area:Number = (xMax - xMin) * (yMax - yMin);
			return (area < 0) ? -area : area; // Math.abs(area);
		}
		
		/**
		 * The xCoverage is defined as the absolute value of the width.
		 * @return The xCoverage of the bounds.
		 */
		public function getXCoverage():Number
		{
			return (xMin < xMax) ? (xMax - xMin) : (xMin - xMax); // Math.abs(xMax - xMin);
		}
		/**
		 * The yCoverage is defined as the absolute value of the height.
		 * @return The yCoverage of the bounds.
		 */
		public function getYCoverage():Number
		{
			return (yMin < yMax) ? (yMax - yMin) : (yMin - yMax); // Math.abs(yMax - yMin);
		}
		
		/**
		 * The xNumericMin is defined as the minimum of xMin and xMax.
		 * @return The numeric minimum x coordinate.
		 */
		public function getXNumericMin():Number
		{
			return xMin < xMax ? xMin : xMax; // Math.min(xMin, xMax);
		}
		/**
		 * The yNumericMin is defined as the minimum of yMin and yMax.
		 * @return The numeric minimum y coordinate.
		 */
		public function getYNumericMin():Number
		{
			return yMin < yMax ? yMin : yMax; // Math.min(yMin, yMax);
		}
		/**
		 * The xNumericMax is defined as the maximum of xMin and xMax.
		 * @return The numeric maximum x coordinate.
		 */
		public function getXNumericMax():Number
		{
			return xMax > xMin ? xMax : xMin; // Math.max(xMin, xMax);
		}
		/**
		 * The xNumericMax is defined as the maximum of xMin and xMax.
		 * @return The numeric maximum y coordinate.
		 */
		public function getYNumericMax():Number
		{
			return yMax > yMin ? yMax : yMin; // Math.max(yMin, yMax);
		}
		
		/**
		 * This function returns a String suitable for debugging the Bounds2D coordinates.
		 * @return A String containing the coordinates of the bounds.
		 */
		public function toString():String
		{
			return "(xMin="+xMin+", "+"yMin="+yMin+", "+"xMax="+xMax+", "+"yMax="+yMax+")";
		}
		
		/*
		
		public function getTweenCoords():Array
		{
			return [xMin, yMin, xMax, yMax];
		}
		
		public function isTweening():Boolean
		{
			return tween != null;
		}
		
		private var tween:Tween = null;
		private var _tweenEndCoords:Array = null;
		public function getTweenEndCoords():Array
		{
			if (tween != null)
				return _tweenEndCoords;
			return getTweenCoords();
		}
		
		private var _tweenEndBounds:IBounds2D = null; // reusable temporary object
		public function getTweenEndBounds():IBounds2D
		{
			if (tween != null)
			{
				if (_tweenEndBounds == null)
					_tweenEndBounds = new Bounds2D();
				_tweenEndBounds.setBounds(_tweenEndCoords[0], _tweenEndCoords[1], _tweenEndCoords[2], _tweenEndCoords[3]);
				return _tweenEndBounds;
			}
			return this;
		}
		
		public function tweenTo(tweenCoords:Array, duration:Number = 400):void
		{
			if (tween != null)
			{
				tween.stop();
				//tween.endTween();
			}
			if (this.isUndefined())
			{
				(setBounds as Function).apply(this, tweenCoords);
			}
			else
			{
				tween = new Tween(this, getTweenCoords(), tweenCoords, duration);
				_tweenEndCoords = tweenCoords;
			}
		}
		
		public function onTweenUpdate(tweenCoords:Array):void
		{
			(setBounds as Function).apply(this, tweenCoords);
		}
		public function onTweenEnd(tweenCoords:Array):void
		{
			(setBounds as Function).apply(this, tweenCoords);
			tween = null;
		}
		
		public function stopTween():void
		{
			if (tween == null)
				return;
			tween.stop();
			tween = null;
		}
		
		*/
	}
}

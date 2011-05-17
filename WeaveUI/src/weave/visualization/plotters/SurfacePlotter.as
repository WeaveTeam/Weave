/**
 * Institute for Visualization and Perception Research
 * Indicator Visualization Platform Framework
 *
 * Web-based data visualization and mapping framework.
 *
 *
 *
 * Copyright (c) 2009-10 Institute for Visualization and Perception Research
 * Department of Computer Science
 * University of Massachusetts Lowell
 * One University Ave.
 * Lowell, Massachusetts  01854
 * U.S.A.
 * All rights reserved.
 *
 * Warning: This computer software program, including all text, graphics, the
 * selection and arrangement thereof, the algorithms, the process, and all
 * other materials in this file, including its compilation are protected by
 * copyright law and international treaties. Unauthorized copying or altering
 * thereof, in hard or soft copy, or distribution of this program or any
 * portion thereof, is expressly forbidden without prior written consent and
 * may result in severe civil and criminal penalties, and will be prosecuted
 * to the maximum extent possible under the law. Additionally, all software
 * packages, compilations, and derivatives thereof, which include this file,
 * are protected as well. Use is subject to license terms.
 */

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.primitives.IMatrix;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.WeaveMatrix;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This class draws a smooth color distribution as the background
	 * to a scatter plot of (x, y) points.
	 * 
	 * @author kmonico
	 */
	public class SurfacePlotter extends ScatterPlotPlotter
	{
		public function SurfacePlotter()
		{
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			var fill:SolidFillStyle = fillStyle.requestLocalObject(SolidFillStyle, false);
			fill.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);

			xColumn.addGroupedCallback(this, recalculateEverything);
			yColumn.addGroupedCallback(this, recalculateEverything);
			registerNonSpatialProperties(Weave.properties.axisFontUnderline,Weave.properties.axisFontSize,Weave.properties.axisFontColor);		
		}
		
		private function recalculateEverything():void
		{
			_resultVector = new WeaveMatrix(_numberLegendrePolynomials, 1);
			_polynomialMatrix = new WeaveMatrix(_numberLegendrePolynomials, _numberLegendrePolynomials);
			
			_xNormalizedVals = normalizeKeys(xColumn);
			_yNormalizedVals = normalizeKeys(yColumn);
			
			// if there is no data or the data is invalid, we can't do anything
			if (_xNormalizedVals.length != _yNormalizedVals.length || _xNormalizedVals.length == 0)
				return;
			
			var i:int;
			var j:int;
			var k:int;
			// first calculate each V vector
			for (i = 0; i < _numberLegendrePolynomials; ++i)
				_vPolyCache[i] = getVPolyVector(i);
			
//			// then calculate each Z vector
//			for (i = 0; i < _numberLegendrePolynomials; ++i)
//				_zPolyCache[i] = getZPolyVector(i);
			
			// fill the matrix
			for (i = 0; i < _numberLegendrePolynomials; ++i)
			{
				for (j = 0; j < _numberLegendrePolynomials; ++j)
				{
					// matrix[i][j] = Sum[V(i) * V(j), k = 0..n]
					_polynomialMatrix.setEntry(
						calcVProduct(i, j), 
						i, j
					);
				}
			}
			
			var invertedMatrix:IMatrix = _polynomialMatrix.invert();
			
			// fill the result vector
			for (i = 0; i < _numberLegendrePolynomials; ++i)
			{
				for (k = 0; k < _xNormalizedVals.length; ++k)
				{
					// vector[i] += z[k] * V(i)[k] 
					_resultVector.setEntry(
						_resultVector.getEntry(i, 0) + _yNormalizedVals[k] * _vPolyCache[i][k],
						i, 1
					);
				}
			}
			_coefficientsVector = invertedMatrix.multiply(_resultVector);
		}
		private function calcVProduct(left:int, right:int):Number
		{
			var result:Number = 0;
			for (var k:int = 0; k < _xNormalizedVals.length; ++k)
			{
				result += _vPolyCache[left][k] * _vPolyCache[right][k];
			}
			return result;
		}
		private function getZPolyVector(order:int):Vector.<Number>
		{
			var result:Vector.<Number> = new Vector.<Number>();
			
			
			return result;
		}

		// we want to solve for the vector C in Z = AC,
		// where C is the _coefficientsVector,
		// A is the _polynomialMatrix
		// and Z is the _resultVector.
		// To solve this, we must calculate C = A^(-1) Z
		private var _coefficientsVector:IMatrix = null;
		private var _resultVector:IMatrix = null;
		private var _polynomialMatrix:IMatrix = null;
		private const _numberLegendrePolynomials:int = 6; // use 6 legendre polynomials
		private var _xNormalizedVals:Vector.<Number> = null; // the x values between -1 and 1
		private var _yNormalizedVals:Vector.<Number> = null; // the y values between -1 and 1
		
		public const lineStyle:DynamicLineStyle = newNonSpatialProperty(DynamicLineStyle);
		public const fillStyle:DynamicFillStyle = newNonSpatialProperty(DynamicFillStyle);

		// int -> Vector.<Number>  for each of these caches
		private const _vPolyCache:Dictionary = new Dictionary(false);
		private	const _zPolyCache:Dictionary = new Dictionary(false);
		
		private const _tempMatrix:Matrix = new Matrix();
		private const _tempPoint:Point = new Point();
		private const _tempScreenBounds:IBounds2D = new Bounds2D();
		private const _tempBitmap:BitmapData = new BitmapData(16, 16, false, 0);
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (_coefficientsVector == null)
				return;
			
			_xNormalizedVals = normalizeKeys(xColumn);
			_yNormalizedVals = normalizeKeys(yColumn);

			_tempScreenBounds.copyFrom(screenBounds);
			_tempScreenBounds.makeSizePositive();
			
			/*dataBounds.getMinPoint(_tempPoint);
			dataBounds.projectPointTo(_tempPoint, _tempScreenBounds);
			var xMin:int = _tempPoint.x;
			var yMin:int = _tempPoint.y;
			dataBounds.getMaxPoint(_tempPoint);
			dataBounds.projectPointTo(_tempPoint, _tempScreenBounds);
			var xMax:int = _tempPoint.x;
			var yMax:int = _tempPoint.y;*/
			var xSize:Number = 16;
			var ySize:Number = 16;
			var xMin:Number = dataBounds.getXMin();
			var yMin:Number = dataBounds.getYMin();
			var xMax:Number = dataBounds.getXMax();
			var yMax:Number = dataBounds.getYMax();
			var xScale:Number = dataBounds.getWidth();
			var yScale:Number = dataBounds.getHeight();
			for (var x:Number = xMin; x < xMax; x += xSize)
			{
				for (var y:Number = yMin; y < yMax; y += ySize)
				{
					var color:Number = calculateColor(x / xScale, y / yScale);
					//trace(color);
					_tempBitmap.floodFill(0, 0, (Math.round(color) * 0xFF) << 16 );
					
					//_tempB
					_tempPoint.x = x;
					_tempPoint.y = y;
					dataBounds.projectPointTo(_tempPoint, screenBounds);
					
					_tempMatrix.identity();
					_tempMatrix.scale(screenBounds.getWidth() / _tempBitmap.width, screenBounds.getHeight() / _tempBitmap.height);
					_tempMatrix.translate(_tempPoint.x, _tempPoint.y);
					
					destination.draw(_tempBitmap, _tempMatrix);
				}
			}
		}	

		private function calculateColor(x:Number, y:Number):Number
		{
			var p0x:Number = calculateLegendrePolynomialValue(x, 0);
			var p0y:Number = calculateLegendrePolynomialValue(y, 0);
			var p1x:Number = calculateLegendrePolynomialValue(x, 1);
			var p1y:Number = calculateLegendrePolynomialValue(y, 1);
			var p2x:Number = calculateLegendrePolynomialValue(x, 2);
			var p2y:Number = calculateLegendrePolynomialValue(y, 2);
			
			var color:Number = (_coefficientsVector.getEntry(0, 0) * p0x * p0y 
				+ _coefficientsVector.getEntry(1, 0) * p0x * p1y
				+ _coefficientsVector.getEntry(2, 0) * p0x * p2y
				+ _coefficientsVector.getEntry(3, 0) * p1x * p0y
				+ _coefficientsVector.getEntry(4, 0) * p1x * p1y
				+ _coefficientsVector.getEntry(5, 0) * p2x * p0y) & 0xFFFFFF;
			
			return color / 0xFFFFFF;
		}
		
		private function getVPolyVector(order:int):Vector.<Number>
		{
			var result:Vector.<Number> = new Vector.<Number>();

			for (var i:int = 0; i < _xNormalizedVals.length; ++i)
			{
				switch (order)
				{
					case 0:
						result.push(calculateLegendrePolynomialValue(_xNormalizedVals[i], 0) * calculateLegendrePolynomialValue(_yNormalizedVals[i], 0));
						break;
					case 1:
						result.push(calculateLegendrePolynomialValue(_xNormalizedVals[i], 0) * calculateLegendrePolynomialValue(_yNormalizedVals[i], 1));
						break;
					case 2:
						result.push(calculateLegendrePolynomialValue(_xNormalizedVals[i], 0) * calculateLegendrePolynomialValue(_yNormalizedVals[i], 2));
						break;
					case 3:
						result.push(calculateLegendrePolynomialValue(_xNormalizedVals[i], 1) * calculateLegendrePolynomialValue(_yNormalizedVals[i], 0));
						break;
					case 4:
						result.push(calculateLegendrePolynomialValue(_xNormalizedVals[i], 1) * calculateLegendrePolynomialValue(_yNormalizedVals[i], 1));
						break;
					case 5:
						result.push(calculateLegendrePolynomialValue(_xNormalizedVals[i], 2) * calculateLegendrePolynomialValue(_yNormalizedVals[i], 0));
						break;				
				}				
			}
			return result;
		}
		
		private function calculateLegendrePolynomialValue(input:Number, order:int):Number
		{
			var returnValue:Number;
			
			switch (order)
			{
				case 0:
					returnValue = 1;
					break;
				case 1:
					returnValue = input;
					break;
				case 2:
					returnValue = (3 * input * input - 1) / 2;
					break;
				case 3:
					returnValue = input * (5 * input *input - 3) / 2;
					break;
				case 4:
					returnValue = (35 * input * input * input * input - 30 * input * input + 3) / 8;
					break;
				case 5:
					returnValue = input * (63 * input * input * input * input - 70 * input * input + 15) / 8;
					break;
				default:
					returnValue = 1;
					break;
			}
			
			return returnValue;
		}

		private function normalizeKeys(iColumn:IAttributeColumn):Vector.<Number>
		{
			var min:Number = Number.POSITIVE_INFINITY;
			var max:Number = Number.NEGATIVE_INFINITY;
			var resultVector:Vector.<Number> = new Vector.<Number>();
			
			resultVector.length = 0;
			// get the min and max values and push the key values
			var keys:Array = iColumn.keys;
			for each (var key:IQualifiedKey in keys)
			{
				var candidate:Number = iColumn.getValueFromKey(key, Number);
				
				if (candidate > max)
					max = candidate;
				if (candidate < min)
					min = candidate;
				
				resultVector.push(candidate);
			}
			
			// normalize the numbers between -1 and 1
			for (var i:int = 0; i < resultVector.length; ++i)
			{
				// shift the value so all values are positive, 
				// normalize the value, 
				// multiply the normalized value by 2 to give it range [0, 2],
				// and shift it to the range [-1, 1]
				resultVector[i] = 2 * (resultVector[i] - min) / (max - min) - 1;
			}	
			
			return resultVector;
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(-1, -1, 1, 1);
		}
	}
}
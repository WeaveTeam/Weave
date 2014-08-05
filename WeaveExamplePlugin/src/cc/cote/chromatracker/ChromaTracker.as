package cc.cote.chromatracker 
{
	
	import flash.display.Bitmap;	
	import flash.display.BitmapData;	
	import flash.display.DisplayObject;	
	import flash.filters.ColorMatrixFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BlurFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * This has been adapated by John Fallon for use in Weave.
	 * 
	 * The ChromaTracker class allows the detection of a specific color or range 
	 * of colors in any DisplayObject. It is particularly useful to track blobs 
	 * of color in a live video feed (from a camera). This class provides methods 
	 * to retrieve view the detected pixels as a normal Bitmap object or a 
	 * rectangle representing the outer boudary of detected pixels.
	 * 
	 * <p>This class is still in beta. Fell free to suggest improvements or 
	 * corrections on the project's home page.</p>
	 *
	 * @author Jean-Philippe Côté
	 * @version 1.0b
	 * @see http://www.cote.cc/projects/chromatracker ChromaTracker's Home Page
	 */
	public class ChromaTracker
	{
		
		/** The current amount of blur added */
		private var _blur:Number;
		
		/** A Bitmap object containing only the detected pixels */
		private var _bm:Bitmap;
		
		/** The current value of the brightness adjustment */
		private var _brightness:Number;
		
		/** The color to detect expressed as a 24bit unsigned integer */
		private var _color:uint;
		
		/** The current value of the contrast adjustment */
		private var _contrast:Number;
		
		/** The current value of the hue adjustment */
		private var _hue:Number;
		
		/** A dummy Point object used on several occasions in this library. */
		private const _pt:Point = new Point();
		
		/** 
		 * The outer boundaries of detected pixels expressed as a Rectangle 
		 * object
		 */
		private var _rect:Rectangle;
		
		/**
		 * Minimum detection value (after factoring in tolerance) for the red, 
		 * green and blue channels expressed as a single 24bit unsigned int
		 */
		private var _rgbMinima:uint;
		
		/**
		 * Maximum detection value (after factoring in tolerance) for the red, 
		 * green and blue channels expressed as a single 24bit unsigned int
		 */
		private var _rgbMaxima:uint;
		
		/** The current value of the saturation adjustment */
		private var _saturation:Number;
		
		/** A reference to the DisplayObject to perform detection on. */
		private var _source:DisplayObject;
		
		/** 
		 * The tolerance to use when performing color detection (above and below 
		 * target color)
		 */
		private var _tolerance:Number;
		
		/**
		 * Creates a ChromaTracker object. By default, a small amount (0.2) of 
		 * tolerance and blur is used. The blur is particularly useful to get 
		 * rid of stray single pixels.
		 * 
		 * Please note that lighting conditions must be controlled to achieve a 
		 * reliable detection.
		 * 
		 * @param source DisplayObject upon which to perform color detection 
		 * (MovieClip, Video, Bitmap, etc.)
		 * @param color Color to detect (24bit unsigned int)
		 * @param tolerance Tolerance to apply to the red, green and blue 
		 * channels to match a larger range of colors (between 0 and 1)
		 * @param blur Amount of blur to apply (between 0 and 1)
		 * @param brightness Brightness adjustement (between -1 and 1)
		 * @param contrast Contrast adjustement (between -1 and 1)
		 * @param saturation Saturation adjustement (between -1 and 1)
		 * @param hue Hue adjustement (between -1 and 1)
		 */
		public function ChromaTracker(	source:DisplayObject, 
										color:uint = 0x000000, 
										tolerance:Number = 0.2,
										blur:Number = 0,
										brightness:Number = 0,
										contrast:Number = 0,
										saturation:Number = 0,
										hue:Number = 0   ):void {
			
			_source = source;
			
			// This library expects colors to be in 24bit. We silently convert 
			// 32bit colors to 24bit (dropping the alpha channel)
			if (color > (2^24 - 1)) {
				color = (color & 0xFFFFFF); 
			}
			
			// Call the setters
			this.tolerance = tolerance;
			this.color = color;
			this.brightness = brightness; 
			this.contrast = contrast;
			this.saturation = saturation;
			this.hue = hue;
			this.blur = blur;
			
			// Create an empty Bitmap object into which the detected pixels will
			// be drawn
			_bm = new Bitmap();
			_bm.bitmapData = new BitmapData(_source.width, _source.height, true);
			
		}
		
		/**
		 * Executes color detection and returns a rectangle that represents the 
		 * outer boundary of detected pixels. This method takes into account 
		 * color and matrix transformations that may have been applied to the
		 * DisplayObject as well as blend modes.
		 *
		 * The execution of this method also updates the 'bitmap', 'rect' and 
		 * 'center' properties.
		 * 
		 * @return A Rectangle object representing the rectangular outer boundary 
		 * of detected pixels
		 */
		public function track():Rectangle {
			
			// Draw the DisplayObject in the BitmapData taking into account any 
			// transformation matrix, color transform, blending mode. Smoothing 
			// is enabled to take into account matrix transformation such as 
			// rotations.				 
			_bm.bitmapData.draw(_source, _source.transform.matrix, 
				_source.transform.colorTransform, _source.blendMode, null, true);
			
			// Reduce color depth of the BitmapData
			_reduceColorDepth(_bm.bitmapData);
			
			// Plot min and max values for each channel
			var rmin:Number = (_rgbMinima >> 16) & 0xff;
			var gmin:Number = (_rgbMinima >> 8) & 0xff;
			var bmin:Number = _rgbMinima  & 0xff;
			var rmax:Number = (_rgbMaxima >> 16) & 0xff;
			var gmax:Number = (_rgbMaxima >> 8) & 0xff;
			var bmax:Number = _rgbMaxima  & 0xff;
			
			var tmp:Number;
			
			// Make sure minima values are smaller than maxima values
			if (rmin > rmax) {
				tmp = rmin;
				rmin = rmax;
				rmax = tmp;
			}
			
			if (gmin > gmax) {
				tmp = gmin;
				gmin = gmax;
				gmax = tmp;
			}
			
			if (bmin > bmax) {
				tmp = bmin;
				bmin = bmax;
				bmax = tmp;
			}
			
			// Plot thresholds
			_bm.bitmapData.threshold(_bm.bitmapData, _bm.bitmapData.rect, _pt, "<", rmin << 16, 0, 0x00FF0000, true);
			_bm.bitmapData.threshold(_bm.bitmapData, _bm.bitmapData.rect, _pt, "<", gmin << 8, 0, 0x0000FF00, true);
			_bm.bitmapData.threshold(_bm.bitmapData, _bm.bitmapData.rect, _pt, "<", bmin, 0, 0x000000FF, true);
			
			_bm.bitmapData.threshold(_bm.bitmapData, _bm.bitmapData.rect, _pt, ">", rmax <<16, 0, 0x00FF0000, true);
			_bm.bitmapData.threshold(_bm.bitmapData, _bm.bitmapData.rect, _pt, ">", gmax << 8, 0, 0x0000FF00, true);
			_bm.bitmapData.threshold(_bm.bitmapData, _bm.bitmapData.rect, _pt, ">", bmax, 0, 0x000000FF, true);
			
			// Update rectangle of detected pixels and return it
			_rect = _bm.bitmapData.getColorBoundsRect(0xFFFFFFFF, _color, false);
			return _rect;
		}
		
		/**
		 * Reduces the number of colors in the image to make calculations faster 
		 * and to make it more capable of matching nearby colors
		 *
		 * @param bd Reference to the BitmapData to work on
		 * @param colors Target number of colors
		 */
		private function _reduceColorDepth(bd:BitmapData, colors:uint = 256):void {
			var rA:Array = new Array(256);
			var gA:Array = new Array(256);
			var bA:Array = new Array(256);
			
			var step:Number = 256 / (colors / 3);
			
			for (var i:uint = 0; i < 256; i++) {
				bA[i] = Math.floor(i / step) * step;
				gA[i] = bA[i] << 8;
				rA[i] = gA[i] << 8;
			}
			
			bd.paletteMap(bd, bd.rect, _pt, rA, gA, bA );
		}
		
		/**
		 * Adjusts the color minima and maxima after a change in color or 
		 * tolerance
		 */
		private function _adjustColorTolerance():void {
			
			var cTolerance:uint = Math.round(_tolerance * 255);
			
			var rMin:Number = 
				Math.min(255,Math.max(0,((_color >>> 16) & 0xff) - cTolerance ));
			var gMin:Number = 
				Math.min(255,Math.max(0,((_color >>> 8) & 0xff) - cTolerance ));
			var bMin:Number = 
				Math.min(255,Math.max(0,(_color & 0xff) - cTolerance ));
			_rgbMinima = rMin<<16 | gMin<<8 | bMin;
			
			var rMax:Number = 
				Math.min(255,Math.max(0,((_color >>> 16) & 0xff) + cTolerance ));
			var gMax:Number = 
				Math.min(255,Math.max(0,((_color >>> 8) & 0xff ) + cTolerance ));
			var bMax:Number = 
				Math.min(255,Math.max(0, (_color & 0xff) + cTolerance ));
			_rgbMaxima = rMax<<16 | gMax<<8 | bMax;
		}
		
		/** 
		 * A Rectangle object representing the outer rectangular boundary of 
		 * detected pixels
		 */
		public function get rect():Rectangle {
			return _rect;
		}
		
		/** 
		 * A Bitmap object of the currently detected pixels to easily visualize 
		 * the result
		 */
		public function get bitmap():Bitmap { 
			return _bm;
		}
		
		/** 
		 * A Point object representing the center of the detected rectangular 
		 * zone
		 */
		public function get center():Point { 
			var a:Point = new Point(rect.x, rect.y);
			var b:Point = new Point(rect.right, rect.bottom);
			return Point.interpolate(a, b, 0.5);
		}
		
		/** A uint representing the color set for detection */
		public function get color():uint { 
			return _color;
		}
		
		/** @private */
		public function set color(c:uint):void {
			_color = c;
			_adjustColorTolerance();
		}
		
		/** A Number between 0 and 1 representing the color tolerance */
		public function get tolerance():Number { 
			return _tolerance;
		}
		
		/** @private */
		public function set tolerance(t:Number):void {
			_tolerance = t;
			_adjustColorTolerance();
		}
		
		/** A Number between 0 and 1 representing the amount of blur applied */
		public function get blur():Number { 
			return _blur;
		}
		
		/** @private */
		public function set blur(b:Number):void {
			_blur = b;
		}
		
		/** A Number between -1 and 1 representing the brightness correction */
		public function get brightness():Number { 
			return _brightness;
		}
		
		/** @private */
		public function set brightness(b:Number):void {
			_brightness = b;
		}
		
		/** A Number between -1 and 1 representing the saturation correction */
		public function get saturation():Number { 
			return _saturation;
		}
		
		/** @private */
		public function set saturation(s:Number):void {
			_saturation = s;
		}
		
		/** A Number between -1 and 1 representing the contrast correction */
		public function get contrast():Number { 
			return _contrast;
		}
		
		/** @private */
		public function set contrast(c:Number):void {
			_contrast = c;
		}
		
		/** A Number between -1 and 1 representing the hue correction */
		public function get hue():Number { 
			return _hue;
		}
		
		/** @private */
		public function set hue(h:Number):void {
			_hue = h;
		}
		
	}
	
}

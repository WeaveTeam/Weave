package weave.utils
{
	import mx.core.UIComponent;
	
	/**
	 * A collection of static functions for getting style values from UIComponent objects.
	 * Allows you to specify a default value if the style doesn't exist.
	 * 
	 * @author Chris Callendar
	 * @date March 3rd, 2010
	 * GNU Lesser General Public License (LGPL-3.0, open source). 
	 */
	public class StyleUtils
	{
		
		/**
		 * Tries to get an alpha style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 * Restricts the value between 0 and 1.
		 */ 
		public static function getAlphaStyle(ui:UIComponent, styleName:String, defaultValue:Number = 1):Number {
			return getNumberStyle(ui, styleName, defaultValue, 0, 1);
		}
		
		
		/**
		 * Tries to get a Number style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 * It can also optionally restrict the number between a min and max.
		 * This function will only return NaN if your default value is NaN.
		 */ 
		public static function getNumberStyle(ui:UIComponent, styleName:String, defaultValue:Number = 1,
											  min:Number = NaN, max:Number = NaN):Number {
			var num:Number = defaultValue;
			var style:Object = ui.getStyle(styleName);
			if (style != null) {
				var n:Number = Number(style);
				if (!isNaN(n)) {
					// check the minimum value
					if (!isNaN(min) && (n < min)) {
						n = min;
					}
					// check the maximum value
					if (!isNaN(max) && (n > max)) {
						n = max;
					}
					num = n;
				}
			}
			return num;
		}
		
		/**
		 * Tries to get a color style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 */
		public static function getColorStyle(ui:UIComponent, styleName:String, defaultValue:uint = 0xffffff):uint {
			return getUintStyle(ui, styleName, defaultValue);
		}
		
		/**
		 * Tries to get a uint style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 */
		public static function getUintStyle(ui:UIComponent, styleName:String, defaultValue:uint = 0):uint {
			var u:uint = defaultValue;
			var style:Object = ui.getStyle(styleName);
			if (style != null) {
				u = uint(Number(style));
			}
			return u;
		}
		
		
		/**
		 * Tries to get an int style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 */
		public static function getIntStyle(ui:UIComponent, styleName:String, defaultValue:int = 0):int {
			var i:int = defaultValue;
			var style:Object = ui.getStyle(styleName);
			if (style != null) {
				i = int(Number(style));
			}
			return i;
		}
		
		/**
		 * Tries to get a Boolean style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 */
		public static function getBooleanStyle(ui:UIComponent, styleName:String, defaultValue:Boolean = false):Boolean {
			var b:Boolean = defaultValue;
			var style:Object = ui.getStyle(styleName);
			if (style != null) {
				b = Boolean(style);
			}
			return b;
		}
		
		/**
		 * Tries to get a Boolean style value from the UIComponent. 
		 * If the style doesn't exist then it returns the default value.
		 */
		public static function getStringStyle(ui:UIComponent, styleName:String, defaultValue:String = null):String {
			var s:String = defaultValue;
			var style:Object = ui.getStyle(styleName);
			if (style != null) {
				s = String(style);
			}
			return s;
		}
		
	}
}


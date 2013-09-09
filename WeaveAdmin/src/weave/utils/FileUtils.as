package weave.utils
{
	import mx.collections.ArrayList;
	import mx.controls.List;
	import mx.formatters.NumberFormatter;

	public class FileUtils
	{
		private static var formater:NumberFormatter = new NumberFormatter();
		
		public function FileUtils()
		{
			
		}
		public static function parse(size:Number, precision:Number):String
		{
			var i:int = 0;
			var sizes:Array = ["B", "KB", "MB", "GB", "TB"];
			
			while( (size/1024) > 1 ) {
				size /= 1024;
				i++;
			}
			
			formater.precision = precision;
			return formater.format(size) + " " + sizes[i];
		}
	}
}
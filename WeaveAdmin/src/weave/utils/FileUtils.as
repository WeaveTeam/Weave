package weave.utils
{
	import mx.formatters.NumberFormatter;

	public class FileUtils
	{
		private var _size:Number;
		private var formater:NumberFormatter = new NumberFormatter();
		
		public function FileUtils()
		{
			
		}
		public function get size():Number
		{
			return _size;
		}
		public function set size(s:Number):void
		{
			_size = s;
		}
		public function parse(size:Number, precision:Number):String
		{
			if( size < 1024 ) 
				return size + (( size == 1 ) ? " Byte" : " Bytes");
			
			size = size / 1024;
			if( size < 1024 ) {
				formater.precision = precision;
				return formater.format(size) + (( size == 1 ) ? " Kilobyte" : " Kilobytes");
			}
			
			size = size / 1024;
			if( size < 1024 ) {
				formater.precision = precision;
				return formater.format(size) + (( size == 1 ) ? " Megabyte" : " Megabytes");
			}
			
			size = size / 1024;
			formater.precision = precision;
			return formater.format(size) + (( size == 1 ) ? " Gigabyte" : " Gigabytes");
		}
	}
}
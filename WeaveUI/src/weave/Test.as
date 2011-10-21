package weave
{
	public class Test
	{
		import flash.utils.getTimer;
		
		public function Test()
		{
			var t:int = getTimer();
			var a:Array = [];
			var i:int;
			for( i=0; i< 1000000; i++)
			{
				var x:int = i*i;
				a.push( x );
			}
			trace( 'constructor: ' + (getTimer() - t) );
			init();
		}
		
		public function init():void
		{
			var t:int = getTimer();
			var a:Array = [];
			var i:int;
			for( i=0; i< 1000000; i++)
			{
				var x:int = i*i;
				a.push( x );
			}
			trace( 'init method: ' + (getTimer() - t) );
		}
	}
}

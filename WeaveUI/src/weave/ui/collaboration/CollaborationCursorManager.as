package weave.ui.collaboration
{
	import flash.utils.Dictionary;
	
	import weave.api.reportError;
	import weave.api.ui.ICollabCursorManager;
	
	public class CollaborationCursorManager implements ICollabCursorManager
	{
		private var cursorList:Dictionary = new Dictionary();
		
		public function getCursorIds():Array
		{
			var localArray:Array = new Array();
			for( var i:String in cursorList )
				localArray.push(i);
			return localArray;		
		}
		
		public function setVisible(id:String, visible:Boolean, duration:uint=1000):void
		{
			
		}
		
		public function setPosition(id:String, x:Number, y:Number, duration:uint):void
		{
			
		}
		
		public function setColor(id:String, color:uint, duration:uint=1000):void
		{
			
		}
		
		public function removeCursor(id:String):void
		{
			try
			{
				delete cursorList[id];
			}
			catch(e:Error)
			{
				reportError(e, "Could not delete specified cursor.");
			}
		}
	}
}
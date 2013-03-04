package weave.utils
{
	import flash.display.DisplayObject;
	
	import mx.core.IVisualElementContainer;
	import mx.core.UIComponent;
	
	import spark.components.Group;
	import spark.components.TitleWindow;
	import spark.components.supportClasses.SkinnableComponent;

	public class SparkUtils
	{
		public function SparkUtils()
		{
			
			
		}
		
		public static function getAllElement(grp:IVisualElementContainer):Array{
			var elements:Array = new Array();
			//elements.length = grp.numElements;
			for(var i:int = 0; i < grp.numElements; i++){
				elements.push(grp.getElementAt(i));
			}
			return elements;	
		}
		
		
		
		
	}
}
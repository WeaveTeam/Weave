package weave.ui.DataMiningEditors
{
	import flash.utils.Dictionary;

	public class DataMiningAlgorithmObject
	{
		[Bindable]
		public var label:String;//tells us the name of the algorithm
		
		public var parameters:Array = new Array();// tells us the parameters needed for the algorithm. Each algorithm will have a different number of parameters
		/* default is false. When selected it becomes true
		 * tells us if an algorithm is selected in the list for running algorithms in R*/
		[Bindable]
		public var isSelectedInAlgorithmList:Boolean = false; 
		
		public var parameterMapping:Dictionary = new Dictionary();//maps the name of the parameter to its value for a dataminingObject
		
		
		public function DataMiningAlgorithmObject()
		{
			super();
		}
	}
}
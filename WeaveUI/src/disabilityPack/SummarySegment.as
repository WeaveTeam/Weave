package disabilityPack
{
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.reportError;
	import weave.editors.Disability;
	import weave.services.WeaveRServlet;
	import weave.services.beans.RResult;

	public class SummarySegment
	{
	
		public var index:int; // index, same as in the joinRcolumns array in disability.	
		private var query:AsyncToken;
		private var _dataValues:Array;
		private var _analysisResult:String;
		
		public function getAnalysis():String
		{
			return _analysisResult; 
		}
		public function setAnalysis(result:String):void
		{
			_analysisResult = result; 
		}
		
		public function setDataValues(values:Array):void
		{
			_dataValues = values;
		}
		
		public function getDataValues():Array
		{	
			return _dataValues;
		}
		
		public function setIndex(mIndex:int):void
		{
			index = mIndex;
		}
		
		public function getIndex():int
		{
			return index;
		}
		
		public function setValuesIndex(values:Array,mIndex:int):void
		{
			_dataValues = values;
			index = mIndex;
			

		}
		
		public function SummarySegment()
		{
			
			
			
		}

		
	}
}
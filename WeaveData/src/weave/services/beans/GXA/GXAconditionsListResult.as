package weave.services.beans.GXA
{
	public class GXAconditionsListResult
	{
		public function GXAconditionsListResult(conditionList:Object)
		{
			property = conditionList.property;
			value = conditionList.value;
			id = conditionList.id;
			path = conditionList.path;
			count = conditionList.count;
			alternativeTerms = conditionList.alternativeTerms;
		}
		
		public var property:String;
		public var value:String;
		public var id:String;
		public var path:Array;
		public var count:Number;		
		public var alternativeTerms:Array;
	}
}
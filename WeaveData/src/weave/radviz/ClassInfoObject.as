package weave.radviz
{
	import flash.utils.Dictionary;

	public class ClassInfoObject
	{
		public var columnMapping:Dictionary = new Dictionary();//stores a map of columnName as key and ColumnValues as its(the key's) values
		
		public var tStatisticArray:Array = new Array();//stores all the t-statistics of each column for a given type
		
		public var pValuesArray:Array = new Array();//stores all the p-values of esch column for a given type
		
		
		
		
		public function ClassInfoObject()
		{
		}
		
		
	}
}
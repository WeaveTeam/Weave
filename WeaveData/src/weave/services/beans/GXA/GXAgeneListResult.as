package weave.services.beans.GXA
{
	public class GXAgeneListResult
	{
		public function GXAgeneListResult(geneList:Object)
		{
			this.species = geneList.species;
			this.otherNames = geneList.otherNames;
			this.property = geneList.property;
			this.value = geneList.value;
			this.id = geneList.id;
			this.path = geneList.path;
			this.count = geneList.count;
		}
			
		public var species:String;
		public var otherNames:Array;
		public var property:String;
		public var value:String;
		public var id:String;
		public var path:Array;
		public var count:int;
	}
}
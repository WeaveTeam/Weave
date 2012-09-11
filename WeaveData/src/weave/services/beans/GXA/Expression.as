package weave.services.beans.GXA
{
	public class Expression
	{
		public function Expression(exp:Object)
		{
			this.efoTerm = exp.efoTerm;
			this.efoId = exp.efoId;
			this.upExperiments = exp.upExperiments;
			this.downExperiments = exp.downExperiments;
			this.nonDEExperiments = exp.nonDEExperiments;
			this.upPvalue = exp.upPvalue;
			this.downPvalue = exp.downPvalue;
			this.experiments = exp.experiments;
		}
		
		public var efoTerm:String;
		public var efoId:String;
		public var upExperiments:int;
		public var downExperiments:int;
		public var nonDEExperiments:int;
		public var upPvalue:Number;
		public var downPvalue:Number;
		public var experiments:Array;
	}
}
package weave.services.beans.GXA
{
	public class Experiment
	{
		public function Experiment(experiment:Object)
		{
			this.experimentAccession = experiment.experimentAccession;
			this.pvalue = experiment.pvalue;
			this.experimentDescription = experiment.experimentDescription;
			this.updn = experiment.updn;
		}
		
		public var experimentAccession:String;
		public var pvalue:Number;
		public var experimentDescription:String;
		public var updn:String;
	}
}
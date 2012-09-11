package weave.services.beans.GXA
{
	public class GeneExpression
	{
		public function GeneExpression(geneExp:Object)
		{
			this.gene = new Gene(geneExp.gene);
			this.expressions = geneExp.expressions;
		}
		public var gene:Gene;
		public var expressions:Array ;
	}
}
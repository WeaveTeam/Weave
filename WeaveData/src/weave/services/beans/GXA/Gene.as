package weave.services.beans.GXA
{
	public class Gene
	{
		public function Gene(gene:Object)
		{
			this.emblIds = gene.emblIds; 
			this.orthologs = gene.orthologs; 
			this.enstranscripts = gene.enstranscripts; 
			this.unigeneIds = gene.unigeneIds; 
			this.goTerms = gene.goTerms; 
			this.goIds = gene.goIds; 
			this.ensemblProteinIds = gene.ensemblProteinIds; 
			this.synonyms = gene.synonyms; 		
			this.ensemblGeneId = gene.ensemblGeneId; 
			this.interProIds = gene.interProIds; 
			this.uniprotIds = gene.uniprotIds; 
			this.organism =  gene.organism; 
			this.id = gene.id; 
			this.designelements = gene.designelements; 
			this.refseqIds = gene.refseqIds; 
			this.ensemblFamilyIds = gene.ensemblFamilyIds; 
			this.ensfamily_descriptions = gene.ensfamily_descriptions; 		
			this.name = gene.name; 
			this.interProTerms =  gene.interProTerms;
		}
		
		public var emblIds:Array; 
		public var orthologs:Array; 
		public var enstranscripts:Array; 
		public var unigeneIds:Array; 
		public var goTerms:Array; 
		public var goIds:Array; 
		public var ensemblProteinIds:Array; 
		public var synonyms:Array; 		
		public var ensemblGeneId:String; 
		public var interProIds:Array; 
		public var uniprotIds:Array; 
		public var organism:String; 
		public var id:String; 
		public var designelements:Array; 
		public var refseqIds:Array; 
		public var ensemblFamilyIds:Array; 
		public var ensfamily_descriptions:Array; 		
		public var name:String; 
		public var interProTerms:Array;
	}
}
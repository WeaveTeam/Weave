package weave.beans.GXA;



public class GXAResult {
	
	public result[] results;
	
	public class result{
		public Gene gene;
		public expression[] expressions;
	}
	
	public class Gene{
		public String[] emblIds; 
		public String[] orthologs; 
		public String[] enstranscripts; 
		public String[] unigeneIds; 
		public String[] goTerms; 
		public String[] goIds; 
		public String[] ensemblProteinIds; 
		public String[] synonyms; 		
		public String ensemblGeneId; 
		public String[] interProIds; 
		public String[] uniprotIds; 
		public String organism; 
		public String id; 
		public String[] designelements; 
		public String[] refseqIds; 
		public String[] ensemblFamilyIds; 
		public String[] ensfamily_descriptions; 		
		public String name; 
		public String[] interProTerms; 
		
	}
	
	public class expression{
		public String efoTerm;
		public String efoId;
		public int upExperiments;
		public int downExperiments;
		public int nonDEExperiments;
		public Double upPvalue;
		public Double downPvalue;
		public experiment[] experiments; 
	}
	
	public  class experiment{
		public String experimentAccession;
		public Double pvalue;
		public String experimentDescription;
		public String updn;
	}
	
	
}



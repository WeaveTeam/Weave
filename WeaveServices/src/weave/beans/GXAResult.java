package weave.beans;

import java.util.List;

public class GXAResult {
//	public String efoTerm;
//	public String efoId;
//	public int upExperiments;
//	public int downExperiments;
//	public int nonDEExperiments;
//	public Long upPvalue;
//	public Long downPvalue;
	
	public List<result> results;
	
	private class result{
		public Gene gene;
		public List<expression> expressions;
	}
	
	
	
	
	
	private class Gene{
		public List<String> emblIds; 
		public List<String> orthologs; 
		public List<String> enstranscripts; 
		public List<String> unigeneIds; 
		public List<String> goTerms; 
		public List<String> goIds; 
		public List<String> ensemblProteinIds; 
		public List<String> synonyms; 		
		public String ensemblGeneId; 
		public List<String> interProIds; 
		public List<String> uniprotIds; 
		public String organism; 
		public String id; 
		public List<String> designelements; 
		public List<String> refseqIds; 
		public List<String> ensemblFamilyIds; 
		public List<String> ensfamily_descriptions; 		
		public String name; 
		public List<String> interProTerms; 
		
	}
	
	private class expression{
		public String efoTerm;
		public String efoId;
		public int upExperiments;
		public int downExperiments;
		public int nonDEExperiments;
		public Double upPvalue;
		public Double downPvalue;
		public List<experiment> experiments; 
	}
	
	private class experiment{
		public String experimentAccession;
		public Double pvalue;
		public String experimentDescription;
		public String updn;
	}
	
	
}



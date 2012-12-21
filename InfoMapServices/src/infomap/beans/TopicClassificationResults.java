package infomap.beans;

public class TopicClassificationResults {
	
	public String[][] keywords;
	public String[][] urls;
	public String[] uncategoried;
	
	public TopicClassificationResults() {
		// TODO Auto-generated constructor stub
	}
	
	public TopicClassificationResults(String[][] keywords, String[][] urls, String[] uncategoried) {
		
		this.keywords = keywords;
		this.urls = urls;
		this.uncategoried = uncategoried;
		
	}
}

package infomap.beans;

public class TopicClassificationResults {
	
	public String[][] keywords;
	public String[][] urls;
	
	public TopicClassificationResults() {
		// TODO Auto-generated constructor stub
	}
	
	public TopicClassificationResults(String[][] keywords, String[][]urls) {
		
		this.keywords = keywords;
		this.urls = urls;
	}
}

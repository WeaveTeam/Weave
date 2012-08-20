package weave.tests;

import java.io.IOException;

import weave.servlets.GXAService;

public class GXATest {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		GXAService ser = new GXAService();
		try {
			//String queryUrl = "http://www.ebi.ac.uk/gxa/api/vx?geneGeneIs=ENSG00000066279&species=&updownIn=EFO_0000815&rows=50&start=0&format=json";

			//ser.extractGeneExpressionData(queryUrl);
			
			
			String query = "ha";
			ser.getGeneList(query);
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}

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
			ser.extractGeneExpressionData();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}

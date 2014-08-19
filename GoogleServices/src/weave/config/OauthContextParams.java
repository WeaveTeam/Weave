package weave.config;

import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;

public class OauthContextParams {
	
	public static OauthContextParams getInstance(ServletContext context) throws ServletException, IOException
	{
//		if (_instance == null)
//			_instance = new OauthContextParams(context);
		return _instance;
	}
	private static OauthContextParams _instance;
	
	
	
//	/**
//	 * This constructor sets all public variables.
//	 * @param context The context of a servlet containing context params.
//	 */
//	private OauthContextParams(ServletContext context) throws IOException
//	{		
//		OauthCredentialUtils.loadClientCredentials(context);		
//	}
//	
	
	

}

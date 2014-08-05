package weave.config;

import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;

import weave.CredentialUtils;

public class GoogleContextParams {
	
	public static GoogleContextParams getInstance(ServletContext context) throws ServletException, IOException
	{
		if (_instance == null)
			_instance = new GoogleContextParams(context);
		return _instance;
	}
	private static GoogleContextParams _instance;
	
	
	
	/**
	 * This constructor sets all public variables.
	 * @param context The context of a servlet containing context params.
	 */
	private GoogleContextParams(ServletContext context) throws IOException
	{		
		CredentialUtils.loadClientCredentials(context);		
	}
	
	
	

}

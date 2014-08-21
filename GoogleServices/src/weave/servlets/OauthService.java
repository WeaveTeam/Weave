package weave.servlets;




import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import weave.OauthCredentialUtils;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;

public class OauthService extends AbstractAuthorizationCodeService {

	private static final long serialVersionUID = 1L;
	
	public static final String RESOURCE_LOCATION = "/WEB-INF/test_client_secrets.json";

	@Override
	protected AuthorizationCodeFlow initializeFlow(String clientID,String clientSecret, String authUri, String tokenUri) throws ServletException,IOException {
		 return OauthCredentialUtils.newFlow(clientID,clientSecret,authUri,tokenUri);
	}

	@Override
	protected String getRedirectUri() throws ServletException, IOException {
		return OauthCredentialUtils.getRedirectUri();
	}

	@Override
	protected String getUserId(HttpServletRequest req) throws ServletException,	IOException {
		return null;
	}
	
	
	
	//public String getToken()
//	@Override
//	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
//	{
//	    triggerOauthFlowWithResponse("20a867dd3176481f9d64f409bfbe3df3","c624be931e554d25b71095e0b69fd6c6","https://runkeeper.com/apps/authorize","https://runkeeper.com/apps/token",response,request);
//	    super.doGet(request, response);
//	}
//	
//	@Override
//	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
//	{
//	    
//	    triggerOauthFlowWithResponse("20a867dd3176481f9d64f409bfbe3df3","c624be931e554d25b71095e0b69fd6c6","https://runkeeper.com/apps/authorize","https://runkeeper.com/apps/token",response,request);
//	    super.doPost(request, response);
//	}

//	 public void triggerOauthFlow(String clientID,String clientSecret, String authUri, String tokenUri) throws IOException, ServletException {
//		    lock.lock();
//		    try {
//		        if (flow == null) {
//		        flow = initializeFlow(clientID,clientSecret,authUri,tokenUri);
//		      }
//		      // redirect to the authorization flow
//		      String redirectUri = getRedirectUri();
//		      HttpServletResponse resp = getServletRequestInfo().response;
//		      String uri = flow.newAuthorizationUrl().setRedirectUri(redirectUri).build(); 
//		      resp.sendRedirect(uri);
//		     // credential = null;
//		     // return uri;
//		    } finally {
//		      lock.unlock();
//		    }
//		  }
	 
//	 private void triggerOauthFlowWithResponse(String clientID,String clientSecret, String authUri, String tokenUri,HttpServletResponse resp,HttpServletRequest req) throws IOException, ServletException {
//		    lock.lock();
//		    try {
//		        if (flow == null) {
//		        flow = initializeFlow(clientID,clientSecret,authUri,tokenUri);
//		      }
//		      // redirect to the authorization flow
//		      String redirectUri = getRedirectUri();
//		     // HttpServletResponse resp = getServletRequestInfo().response;
//		      String uri = flow.newAuthorizationUrl().setRedirectUri(redirectUri).build();     
//		     // resp.setContentType("text/html");
//		      resp.sendRedirect(uri);
//		     
//		     // credential = null;
//		    } finally {
//		      lock.unlock();
//		    }
//		  }
	
//	public void init(ServletConfig config) throws ServletException
//	{
//		super.init(config);
//		try {
//			initOauthConfig(OauthContextParams.getInstance(config.getServletContext()));
//		} catch (IOException e) {
//			e.printStackTrace();
//		}
//	}
	 
	 
	 
	
}




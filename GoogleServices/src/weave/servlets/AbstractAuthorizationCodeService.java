package weave.servlets;

import java.io.IOException;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;
import com.google.api.client.auth.oauth2.AuthorizationCodeResponseUrl;
import com.google.api.client.auth.oauth2.AuthorizationCodeTokenRequest;
import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.auth.oauth2.TokenResponse;
import com.google.api.client.http.HttpResponseException;

public abstract class AbstractAuthorizationCodeService extends WeaveServlet {
	private static final long serialVersionUID = 1L;

	  /** Lock on the flow and credential. */
	  protected final Lock lock = new ReentrantLock();

	  /** Persisted credential associated with the current request or {@code null} for none. */
	  private Credential credential;

	  /**
	   * Authorization code flow to be used across all HTTP servlet requests or {@code null} before
	   * initialized in {@link #initializeFlow()}.
	   */
	  protected AuthorizationCodeFlow flow;

	  protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
		{	
			StringBuffer buf = request.getRequestURL();
			String queryString = request.getQueryString();
			String code = null;
		    if (queryString != null) {
		      buf.append('?').append(request.getQueryString());
		      AuthorizationCodeResponseUrl responseUrl = new AuthorizationCodeResponseUrl(buf.toString());
			    code = responseUrl.getCode();
			    if (responseUrl.getError() != null) {
			    	onError(request, response, responseUrl);
			    }
		    }
		   
		    if(code != null){
		      String redirectUri = getRedirectUri();
		      lock.lock();
		      try {
		        AuthorizationCodeTokenRequest tokenRequest = flow.newTokenRequest(code).setRedirectUri(redirectUri);
		        //resp from RunKeeper  is json object= access_token  ,token_type:bearer
		        TokenResponse resp = tokenRequest.execute();
		        String userId = getUserId(request);
		        Credential credential = flow.createAndStoreCredential(resp, userId);
		        onSuccess(request, response, credential);
		      } finally {
		        lock.unlock();
		      }
		    }
			super.doGet(request, response);
		}
	  
	 
	  
	  /**
	   * Handles a successfully granted authorization.
	   *
	   * <p>
	   * Default implementation is to do nothing, but subclasses should override and implement. Sample
	   * implementation:
	   * </p>
	   *
	   * <pre>
	      resp.sendRedirect("/granted");
	   * </pre>
	   *
	   * @param req HTTP servlet request
	   * @param resp HTTP servlet response
	   * @param credential credential
	   * @throws ServletException HTTP servlet exception
	   * @throws IOException some I/O exception
	   */
	  protected void onSuccess(HttpServletRequest req, HttpServletResponse resp, Credential credential)
	      throws ServletException, IOException {
	  }
	  
	  /**
	   * Handles an error to the authorization, such as when an end user denies authorization.
	   *
	   * <p>
	   * Default implementation is to do nothing, but subclasses should override and implement. Sample
	   * implementation:
	   * </p>
	   *
	   * <pre>
	      resp.sendRedirect("/denied");
	   * </pre>
	   *
	   * @param req HTTP servlet request
	   * @param resp HTTP servlet response
	   * @param errorResponse error response ({@link AuthorizationCodeResponseUrl#getError()} is not
	   *        {@code null})
	   * @throws ServletException HTTP servlet exception
	   * @throws IOException some I/O exception
	   */
	  protected void onError(
	      HttpServletRequest req, HttpServletResponse resp, AuthorizationCodeResponseUrl errorResponse)
	      throws ServletException, IOException {
	  }
	  
//	  @Override
//	  protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
//	    lock.lock();
//	    try {
//	      // load credential from persistence store
//	      String userId = getUserId(req);
//	      if (flow == null) {
//	        flow = initializeFlow();
//	      }
//	      if(userId != null)
//	    	  credential = flow.loadCredential(userId);
//	      // if credential found with an access token, invoke the user code
//	      if (credential != null && credential.getAccessToken() != null) {
//	        try {
//	          super.service(req, resp);
//	          return;
//	        } catch (HttpResponseException e) {
//	          // if access token is null, assume it is because auth failed and we need to re-authorize
//	          // but if access token is not null, it is some other problem
//	          if (credential.getAccessToken() != null) {
//	            throw e;
//	          }
//	        }
//	      }
//	      // redirect to the authorization flow
//	      String redirectUri = getRedirectUri();
//	      resp.sendRedirect(flow.newAuthorizationUrl().setRedirectUri(redirectUri).build());
//	      credential = null;
//	    } finally {
//	      lock.unlock();
//	    }
//	  }
	  
	  
	 
	  


	  /**
	   * Loads the authorization code flow to be used across all HTTP servlet requests (only called
	   * during the first HTTP servlet request).
	   */
	  protected abstract AuthorizationCodeFlow initializeFlow(String clientID,String clientSecret, String authUri, String tokenUri) throws ServletException, IOException;

	  /** Returns the redirect URI for the given HTTP servlet request. */
	  protected abstract String getRedirectUri()
	      throws ServletException, IOException;

	  /** Returns the user ID for the given HTTP servlet request. */
	  protected abstract String getUserId(HttpServletRequest req) throws ServletException, IOException;

	  /**
	   * Return the persisted credential associated with the current request or {@code null} for none.
	   */
	  protected final Credential getCredential() {
	    return credential;
	  }

}

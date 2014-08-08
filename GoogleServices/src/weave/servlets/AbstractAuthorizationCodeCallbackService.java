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
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeTokenRequest;

public abstract class AbstractAuthorizationCodeCallbackService extends WeaveServlet {

	private static final long serialVersionUID = 1L;

	/** Lock on the flow. */
	private final Lock lock = new ReentrantLock();

	/**
	 * Authorization code flow to be used across all HTTP servlet requests or {@code null} before
	 * initialized in {@link #initializeFlow()}.
	 */
	private AuthorizationCodeFlow flow;

	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{		
		StringBuffer buf = request.getRequestURL();
	    if (request.getQueryString() != null) {
	      buf.append('?').append(request.getQueryString());
	    }
	    AuthorizationCodeResponseUrl responseUrl = new AuthorizationCodeResponseUrl(buf.toString());
	    String code = responseUrl.getCode();
	    if (responseUrl.getError() != null) {
	      onError(request, response, responseUrl);
	    } else if (code == null) {
	    	response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
	    	response.getWriter().print("Missing authorization code");
	    } else {
	      String redirectUri = getRedirectUri();
	      lock.lock();
	      try {
	        if (flow == null) {
	          flow = initializeFlow();
	        }
	        AuthorizationCodeTokenRequest tokenRequest = flow.newTokenRequest(code).setRedirectUri(redirectUri);
	        //resp is json object, which has 
	        //access_token , expires_in ,id_token, refresh_token ,token_type
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
	   * Loads the authorization code flow to be used across all HTTP servlet requests (only called
	   * during the first HTTP servlet request with an authorization code).
	   */
	  protected abstract AuthorizationCodeFlow initializeFlow() throws ServletException, IOException;

	  /** Returns the redirect URI for the given HTTP servlet request. */
	  protected abstract String getRedirectUri() throws ServletException, IOException;

	  /** Returns the user ID for the given HTTP servlet request. */
	  protected abstract String getUserId(HttpServletRequest req) throws ServletException, IOException;

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

}

package weave.servlets;

import java.io.IOException;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;
import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.http.HttpResponseException;

public abstract class AbstractAuthorizationCodeService extends WeaveServlet {
	private static final long serialVersionUID = 1L;

	  /** Lock on the flow and credential. */
	  private final Lock lock = new ReentrantLock();

	  /** Persisted credential associated with the current request or {@code null} for none. */
	  private Credential credential;

	  /**
	   * Authorization code flow to be used across all HTTP servlet requests or {@code null} before
	   * initialized in {@link #initializeFlow()}.
	   */
	  private AuthorizationCodeFlow flow;

	  @Override
	  protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
	    lock.lock();
	    try {
	      // load credential from persistence store
	      String userId = getUserId(req);
	      if (flow == null) {
	        flow = initializeFlow();
	      }
	      if(userId != null)
	    	  credential = flow.loadCredential(userId);
	      // if credential found with an access token, invoke the user code
	      if (credential != null && credential.getAccessToken() != null) {
	        try {
	          super.service(req, resp);
	          return;
	        } catch (HttpResponseException e) {
	          // if access token is null, assume it is because auth failed and we need to re-authorize
	          // but if access token is not null, it is some other problem
	          if (credential.getAccessToken() != null) {
	            throw e;
	          }
	        }
	      }
	      // redirect to the authorization flow
	      String redirectUri = getRedirectUri();
	      resp.sendRedirect(flow.newAuthorizationUrl().setRedirectUri(redirectUri).build());
	      credential = null;
	    } finally {
	      lock.unlock();
	    }
	  }
	  


	  /**
	   * Loads the authorization code flow to be used across all HTTP servlet requests (only called
	   * during the first HTTP servlet request).
	   */
	  protected abstract AuthorizationCodeFlow initializeFlow() throws ServletException, IOException;

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

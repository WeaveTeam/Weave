package weave.servlets;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;

import weave.CredentialUtils;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;

public class Oauth2Callback extends AbstractAuthorizationCodeCallbackService {

	private static final long serialVersionUID = 1L;

	
	@Override
	protected AuthorizationCodeFlow initializeFlow() throws ServletException,
			IOException {
		return CredentialUtils.newFlow();
	}

	@Override
	protected String getRedirectUri() throws ServletException, IOException {
		 return CredentialUtils.getRedirectUri();
	}

	@Override
	protected String getUserId(HttpServletRequest req) throws ServletException,
			IOException {
		// TODO Auto-generated method stub
		return null;
	}

}

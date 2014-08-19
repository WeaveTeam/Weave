package weave.servlets;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;

import weave.OauthCredentialUtils;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;

public class Oauth2Callback extends AbstractAuthorizationCodeCallbackService {

	private static final long serialVersionUID = 1L;

	
	@Override
	protected AuthorizationCodeFlow initializeFlow(String clientID,String clientSecret, String authUri, String tokenUri) throws ServletException,
			IOException {
		return OauthCredentialUtils.newFlow(clientID,clientSecret,authUri,tokenUri);
	}

	@Override
	protected String getRedirectUri() throws ServletException, IOException {
		 return OauthCredentialUtils.getRedirectUri();
	}

	@Override
	protected String getUserId(HttpServletRequest req) throws ServletException,
			IOException {
		// TODO Auto-generated method stub
		return null;
	}

}

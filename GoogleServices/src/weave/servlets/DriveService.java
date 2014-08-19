package weave.servlets;

import static weave.config.GoogleConfig.initGoogleConfig;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;

import weave.CredentialUtils;
import weave.config.GoogleContextParams;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;
import com.google.api.services.drive.Drive;
import com.google.api.services.drive.model.File;

public class DriveService extends AbstractAuthorizationCodeService {
	private static final long serialVersionUID = 1L;
	


	@Override
	protected AuthorizationCodeFlow initializeFlow(String clientID,String clientSecret, String authUri, String tokenUri) throws ServletException,IOException {
		 return CredentialUtils.newFlow();
	}

	@Override
	protected String getRedirectUri() throws ServletException, IOException {
		return CredentialUtils.getRedirectUri();
	}

	@Override
	protected String getUserId(HttpServletRequest req) throws ServletException,	IOException {
		return null;
	}
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		try {
			initGoogleConfig(GoogleContextParams.getInstance(config.getServletContext()));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void getFileMetaData(String fileId ) throws IOException{
		 File file = null;		    
		 Drive service = CredentialUtils.loadDriveService();
		 file = service.files().get(fileId).execute();
	}

}

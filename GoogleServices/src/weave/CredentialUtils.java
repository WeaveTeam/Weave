package weave;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.Arrays;
import java.util.List;

import javax.servlet.ServletContext;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson.JacksonFactory;
import com.google.api.client.util.Preconditions;
import com.google.api.services.drive.Drive;

public class CredentialUtils {

	static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();
	static final JsonFactory JSON_FACTORY = new JacksonFactory();
	public static final String RESOURCE_LOCATION = "/WEB-INF/client_secrets.json";;
	private static GoogleClientSecrets clientSecrets = null;

	private static final List<String> SCOPES = Arrays.asList(
			// Required to access and manipulate files.
			"https://www.googleapis.com/auth/drive.file",
			// Required to identify the user in our data store.
			"https://www.googleapis.com/auth/userinfo.email",
			"https://www.googleapis.com/auth/userinfo.profile");



	public static String getRedirectUri() {
		String redirectURI = clientSecrets.getWeb().getRedirectUris().get(0);
		GenericUrl url = new GenericUrl(redirectURI);
		return url.build();
	}
	
	public static void loadClientCredentials(ServletContext context) throws IOException {
		InputStream inputStream = context.getResourceAsStream("/WEB-INF/client_secrets.json");
		Reader reader = new InputStreamReader(inputStream);
		Preconditions.checkNotNull(inputStream, "Cannot open: %s" + RESOURCE_LOCATION);
		clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, reader);
		
	}

	public static GoogleClientSecrets getClientCredential() throws IOException {
//		if (clientSecrets == null) {
//			InputStream inputStream = new FileInputStream(new File(RESOURCE_LOCATION));
//			Reader reader = new InputStreamReader(inputStream);
//			Preconditions.checkNotNull(inputStream, "Cannot open: %s" + RESOURCE_LOCATION);
//			clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, reader);
//		}
		return clientSecrets;
	}

	public static GoogleAuthorizationCodeFlow newFlow() throws IOException {
		return new GoogleAuthorizationCodeFlow.Builder(HTTP_TRANSPORT, JSON_FACTORY, getClientCredential(), SCOPES)
		.setAccessType("offline").setApprovalPrompt("force").build();
	}

	

	public static String getUserId() {
		// Include your custom implementation for retrieval of a unique
		// user id string from your application.
		String userId = "";
		return userId;
	}
	
	
	public static Drive loadDriveService() throws IOException {
	    String userId = getUserId();
	    Credential credential = newFlow().loadCredential(userId);
	    return new Drive.Builder(HTTP_TRANSPORT, JSON_FACTORY, credential).build();
	  }

}

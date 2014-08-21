package weave;

import java.io.IOException;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;
import com.google.api.client.auth.oauth2.BearerToken;
import com.google.api.client.auth.oauth2.ClientParametersAuthentication;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.HttpExecuteInterceptor;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson.JacksonFactory;

public class OauthCredentialUtils {

	static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();
	static final JsonFactory JSON_FACTORY = new JacksonFactory();
	
	private static GoogleClientSecrets clientSecrets = null;

//	private static final List<String> SCOPES = Arrays.asList(
//			// Required to access and manipulate files.
//			"https://www.googleapis.com/auth/drive.file",
//			// Required to identify the user in our data store.
//			"https://www.googleapis.com/auth/userinfo.email",
//			"https://www.googleapis.com/auth/userinfo.profile");



	public static String getRedirectUri() {
		
		GenericUrl url = new GenericUrl("http://localhost:8080/GoogleServices/Oauth2Callback");
		return url.build();
	}
	
//	public static void loadClientCredentials(ServletContext context) throws IOException {
//		InputStream inputStream = context.getResourceAsStream(resourceURI);
//		Reader reader = new InputStreamReader(inputStream);
//		Preconditions.checkNotNull(inputStream, "Cannot open: %s" + resourceURI);
//		clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, reader);
//		
//	}

	public static GoogleClientSecrets getClientCredential() throws IOException {
//		if (clientSecrets == null) {
//			InputStream inputStream = new FileInputStream(new File(RESOURCE_LOCATION));
//			Reader reader = new InputStreamReader(inputStream);
//			Preconditions.checkNotNull(inputStream, "Cannot open: %s" + RESOURCE_LOCATION);
//			clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, reader);
//		}
		return clientSecrets;
	}

	public static AuthorizationCodeFlow newFlow(String clientID,String clientSecret, String authUri, String tokenUri) throws IOException {
		GenericUrl genUrl = new GenericUrl( tokenUri);
		HttpExecuteInterceptor clientAuthentication =  new ClientParametersAuthentication(clientID,clientSecret);
		return new AuthorizationCodeFlow.Builder(BearerToken.authorizationHeaderAccessMethod(),HTTP_TRANSPORT, JSON_FACTORY, genUrl,clientAuthentication, clientID,authUri).build();
	}

	

//	public static String getUserId() {
//		// Include your custom implementation for retrieval of a unique
//		// user id string from your application.
//		String userId = "";
//		return userId;
//	}
	
	
//	public static Drive loadDriveService() throws IOException {
//	    String userId = getUserId();
//	    Credential credential = newFlow().loadCredential(userId);
//	    return new Drive.Builder(HTTP_TRANSPORT, JSON_FACTORY, credential).build();
//	  }

}

package weave.servlets;




import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.servlets.WeaveServlet;



import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson.JacksonFactory;

public class OauthService extends WeaveServlet {

	private static final long serialVersionUID = 1L;

	/** Lock on the flow and credential. */
	private final Lock lock = new ReentrantLock();

	/**
	 * Define a global instance of the HTTP transport.
	 */
	public static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();

	/**
	 * Define a global instance of the JSON factory.
	 */
	public static final JsonFactory JSON_FACTORY = new JacksonFactory();
	/**
	 * Client secrets object.
	 */
	private GoogleClientSecrets clientSecrets;

	protected static  GoogleAuthorizationCodeFlow flow = null; 
	/** Persisted credential associated with the current request or {@code null} for none. */
	//private Credential credential;

	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		clientSecrets = getClientSecrets();		

	}
	
	

	/**
	 * If the user already has a valid credential held in the AuthorizationCodeFlow they
	 * are simply returned to the home page.
	 */
//	@Override
//	protected void doGet(HttpServletRequest request, HttpServletResponse response)throws ServletException, IOException {
//		response.sendRedirect("/");
//	}

//	/**
//	 * Returns the URI to redirect to with the authentication result.
//	 */
//	@Override
//	protected String getRedirectUri(HttpServletRequest request) throws ServletException, IOException {
//		return REDIRECT_URI;
//	}
//
//	/**
//	 * Returns the HTTP session id as the identifier for the current user.  The users
//	 * credentials are stored against this ID.
//	 */
//	@Override
//	protected String getUserId(HttpServletRequest request)throws ServletException, IOException {
//		return request.getSession(true).getId();
//	}






	/**
	 * Reads client_secrets.json and creates a GoogleClientSecrets object.
	 * @return A GoogleClientsSecrets object.
	 */
	private GoogleClientSecrets getClientSecrets() {
		// get from the stored file
		InputStream stream =  getServletContext().getResourceAsStream(CLIENT_SECRETS_FILE_PATH);
		Reader reader = new InputStreamReader(stream);
		try {
			return GoogleClientSecrets.load(JSON_FACTORY, reader);
		} catch (IOException e) {
			throw new RuntimeException("No client_secrets.json found");
		}
	}




	/**
	 * Build an authorization flow and store it as a static class attribute.
	 *
	 * @return GoogleAuthorizationCodeFlow instance.
	 * @throws IOException Unable to load client_secrets.json.
	 */
	protected GoogleAuthorizationCodeFlow initializeFlow() throws  RemoteException {
		//if (flow == null) {
			flow = new GoogleAuthorizationCodeFlow.Builder(HTTP_TRANSPORT, JSON_FACTORY, clientSecrets, SCOPES)
			.setAccessType("offline").setApprovalPrompt("force").build();
		//}
		return flow;
	}

	/**
	 * Path component under war/ to locate client_secrets.json file.
	 */
	private static final String CLIENT_SECRETS_FILE_PATH = "/WEB-INF/client_secrets.json";
	//private static final String REDIRECT_URI = "<YOUR_REGISTERED_REDIRECT_URI>";
	private static final List<String> SCOPES = Arrays.asList(
			// Required to access and manipulate files.
			"https://www.googleapis.com/auth/drive.file",
			// Required to identify the user in our data store.
			"https://www.googleapis.com/auth/userinfo.email",
			"https://www.googleapis.com/auth/userinfo.profile");



	/**
	 * Authorizes the installed application to access user's protected data.
	 *
	 * @param scopes              list of scopes needed to run youtube upload.
	 * @param credentialDatastore name of the credential datastore to cache OAuth tokens
	 */
	public void authorize() throws  RemoteException {



		//    MemoryDataStoreFactory memoryDataStoreFactory = new MemoryDataStoreFactory();
		//    DataStore<StoredCredential> datastore = memoryDataStoreFactory.getDataStore(credentialDatastore);
		//
		//    GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
		//            HTTP_TRANSPORT, JSON_FACTORY, clientSecrets, SCOPES).setCredentialDataStore(datastore)
		//            .build();

		lock.lock();
		try {
			// load credential from persistence store
			// String userId = getUserId(req);
			//if (flow == null) {
				flow = initializeFlow();
			//}
			// credential = flow.loadCredential(userId);
			// if credential found with an access token, invoke the user code
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
			// redirect to the authorization flow
			//	      String redirectUri = getRedirectUri(req);
			//	      resp.sendRedirect(flow.newAuthorizationUrl().setRedirectUri(redirectUri).build());
			//	      credential = null;
		} finally {
			lock.unlock();
		}
	}
}

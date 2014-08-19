package weave.config;


public class OauthConfig {
	private static OauthContextParams oauthContextParams = null;
	
	public static void initOauthConfig(OauthContextParams wcp)
	{
		if (oauthContextParams == null)
		{
			oauthContextParams = wcp;
		}
	}
	
	public static OauthContextParams getOauthContextParams()
	{
		return oauthContextParams;
	}
	
	
}

package weave.config;


public class GoogleConfig {
	private static GoogleContextParams googleContextParams = null;
	
	public static void initGoogleConfig(GoogleContextParams wcp)
	{
		if (googleContextParams == null)
		{
			googleContextParams = wcp;
		}
	}
	
	public static GoogleContextParams getGoogleContextParams()
	{
		return googleContextParams;
	}
	
	
}

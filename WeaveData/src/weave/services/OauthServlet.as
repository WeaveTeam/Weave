package weave.services
{
	import mx.rpc.AsyncToken;
	
	import weave.api.core.ILinkableObject;

	public class OauthServlet implements ILinkableObject
	{
		public function OauthServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
		}
		
		protected var servlet:AMF3Servlet;
		
		public function triggerOauthFlow(clientID:String,clientSecret:String , authUri:String , tokenUri:String ):AsyncToken {
			return servlet.invokeAsyncMethod("triggerOauthFlow", arguments);
		}
			
	}
}
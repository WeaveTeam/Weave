package weave.services
{
	import mx.rpc.AsyncToken;

	public class GoogleServlet
	{
		public function GoogleServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
		}
		
		protected var servlet:AMF3Servlet;
		
		/*public function authorize():AsyncToken
		{
			return servlet.invokeAsyncMethod("authorize", arguments);
		}*/
		
		public function getFileMetaData(fileId:String):AsyncToken{
			return servlet.invokeAsyncMethod("getFileMetaData", arguments);
		}
	}
}
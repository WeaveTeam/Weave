package weave.services
{
	
	import mx.rpc.AsyncToken;
	
	import weave.utils.ByteArrayUtils;
	public class WeavePDBServlet
	{
		public function WeavePDBServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
		}
		
		protected var servlet:AMF3Servlet;
		
		// async result will be of type KMeansClusteringResult
		public function getPhiPsiValues(pdbID:String):AsyncToken
		{			
			return servlet.invokeAsyncMethod("extractPhiPsi", arguments);
		}
	}
}
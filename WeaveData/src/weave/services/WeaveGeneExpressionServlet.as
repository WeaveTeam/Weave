package weave.services
{
	import mx.rpc.AsyncToken;

	public class WeaveGeneExpressionServlet
	{
		
		
		public function WeaveGeneExpressionServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
		}
		
		protected var servlet:AMF3Servlet;
		
		// async result will be of type KMeansClusteringResult
		public function getGeneExpressionData(queryStr:String):AsyncToken
		{			
			return servlet.invokeAsyncMethod("extractGeneExpressionData", arguments);
		}
	}
}
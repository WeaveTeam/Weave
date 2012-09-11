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
		
		
		public function getGeneExpressionData(queryStr:String):AsyncToken
		{			
			return servlet.invokeAsyncMethod("extractGeneExpressionData", arguments);
		}
		
		public function getGeneList(queryStr:String):AsyncToken
		{			
			return servlet.invokeAsyncMethod("getGeneList", arguments);
		}
		
		public function getConditionsList(queryStr:String):AsyncToken
		{			
			return servlet.invokeAsyncMethod("getConditionsList", arguments);
		}
		
	}
}
package weave.services
{
	import mx.rpc.AsyncToken;
	public class WeaveJRIServlet
	{
		public function WeaveJRIServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
		}
		protected var servlet:AMF3Servlet;
		
		public function runScript(keys:Array,inputNames:Array, inputValues:Array, outputNames:Array, script:String,plotScript:String, showIntermediateResults:Boolean, showWarningMessages:Boolean,useColumnAsList:Boolean ):AsyncToken
		{
			return servlet.invokeAsyncMethod("runScript", arguments);
		}
	}
}
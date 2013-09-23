package weave.services
{
	import weave.api.core.ILinkableObject;
	import mx.rpc.AsyncToken;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
    public class WeaveRenderServlet implements ILinkableObject
    {
        protected var servlet:AMF3Servlet;

        public function WeaveRenderServlet(url:String)
        {
            servlet = new AMF3Servlet(url);       
			registerLinkableChild(this, servlet);
        }
        public function getRenderContext(backendType:String):AsyncToken // String
        {
            return servlet.invokeAsyncMethod("getRenderContext", arguments);
        }
        public function destroyRenderContext(contextUuid:String):AsyncToken // boolean
        {
            return servlet.invokeAsyncMethod("destroyRenderContext", arguments);
        }
        public function setData(contextUuid:String, columnNames:Array, columnIds:Array):AsyncToken // boolean
        {
            return servlet.invokeAsyncMethod("setData", arguments);
        }
        public function setParams(contextUuid:String, paramNames:Array, paramValues:Array):AsyncToken // boolean
        {
            return servlet.invokeAsyncMethod("setParams", arguments);
        }
        public function getImage(contextUuid:String, x1:int, y1:int, x2:int, y2:int, width:int, height:int):AsyncToken // returns a string containing the PNG
        {
            return servlet.invokeAsyncMethod("getImage", arguments);
        }
        public function render(contextUuid:String):AsyncToken
        {
            return servlet.invokeAsyncMethod("render", arguments);
        }
        public function probe(contextUuid:String, x:int, y:int):AsyncToken
        {
            return servlet.invokeAsyncMethod("probe", arguments);
        }
        public function setSelectedKeys(contextUuid:String, keys:Array):AsyncToken
        {
            return servlet.invokeAsyncMethod("setSelectedKeys", arguments);
        }
        public function setProbedKeys(contextUuid:String, keys:Array):AsyncToken
        {
            return servlet.invokeAsyncMethod("setProbedKeys", arguments);
        }

    }
}

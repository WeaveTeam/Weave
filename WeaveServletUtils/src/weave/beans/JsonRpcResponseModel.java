package weave.beans;

public class JsonRpcResponseModel
{
	public String jsonrpc = "2.0";
	public Object result;
	public JsonRpcErrorModel error;
	public Object id;
}

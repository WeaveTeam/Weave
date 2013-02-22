package weave.beans;

public class JsonRpcRequestModel {

	public String jsonrpc = "2.0";
	public String method;
	public String id;
	public Object params;
}

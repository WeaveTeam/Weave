package weave.servlets;

import java.io.File;
import java.rmi.RemoteException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.AwsContextParams;
import weave.models.ScriptManagerService;
import weave.utils.AWSUtils;

import com.google.gson.JsonObject;

public class ScriptManagementServlet extends WeaveServlet
{
	private static final long serialVersionUID = 1L;
	
	public ScriptManagementServlet(){
		
	}

	private File rDirectory;
	private File stataDirectory;
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		rDirectory = new File(AwsContextParams.getInstance(config.getServletContext()).getRScriptsPath());
		stataDirectory = new File(AwsContextParams.getInstance(config.getServletContext()).getStataScriptsPath());
		
	}
	
	public String getScript(String scriptName) throws Exception {
		 
 		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
 		{
 			return ScriptManagerService.getScript(rDirectory, scriptName);
 		} else if( AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
 		{
 			return ScriptManagerService.getScript(stataDirectory, scriptName);
 		} else {
 			throw new RemoteException("Unknown Script Type");
  		}

	}
	
	public String[] getListOfScripts() throws Exception{
		
 		File[] directories = {rDirectory, stataDirectory};
 		return ScriptManagerService.getListOfScripts(directories);
	}
		 
	public String[] getListOfRScripts() throws Exception{
		return ScriptManagerService.getListOfScripts(new File[] {rDirectory});
	}
	
	public String[] getListOfStataScripts() throws Exception{
		return ScriptManagerService.getListOfScripts(new File[] {stataDirectory});
	}
	
	public Object getScriptMetadata(String scriptName) throws Exception{
		
		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
 		{
			return ScriptManagerService.getScriptMetadata(rDirectory, scriptName);
 		} else if( AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
 		{
 			return ScriptManagerService.getScriptMetadata(stataDirectory, scriptName);
 		} else {
 			throw new RemoteException("Unknown Script Type");
  		}
		
	}
	
	
 	public boolean saveScriptMetadata (String scriptName, JsonObject metadata) throws Exception {
 
 		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
 		{
 			return ScriptManagerService.saveScriptMetadata(rDirectory, scriptName, metadata);
 		} else if( AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
 		{
 			return ScriptManagerService.saveScriptMetadata(stataDirectory, scriptName, metadata);
 		} else {
 			throw new RemoteException("Unknown Script Type");
  		}
	 }
	
// 	public boolean uploadNewScript(String scriptName, String content) throws Exception {
// 		 
// 		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
// 		{
// 			return ScriptManagerService.uploadNewScript(rDirectory, scriptName, content);
// 		} else if( AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
// 		{
// 			return ScriptManagerService.uploadNewScript(stataDirectory, scriptName, content);
// 		} else {
// 			throw new RemoteException("Unknown Script Type");
//  		}
// 	}
// 	
 	
 	public boolean uploadNewScript(String scriptName, String content, JsonObject metadata) throws Exception {
 		 
 		if(metadata == null)
 			metadata = new JsonObject();//will use blank jsonobejct is metadata is not specified
 		
 		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
 		{
 			return ScriptManagerService.uploadNewScript(rDirectory, scriptName, content, metadata);
 		} else if( AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
 		{
 			return ScriptManagerService.uploadNewScript(stataDirectory, scriptName, content, metadata);
 		} else {
 			throw new RemoteException("Unknown Script Type");
  		}
 	}
 	
 	public boolean deleteScript(String scriptName) throws Exception {
 		 
 		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
 		{
 			return ScriptManagerService.deleteScript(rDirectory, scriptName);
 		} else if( AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
 		{
 			return ScriptManagerService.deleteScript(stataDirectory, scriptName);
 		} else {
 			throw new RemoteException("Unknown Script Type");
 		}
 	}
}

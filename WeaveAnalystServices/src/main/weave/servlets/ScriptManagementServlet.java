package weave.servlets;

import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;

import weave.servlets.WeaveServlet;

import weave.config.AwsContextParams;
import weave.config.WeaveContextParams;
import weave.models.ScriptManagerService;

public class ScriptManagementServlet extends WeaveServlet
{
	private static final long serialVersionUID = 1L;
	
	public ScriptManagementServlet(){
		
	}

	private static String awsConfigPath = "";
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		awsConfigPath = AwsContextParams.getInstance(config.getServletContext()).getAwsConfigPath(); 
	}
	
	
	
	public Object delegateToScriptManagementMethods(String action, Map<String, Object> params){
		Object returnStatus = null;
		
		if(action.matches("REPORT_SCRIPTS_LIST")){
				returnStatus = ScriptManagerService.getListOfScripts(awsConfigPath);
		}
		else if(action.matches("REPORT_SCRIPT_CONTENTS")){
			try {
				returnStatus = ScriptManagerService.getScript(awsConfigPath,params);
			} catch (Exception e) {
				e.printStackTrace();
			} 
		}
		else if(action.matches("SAVE_METADATA")){
			try{
				returnStatus = ScriptManagerService.saveMetadata(awsConfigPath, params);
			}
			catch(Exception e){
				e.printStackTrace();
			}
		}
		else if(action.matches("REPORT_SCRIPT_METADATA")){
			try{
				returnStatus = ScriptManagerService.getScriptMetadata(awsConfigPath, params);
			}
			catch(Exception e){
				e.printStackTrace();
			}
		}
		else if(action.matches("UPLOAD_NEW_SCRIPT")){
				returnStatus = ScriptManagerService.uploadNewScript(awsConfigPath, params);
		}
	
		
		
		
		return returnStatus;
	}
}

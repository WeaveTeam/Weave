package weave.config;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;

import org.apache.commons.io.FilenameUtils;

import weave.utils.Strings;

public class AwsContextParams
{
	private static String awsConfigPath = "";
	private static String stataPath = "";
	private static String rScriptsPath = "";
	private static String stataScriptsPath = "";
	private static String pythonScriptPath = "";
	
	public static AwsContextParams getInstance(ServletContext context)throws ServletException{
		if (_instance == null)
			_instance = new AwsContextParams(context);
		return _instance;
		
	}
	
	private static AwsContextParams _instance ;
	
	private AwsContextParams(ServletContext  context) throws ServletException
	{
		awsConfigPath = context.getRealPath(context.getInitParameter("awsconfigPath")).replace('\\','/');
		
		stataPath = context.getInitParameter("StataPath").replace('\\','/');
		
		// if StataPath is not specified, keep it empty
		if (!Strings.isEmpty(stataPath))
			stataPath = stataPath.replace('\\', '/');
				
		rScriptsPath= FilenameUtils.concat(awsConfigPath, "RScripts");
		stataScriptsPath = FilenameUtils.concat(awsConfigPath, "StataScripts");
		pythonScriptPath = FilenameUtils.concat(awsConfigPath, "PythonScripts");
	}
	
	
	/**
	 * @return The path where aws config files are stored, ending in "/"
	 */
	public String getAwsConfigPath(){

		return awsConfigPath;
	}

	/**
	 * @return The path where R scripts are uploaded ending in "/"
	 */
	public String getRScriptsPath() {
		return rScriptsPath;
	}

	/**
	 * @return The path where uploaded files are stored, ending in "/"
	 */
	public String getStataScriptsPath() {
		return stataScriptsPath;
	}
	
	/**
	 * @return The path where to stata.exe on windows or env variable on Unix
	 */
	 public String getStataPath(){
	 	return stataPath;
	 }
	 
	 /**
	  * @return The path where uploaded files are stored, ending in "/"
	  */
	 public String getPythonScriptsPath(){
		 return pythonScriptPath;
	 }
}

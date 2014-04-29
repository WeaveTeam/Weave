package weave.models;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.WeaveContextParams;
import weave.servlets.WeaveServlet;

import com.google.gson.Gson;
import weave.config.AwsContextParams;

public class ScriptManagerService extends WeaveServlet{

	private static final long serialVersionUID = 1L;
	//private static String awsConfigPath = "";
	
	public ScriptManagerService(){
		
	}
	
	/**
	 * Gives an object containing the script contents
	 * 
	 * @param scriptName
	 * @return
	 */
	public static String getScript(String awsConfigPath, Map<String, Object> params) throws Exception{
    	File directory = new File(awsConfigPath, "RScripts");
		String[] files = directory.list();
		String scriptContents = new String();
		BufferedReader bufr = null;
		String scriptName = params.get("scriptName").toString(); 
		
		for (int i = 0; i < files.length; i++)
		{
			if(scriptName.equalsIgnoreCase(files[i])){
				try {
					bufr = new BufferedReader(new FileReader(new File(directory, scriptName)));
					String contents = "";
					while((contents = bufr.readLine()) != null){
						scriptContents = scriptContents + contents + "\n";
					}
				} catch (IOException e) {
					e.printStackTrace();
				} finally {
					try {
						if(bufr != null){
							bufr.close();
						}
					} catch (IOException ex) {
						ex.printStackTrace();
					}
				}
			}
		}
		return scriptContents;
    }

	public static String[] getListOfScripts(String awsConfigPath) {

		File directory = new File(awsConfigPath, "RScripts");
		String[] files = directory.list();
		List<String> rFiles = new ArrayList<String>(); 
		String extension = "";

		for (int i = 0; i < files.length; i++) {
			extension = files[i].substring(files[i].lastIndexOf(".") + 1,
					files[i].length());
			if (extension.equalsIgnoreCase("r"))
				rFiles.add(files[i]);
		}
		return rFiles.toArray(new String[rFiles.size()]);
	}

	public static String saveMetadata(String awsConfigPath,Map<String,Object>params) throws Exception {
		String status = "";
		String scriptName = params.get("scriptName").toString();
		Object scriptMetadata = params.get("scriptMetadata");
		if(scriptName.length() < 3){
			return "The script Name is invalid";
		}
		
		String jsonFileName = scriptName.substring(0, scriptName.lastIndexOf('.')).concat(".json");
		File file = new File(awsConfigPath + "RScripts", jsonFileName);
		if (!file.exists()){
			file.createNewFile();
			//throw new RemoteException("Metadata file: " + jsonFileName + "does not exist");
		}
		
		FileWriter fw = new FileWriter(file.getAbsolutePath());
		BufferedWriter bw = new BufferedWriter(fw);
		Gson gson = new Gson();
		gson.toJson(scriptMetadata, bw);
		bw.close();
		
		status = "success";
		return status;
	}

	public static Object getScriptMetadata(String awsConfigPath, Map<String,Object> params) throws Exception {
		File directory = new File(awsConfigPath, "RScripts");
		String[] files = directory.list();
		String scriptName = params.get("scriptName").toString();
		int filecount = 0;
		// this object will get the metadata from the json file
		Object scriptMetadata = new Object();
		
		// we replace scriptname.R with scriptname.json
		String jsonFileName = scriptName.substring(0, scriptName.lastIndexOf('.')).concat(".json");

		// we will check if there is a json file with the same name in the directory.
		for (int i = 0; i < files.length; i++)
		{
			if (jsonFileName.equalsIgnoreCase(files[i]))
			{
				filecount++;
				// do the work
				Gson gson = new Gson();
				
				if(filecount > 1) {
					throw new RemoteException("multiple copies of " + jsonFileName + "found!");
				}
				
				try {
					
					BufferedReader br = new BufferedReader(new FileReader(new File(directory, jsonFileName)));
					
					scriptMetadata = gson.fromJson(br, Object.class);
					
					//System.out.println(scriptMetadata);
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
		// 
		if(filecount == 0) {
			throw new RemoteException("Could not find the file " + jsonFileName + "!");
		}
		
		return scriptMetadata;
	}
	
	public static Boolean uploadNewScript(String awsConfigPath, Map<String, Object> params){
		String scriptName = params.get("scriptName").toString();
		Object fileObject = params.get("fileObject");
		File file = new File(awsConfigPath + "RScripts", scriptName);
		if (!file.exists()){
			try{
				file.createNewFile();
				FileWriter fw = new FileWriter(file.getAbsolutePath());
				BufferedWriter bw = new BufferedWriter(fw);
				bw.write( (String) fileObject);
				bw.flush();

				bw.close();
			}catch(IOException e){
				e.printStackTrace();
			}
		}
		
		String jsonFileName = scriptName.substring(0, scriptName.lastIndexOf('.')).concat(".json");
		file = new File(awsConfigPath + "RScripts", jsonFileName);
		if(!file.exists()){
				try {
					file.createNewFile();
				} catch (IOException e) {
					e.printStackTrace();
				}
		}

		return true;
	}
	
	public Boolean deleteScript(String scriptName, String password) throws RemoteException
	{
//		if(authenticate()){
//			File file = new File(awsConfigPath + "RScripts", scriptName);
//			file.delete();
//		}else{
//			throw new RemoteException("Authentication Failure");
//		}
		return false;
	}
}

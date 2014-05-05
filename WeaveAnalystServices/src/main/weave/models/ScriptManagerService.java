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

import org.apache.commons.io.FilenameUtils;

import weave.servlets.WeaveServlet;
import weave.utils.AWSUtils;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class ScriptManagerService extends WeaveServlet{

	private static final long serialVersionUID = 1L;
	//private static String awsConfigPath = "";
	
	public ScriptManagerService(){
		
	}
	
	
		 /**
		  * 
		  * @param directory The location of the script
		  * @param scriptName The name of the script
		  *
		  * @return The script content as a string
		  * @throws Exception
		  */
		public static String getScript(File directory, String scriptName) throws Exception{
		String[] files = directory.list();
		String scriptContents = new String();
		BufferedReader bufr = null;
		
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


	/**
	 * This function navigates all the given directories and return the list of all known scripts
	 *
	 * @param directories
	 * 
	 * @return Array of script names
	 */
		public static String[] getListOfScripts(File[] directories) {
	
			List<String> listOfScripts = new ArrayList<String>();
	
	 	for(int i = 0; i < directories.length; i++)
	 	{
	 		File directory = directories[i];
	 		String[] files = directory.list();
	 		if(files != null)
	 			{
	 				
	 				for (int j = 0; j < files.length; j++) 
	 				{
	 					if(AWSUtils.getScriptType(files[j]) != AWSUtils.SCRIPT_TYPE.UNKNOWN)
	 					{
	 						listOfScripts.add(files[j]);
	 					}
	 				}
	 			}
	 	}
	 	
	 	return listOfScripts.toArray(new String[listOfScripts.size()]);
	}

	/**
	 * 
	 * This function saves the script metadata at the same location as the script.
	 * 
 	 * @param directory The location of the script
 	 * @param scriptName The script name
 	 * @param scriptMetadata The metadata to be saved
 	 * 
 	 * @return Returns true if the metadata was saved.
 	 * @throws Exception
 	 */
 	public static boolean saveScriptMetadata(File directory, String scriptName, JsonObject scriptMetadata) throws Exception {
 
 		// create json file name
 		String jsonFileName = FilenameUtils.removeExtension(scriptName).concat(".json");
 
 		File file = new File(directory, jsonFileName);
 
		if (!file.exists()){
			file.createNewFile();
		}
		
		FileWriter fw = new FileWriter(file.getAbsolutePath());
		BufferedWriter bw = new BufferedWriter(fw);
		Gson gson = new Gson();
		gson.toJson(scriptMetadata, bw);
		bw.close();
		
		return true;
	}

	/**
	 * 
	 * @param directory The directory where the script is located
	 * @param scriptName The script name relative
	 * 
	 * @return The script metadata as a Json object
	 * @throws Exception
	 */
 	public static Object getScriptMetadata(File directory, String scriptName) throws Exception {
	// this object will get the metadata from the json file
 		Object scriptMetadata;
 		Gson gson = new Gson();
 		String jsonFileName = FilenameUtils.removeExtension(scriptName).concat(".json");
 		File metadataFile = new File(directory, jsonFileName);
 		if(metadataFile.exists())
 		{
 			BufferedReader br = new BufferedReader(new FileReader(new File(directory, jsonFileName)));
 			scriptMetadata = gson.fromJson(br, Object.class);
 			return scriptMetadata;
 		}
 		
 		else
 		{
 				throw new RemoteException("Could not find script metadata");
 		}
	}
	
 	/**
	 * 
	 * This function uploads a new script with a blank metadata file
	 * 
	 * @param directory
	 * @param scriptName
	 * @param content
	 * @return
	 * @throws Exception
	 */
	public static Boolean uploadNewScript(File directory, String scriptName, String content) throws Exception
	{
		JsonObject metadata = new JsonObject();
		return uploadNewScript(directory, scriptName, content, metadata);
	}

 	
   /**
	 * 
	 * This function uploads a new script with metadata
	 * 
	 * @param directory
	 * @param scriptName
	 * @param content
	 * @param metadata
	 * @return
	 * @throws Exception
	 */
	public static Boolean uploadNewScript(File directory, String scriptName, String content, JsonObject metadata) throws Exception
	{
		File file = new File(directory, scriptName);

 		try
 		{
 			file.createNewFile();
 			FileWriter fw = new FileWriter(file);
 			BufferedWriter bw = new BufferedWriter(fw);
 			bw.write(content);
 			bw.flush();
 			bw.close();
 		}catch(IOException e){
 			e.printStackTrace();
  		}
  
 		saveScriptMetadata(directory, scriptName, metadata);
 
  		return true;
  	}
	
	
	/**
 	 * 
 	 * Delete a script and its metadata
 	 * 
 	 * @param directory
 	 * @param scriptName
 	 * @return
 	 * @throws RemoteException
 	 */
 	public static Boolean deleteScript(File directory, String scriptName) throws RemoteException
  	{
			File script = new File(directory, scriptName);
	 		File metadata = new File(directory, FilenameUtils.removeExtension(scriptName).concat(".json"));
	 
	 		if(script.delete() && metadata.delete())
	 		{
	 			return true;
	 		}
	 		else
	 		{
	 			throw new RemoteException("Could not properly delete script and metadata");
	 		}
	}
	  	
}

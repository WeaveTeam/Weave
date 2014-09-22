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

import com.google.gson.Gson;
import com.google.gson.internal.StringMap;

import weave.utils.AWSUtils;

public class ScriptManagerService{

	
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
 	public static boolean saveScriptMetadata(File directory, String scriptName, String scriptMetadata) throws Exception {
 
 		// create json file name
 		String jsonFileName = FilenameUtils.removeExtension(scriptName).concat(".json");
 
 		File file = new File(directory, jsonFileName);
 
		if (!file.exists()){
			file.createNewFile();
		}
		
		FileWriter fw = new FileWriter(file.getAbsolutePath());
		BufferedWriter bw = new BufferedWriter(fw);
		bw.write(scriptMetadata);
		bw.flush();
		bw.close();
		
		return true;
	}
 	
 	/**
	 * 
	 * This function saves the script content, overwriting the current script content.
	 * 
 	 * @param directory The location of the script
 	 * @param scriptName The script name
 	 * @param content The new content to be saved
 	 * 
 	 * @return Returns true if the content was saved.
 	 * @throws Exception
 	 */
 	public static boolean saveScriptContent(File directory, String scriptName, String content) throws Exception {
 
 		// create json file name
 		File file = new File(directory, scriptName);
 
		if (!file.exists()){
			file.createNewFile();
		}
		
		FileWriter fw = new FileWriter(file.getAbsolutePath());
		BufferedWriter bw = new BufferedWriter(fw);
		bw.write(content);
		bw.flush();
		bw.close();
		
		return true;
	}
 	
 	/**
 	 * This function checks if a script with the given name already exists in the given directory
 	 * 
 	 * @param directory
 	 * @param scriptName
 	 * @return
 	 * @throws Exception
 	 */
 	public static boolean scriptExists(File directory, String scriptName) throws Exception {
		
		return new File(directory, scriptName).exists();
		
	}
 	/**
	 * 
	 * This function renames a script, and update the content and metadata.
	 *  
 	 * @param directory The location of the script
 	 * @param oldScriptName The old script name to be modified.
 	 * @param newScriptName The new script name to be used.
 	 * @param content The new content to be saved.
 	 * @param metadata The new metadata to be saved.
 	 * 
 	 * @return Returns true if the content was saved.
 	 * @throws Exception
 	 */
 	public static boolean renameScript(File directory, String oldScriptName, String newScriptName, String content, String metadata) throws Exception {
 
		if(!deleteScript(directory, oldScriptName))
			return false;
		
		return uploadNewScript(directory, newScriptName, content, metadata);
	}

 	/**
	 * 
	 * @param directory The directory where the script is located
	 * @param scriptName The script name relative
	 * 
	 * @return The script metadata as a Json object
	 * @throws Exception
	 */
 	public static StringMap<Object> getScriptMetadata(File directory, String scriptName) throws RemoteException {
	// this object will get the metadata from the json file
 		Gson gson = new Gson();
 		String jsonFileName = FilenameUtils.removeExtension(scriptName).concat(".json");
 		File metadataFile = new File(directory, jsonFileName);
 		
 		try {
 			if(!metadataFile.exists())
 			{
 				throw new RemoteException("Cannot find script metadata file.");
 			}
 			BufferedReader br = new BufferedReader(new FileReader(new File(directory, jsonFileName)));
 			return gson.fromJson(br, StringMap.class);
 		} catch(Exception e) {
 			throw new RemoteException("Error reading script metadata file.");
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
		String metadata = "";
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
	public static Boolean uploadNewScript(File directory, String scriptName, String content, String metadata) throws Exception
	{
		File file = new File(directory, scriptName);

 		try
 		{
 			if(!file.exists()) {
 				file.createNewFile();
 				FileWriter fw = new FileWriter(file);
 				BufferedWriter bw = new BufferedWriter(fw);
 				bw.write(content);
 				bw.flush();
 				bw.close();
 			} else {
 				return false;
 			}
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

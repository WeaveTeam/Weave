package weave.models.computations;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

import org.apache.commons.io.FilenameUtils;
import com.google.gson.internal.StringMap;

import weave.utils.CSVParser;
import weave.utils.CommandUtils;

import weave.utils.AWSUtils;
import weave.utils.AWSUtils.OS_TYPE;
import weave.models.computations.IScriptEngine;

public class AwsStataService implements IScriptEngine {

	public static Object runScript(String scriptName, StringMap<Object> scriptInputs, String programPath, String tempDirPath, String scriptPath) throws Exception {

		int exitValue = -1;
		
		ArrayList<Object[]> data = new ArrayList<Object[]>();
		Object[][] dataSet;
		HashMap<String, Object> finalResult= null;
		
		for(String key : scriptInputs.keySet()) {
			ArrayList<Object> arrl = new ArrayList<Object>();
			arrl.add(key);
			if(scriptInputs.get(key) instanceof Object[]) {
				Object[] temp = (Object[]) scriptInputs.get(key);
				for(int i = 0; i < temp.length; i++) {
					arrl.add(temp[i]);
				}
			} else {
				arrl.add(scriptInputs.get(key));
			}
			data.add(arrl.toArray(new Object[arrl.size()]));
		}
		
		dataSet = (Object[][]) AWSUtils.transpose(data.toArray(new Object[data.size()][]));
		
		CSVParser parser = new CSVParser();
		//Gson jsonParser = new Gson();
		String tempScript = "";
		String[][] resultData;
		String[] args = null;
		File dataSetCSV = null;
		File tempScriptFile = null;
		File tempDirectory = new File(tempDirPath);
		if(!tempDirectory.exists() || !tempDirectory.isDirectory())
		{
			tempDirectory.mkdir();
		} 

		try 
		{
			dataSetCSV = new File(FilenameUtils.concat(tempDirectory.getCanonicalPath(), "data.csv"));
			BufferedWriter out = new BufferedWriter(new FileWriter(dataSetCSV));
			parser.createCSV(dataSet, true, out, true);
			//jsonParser.toJson(dataSet, out);
			out.close();
		} 

		catch( IOException e)
		{
			e.printStackTrace();
			throw new RemoteException("Error while trying to write dataset to file");
		}

		try 
		{
			tempScript += "insheet using " + dataSetCSV.getAbsolutePath() + ", clear" + "\n" +
			 	"global path=\"" + tempDirPath + "\"\n" +
			 	"cd \"$path/\" \n" +
			 	"noisily do " + new File(FilenameUtils.concat(scriptPath, scriptName)).getAbsolutePath() + "\n" +
			 	"capture erase tempScript.log\n";
			 	// "capture erase " +  tempDirPath + "tempScript.log";
			tempScriptFile = new File(FilenameUtils.concat(tempDirectory.getAbsolutePath(), "tempScript.do"));
			BufferedWriter out = new BufferedWriter(new FileWriter(tempScriptFile));
			out.write(tempScript);
			out.close();
		} 
		catch( IOException e)
		{
			e.printStackTrace();
			throw new RemoteException("Error while trying to write script wrapper to file");
		}

		if(AWSUtils.getOSType() == OS_TYPE.LINUX || AWSUtils.getOSType() == OS_TYPE.OSX)
		{
			args = new String[] {programPath, "-b", "-q", "do", FilenameUtils.concat(tempDirPath, "tempScript.do")};

		}

		else if(AWSUtils.getOSType() == OS_TYPE.WINDOWS)
		{
			args = new String[] {programPath, "/e", "/q", "do", FilenameUtils.concat(tempDirPath, "tempScript.do")};
		}

		else if(AWSUtils.getOSType() == OS_TYPE.UNKNOWN)
		{
			throw new RemoteException("unsupported os type");
		}

		try {
			exitValue = CommandUtils.runCommand(args, null, tempDirectory);
			if(exitValue != 0)
			{
				throw new RemoteException("Stata terminated with exit value " + exitValue);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}

		// Since we cannot rely on the return value of the Stata process,
		// We will assume that the log file is erased at the end of the script.
		// Therefore if the log exists, the program did not terminate

		// remove extension .do extension and add .log
		File logFile = new File(FilenameUtils.removeExtension(tempScriptFile.getAbsolutePath()).concat(".log"));

		// for now we assume result is always in result.csv
		File scriptResult = new File(tempDirectory.getAbsolutePath(), "result.csv");

		if(logFile.exists()) {
			// parse log file for ouput only
			String error = getErrorsFromStataLog(logFile);
			throw new RemoteException("Error while running Stata script: " + error);
		} else {
			if(scriptResult.exists()) {
				resultData = parser.parseCSV(scriptResult, true);
				finalResult = new HashMap<String,Object>();
				ArrayList<String[]>tempArray = new ArrayList<String[]>();
				for(int i = 1; i < resultData.length; i++) {
					tempArray.add(resultData[i]);
				}
				finalResult.put("columnNames", resultData[0]);
				finalResult.put("resultData", (Object[][]) AWSUtils.transpose((Object)tempArray.toArray(new String[tempArray.size()][])));
				
			} else {
				throw new RemoteException("Could not find result.csv");
			}
		}
		return finalResult;
	}
	
	/**
	 * This functions reads a stata .log log file and returns the outputs
	 * 
	 * @param filename
	 * @return the log outputs
	 */
	private static String getErrorsFromStataLog(File file) throws Exception
	{
		String outputs = "";

		BufferedReader br = new BufferedReader(new FileReader(file));

		String line;
		while ((line = br.readLine()) != null) {
			 if (line.startsWith(".") || line.startsWith(">")|| line.startsWith("runn") || line.startsWith("\n")|| line.startsWith(" ")) // run skips output lines for do files
		   {
			   // this is a command input.. skip
			   continue;
		   }
		   else
		   {
			   outputs += line;
		   }
			// process the line.
		}
		br.close();

		return outputs;
	}

}
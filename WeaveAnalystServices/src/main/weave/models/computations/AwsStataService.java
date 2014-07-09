package weave.models.computations;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.rmi.RemoteException;

import org.apache.commons.io.FilenameUtils;

import weave.utils.CSVParser;
import weave.utils.CommandUtils;

import weave.utils.AWSUtils;
import weave.utils.AWSUtils.OS_TYPE;
import weave.models.computations.IScriptEngine;

public class AwsStataService implements IScriptEngine {

	public static Object runScript(String scriptName, String json, String programPath, String tempDirPath, String scriptPath) throws Exception {

		
		int exitValue = -1;
		CSVParser parser = new CSVParser();
		String tempScript = "";
		String[][] resultData;
		String[] args = null;
		File tempScriptFile = null;
		File tempDirectory = new File(tempDirPath);
		if(!tempDirectory.exists() || !tempDirectory.isDirectory())
		{
			tempDirectory.mkdir();
		} 

		if(new File(tempDirectory.getAbsolutePath(), "result.csv").exists())
		{
			if(!new File(tempDirectory.getAbsolutePath(), "result.csv").delete()) {
				throw new RemoteException("Cannot delete result.csv");
			}
		}

		try {
			//write converted json data to a file named "file.json"
			FileWriter writer = new FileWriter(FilenameUtils.concat(tempDirPath, "data.json"));
			writer.write(json);
			writer.close();
	 
		} catch (IOException e) {
			e.printStackTrace();
			throw new RemoteException("Error while trying to write dataset to file");
		}

		try 
		{
			tempScript += "insheetjson using " + FilenameUtils.concat(tempDirPath, "data.json") + ", clear" + "\n" +
					"global path=\"" + tempDirPath + "\"\n" +
					"cd \"$path/\" \n" +
					"noisily do " + new File(FilenameUtils.concat(scriptPath, scriptName)).getAbsolutePath() + "\n";

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

		if(scriptResult.exists()) {
			// parse log file for ouput only
			resultData = parser.parseCSV(scriptResult, true);
			scriptResult.delete();
		} else {
			if(logFile.exists()) {
				String error = getErrorsFromStataLog(logFile);
				throw new RemoteException("Error while running Stata script: " + error);
			} else {
				throw new RemoteException("Script did not produce result.csv and no log file found.");
			}
		}
		return resultData;
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
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

	public static Object runScript(String scriptAbsPath, Object[][] dataSet, String programPath, String tempDirPath) throws Exception {

		int exitValue = -1;
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
			dataSetCSV = new File(FilenameUtils.concat(tempDirectory.getAbsolutePath(), "data.csv"));
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
			// TODO set up the csv variables name
			tempScript += "insheet using " + dataSetCSV.getAbsolutePath() + ", clear \n" +
					"noisily do " + scriptAbsPath;

			tempScriptFile = new File(tempDirectory.getAbsolutePath() + "tempScript.do");
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
			args = new String[] {programPath, "-b", "-q", "do", tempScriptFile.getCanonicalPath()};

		}

		else if(AWSUtils.getOSType() == OS_TYPE.WINDOWS)
		{
			args = new String[] {programPath, "/e", "/q", "do", tempScriptFile.getCanonicalPath()};
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
		File scriptResult = new File(tempDirectory.getAbsolutePath() + "result.csv");

		if(logFile.exists()) {
			// parse log file for ouput only
			String error = getErrorsFromStataLog(logFile);
			throw new RemoteException("Error while running Stata script: " + error);
		} else {
			if(scriptResult.exists()) {
				resultData = parser.parseCSV(scriptResult, true);
			} else {
				throw new RemoteException("Could not find result.csv");
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
		   if (line.startsWith(".") || line.startsWith(">")|| line.startsWith("runn") || line.startsWith("\n")) // run skips output lines for do files
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
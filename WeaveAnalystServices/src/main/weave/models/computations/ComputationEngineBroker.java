package weave.models.computations;

import java.rmi.RemoteException;

import weave.beans.RResult;
import weave.servlets.DataService;
import weave.utils.SQLUtils.WhereClause.NestedColumnFilters;

import weave.utils.AWSUtils;
import weave.utils.AWSUtils.SCRIPT_TYPE;


public class ComputationEngineBroker {
	
	public  ComputationEngineBroker(){
		
	}
	
	public ScriptResult decideComputationEngine(String scriptName, int [] ids, NestedColumnFilters filters, String programPath, String tempDirPath) throws RemoteException{//TODO refactor programpath
		Object resultData = null;
		ScriptResult result = new ScriptResult();

		long startTime = 0; 
		long endTime = 0;
		long time1 = 0;
		long time2 = 0;
		
		// Start the timer for the data request
		startTime = System.currentTimeMillis();
		Object[][] recordData;
			recordData = DataService.getFilteredRows(ids, filters, null).recordData;
		if(recordData.length == 0){
			throw new RemoteException("Query produced no rows...");
		}
	if(AWSUtils.getScriptType(scriptName) == SCRIPT_TYPE.R)
	{
		// R requires the data as column data
		Object[][] columnData = AWSUtils.transpose(recordData);
		endTime = System.currentTimeMillis(); // end timer for data request
		recordData = null;
		time1 = startTime - endTime;

		// Run and time the script
		startTime = System.currentTimeMillis();
		try {
			resultData = AwsRService.runScript(scriptName, columnData);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		endTime = System.currentTimeMillis();
		time2 = startTime - endTime;

	}
	else if(AWSUtils.getScriptType(scriptName) == SCRIPT_TYPE.STATA)
	{
		endTime = System.currentTimeMillis(); // end timer for data request

		// Run and time the script
		startTime = System.currentTimeMillis();
		try {
			resultData = AwsStataService.runScript(scriptName, recordData, programPath, tempDirPath);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		endTime = System.currentTimeMillis();
		time2 = endTime - startTime;
	}

	result.data = (RResult[]) resultData;
	result.times[0] = time1;
	result.times[1] = time2;
	
	return result;
}
}

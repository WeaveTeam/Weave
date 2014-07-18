package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.apache.commons.io.FilenameUtils;
import org.json.simple.JSONObject;
import org.python.google.common.primitives.Ints;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPDouble;
import org.rosuda.REngine.REXPList;
import org.rosuda.REngine.REXPLogical;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REXPString;
import org.rosuda.REngine.REXPUnknown;
import org.rosuda.REngine.RFactor;
import org.rosuda.REngine.RList;
import org.rosuda.REngine.Rserve.RConnection;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.internal.StringMap;

import weave.beans.WeaveRecordList;
import weave.config.WeaveContextParams;
import weave.servlets.WeaveServlet;
import weave.utils.AWSUtils;
import weave.utils.ListUtils;
import weave.utils.SQLUtils.WhereClause.NestedColumnFilters;

import weave.config.AwsContextParams;
import weave.models.computations.AwsRService;
import weave.models.computations.AwsStataService;
import weave.models.computations.ScriptResult;

public class ComputationalServlet extends WeaveServlet
{	
	public ComputationalServlet() throws Exception
	{
		rService = new AwsRService();
	}
	
	private String programPath = "";
	private String tempDirPath = "";
	private String stataScriptsPath = "";
	private String rScriptsPath = "";
	private AwsRService rService = null;
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
		programPath = AwsContextParams.getInstance(config.getServletContext()).getStataPath();
		tempDirPath = FilenameUtils.concat(AwsContextParams.getInstance(config.getServletContext()).getAwsConfigPath(), "temp");
		
		stataScriptsPath = AwsContextParams.getInstance(config.getServletContext()).getStataScriptsPath();
		rScriptsPath = AwsContextParams.getInstance(config.getServletContext()).getRScriptsPath();
	}

	private static final long serialVersionUID = 1L;

	public Object runScript(String scriptName, StringMap<Object> scriptInputs, NestedColumnFilters filters) throws Exception
	{
		Object resultData = null;
		ScriptResult result = new ScriptResult();
		
 		long startTime = 0; 
 		long endTime = 0;
 		long time1 = 0;
 		long time2 = 0;
 		
 		// Start the timer for the data request
 		startTime = System.currentTimeMillis();
		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R) 
		{

			ArrayList<String> inputNames = new ArrayList<String>();
			ArrayList<Object> inputValues = new ArrayList<Object>();
			
			for(String key : scriptInputs.keySet()) {
				
				inputNames.add(key);
				
				Object value = scriptInputs.get(key);
				
				if(value instanceof String) {
					inputValues.add(value);
				} else if (value instanceof Number) {
					inputValues.add(value);
				} else if (value instanceof Boolean) {
					inputValues.add(value);;
				} else if (value instanceof StringMap<?>){
					WeaveRecordList data = null;
					data = DataService.getFilteredRows( new int[] {(Integer) ((Double) ( (StringMap<Object>) scriptInputs.get(key)).get("id")).intValue()}, filters, null);
					Object[][] columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
					inputValues.add(columnData[0]);
				} else if (value instanceof Object[]) {
					ArrayList<Integer> ids = new ArrayList<Integer>();
					Object[] values = (Object[]) value;
					for(int i = 0; i < values.length; i++)
					{	
						StringMap<Object> strMap = (StringMap<Object>) values[i];
						ids.add((Integer) ((Double) strMap.get("id")).intValue());
					}
					
					WeaveRecordList data = null;
					data = DataService.getFilteredRows(Ints.toArray(ids), filters, null);
					inputValues.add(AWSUtils.transpose(data.recordData));
				}
			}
			
	 		endTime = System.currentTimeMillis();
	 		time1 = endTime - startTime;
	 		
	 		startTime = System.currentTimeMillis();
	 		try {
				resultData = rService.runScript(FilenameUtils.concat(rScriptsPath, scriptName), (String[]) inputNames.toArray(new String[inputNames.size()]), inputValues.toArray(new Object[inputValues.size()]));
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
	 		endTime = System.currentTimeMillis();
	 		time2 = endTime - startTime;
		} else if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
		{
			// create JSON data
			StringMap<Object> inputData = new StringMap<Object>();
			
			Gson gson = new Gson();
			
			for(String key : scriptInputs.keySet()) {
				
				Object value = scriptInputs.get(key);
				
				if(value instanceof String) {
					inputData.put(key, value);
				} else if (value instanceof Number) {
					inputData.put(key, value);
				} else if (value instanceof Boolean) {
					inputData.put(key, value);
				} else if (value instanceof StringMap<?>){
					WeaveRecordList data = null;
					data = DataService.getFilteredRows( new int[] {(Integer) ((Double) ( (StringMap<Object>) scriptInputs.get(key)).get("id")).intValue()}, filters, null);
					Object[][] columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
					inputData.put(key, columnData[0]);
				} else if (value instanceof Object[]) {
					ArrayList<Integer> ids = new ArrayList<Integer>();
					Object[] values = (Object[]) value;
					for(int i = 0; i < values.length; i++)
					{	
						StringMap<Object> strMap = (StringMap<Object>) values[i];
						ids.add((Integer) ((Double) strMap.get("id")).intValue());
					}
					
					WeaveRecordList data = null;
					data = DataService.getFilteredRows(Ints.toArray(ids), filters, null);
					inputData.put(key, AWSUtils.transpose(data.recordData));
				}
			}
			
			String json = gson.toJson(inputData);
			resultData = AwsStataService.runScript(scriptName, json, programPath, tempDirPath, stataScriptsPath);
			
			json = json;
		}
		
		
		result.data = resultData;
	 	result.times[0] = time1;
	 	result.times[1] = time2;
		return result;
	}
//	public ScriptResult runScript(String scriptName, int[] ids, NestedColumnFilters filters) throws Exception
// 	{
// 		Object resultData = null;
// 		ScriptResult result = new ScriptResult();
// 
// 		long startTime = 0; 
// 		long endTime = 0;
// 		long time1 = 0;
// 		long time2 = 0;
// 		
// 		// Start the timer for the data request
// 		startTime = System.currentTimeMillis();
// 		Object[][] recordData = DataService.getFilteredRows(ids, filters, null).recordData;
// 		if(recordData.length == 0){
// 			throw new RemoteException("Query produced no rows...");
// 		}
// 		
// 	if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R)
// 	{
// 		// R requires the data as column data
// 		Object[][] columnData = (Object[][]) AWSUtils.transpose((Object) recordData);
// 		endTime = System.currentTimeMillis(); // end timer for data request
// 		recordData = null;
// 		time1 = endTime - startTime;
// 
// 		// Run and time the script
// 		startTime = System.currentTimeMillis();
//// 		try {
//// 			AwsRService rService = new AwsRService();
// 			resultData = rService.runScript(FilenameUtils.concat(rScriptsPath, scriptName), columnData);
//// 		} catch (Exception e) {
//// 			// TODO Auto-generated catch block
//// 			e.printStackTrace();
//// 		}
// 		endTime = System.currentTimeMillis();
// 		time2 = endTime - startTime;
// 
// 	}
// 	else if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA)
// 	{
// 		endTime = System.currentTimeMillis(); // end timer for data request
// 		time1 = endTime - startTime;
// 		// Run and time the script
// 		startTime = System.currentTimeMillis();
// 		resultData = AwsStataService.runScript(scriptName, recordData, programPath, tempDirPath, stataScriptsPath);
// 		endTime = System.currentTimeMillis();
// 		time2 = endTime - startTime;
// 		
// 	}
// 
// 	result.data = resultData;
// 	result.times[0] = time1;
// 	result.times[1] = time2;
// 	
// 	return result;
// 	}
}
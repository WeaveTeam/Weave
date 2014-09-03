package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

import java.util.ArrayList;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.apache.commons.io.FilenameUtils;
import org.python.google.common.primitives.Ints;

import weave.beans.WeaveRecordList;
import weave.config.AwsContextParams;
import weave.config.WeaveContextParams;
import weave.models.computations.AwsPythonService;
import weave.models.computations.AwsRService;
import weave.models.computations.AwsStataService;
import weave.models.computations.ScriptResult;
import weave.utils.AWSUtils;
import weave.utils.SQLUtils.WhereClause.NestedColumnFilters;


import com.google.gson.internal.StringMap;
import com.xhaus.jyson.JSONEncodeError;

public class ComputationalServlet extends WeaveServlet
{	
	public ComputationalServlet() throws Exception
	{
		try {
			rService = new AwsRService();
		} catch (Exception e) {
			throw new Exception("Cannot Start RService. Make sure Rserve is running.");
		}
	}
	
	private String programPath = "";
	private String tempDirPath = "";
	private String stataScriptsPath = "";
	private String rScriptsPath = "";
	private String algorithmScriptsPath = "";
	private AwsRService rService = null;
	private AwsPythonService pyService = null;
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
		programPath = AwsContextParams.getInstance(config.getServletContext()).getStataPath();
		tempDirPath = FilenameUtils.concat(AwsContextParams.getInstance(config.getServletContext()).getAwsConfigPath(), "temp");
		
		stataScriptsPath = AwsContextParams.getInstance(config.getServletContext()).getStataScriptsPath();
		rScriptsPath = AwsContextParams.getInstance(config.getServletContext()).getRScriptsPath();
		algorithmScriptsPath = AwsContextParams.getInstance(config.getServletContext()).getAlgorithmsDirectoryPath();
	}

	private static final long serialVersionUID = 1L;
	
	
	public static class InputObjects
	{
		public String type;
		public String name;
		public Object value;
	}
	
	public static class FilteredRows
	{
		int[] ids;
		NestedColumnFilters filters;
	}
	
	public Object runScript(String scriptName, InputObjects[] scriptInputs ) throws Exception, JSONEncodeError
	{
		Object resultData = null;
		ScriptResult result = new ScriptResult();
		
 		long startTime = 0; 
 		long endTime = 0;
 		long time1 = 0;
 		long time2 = 0;
 		
// 		// Start the timer for the data request
 		startTime = System.currentTimeMillis();
		StringMap<Object> input = new StringMap<Object>();
		for(int i = 0; i < scriptInputs.length; i++)//for every input 
		{
			//get its type
			//process its value accordingly
			String type = scriptInputs[i].type;
			if (type.equalsIgnoreCase("FilteredRows"))
			{
				FilteredRows fRows = new FilteredRows();
				ArrayList<Double> idValues = (ArrayList<Double>)scriptInputs[i].value;
				int[] ids = new int [idValues.size()];
				for(int t = 0; t < idValues.size(); t++ )
				{
					Double id = idValues.get(t);
					ids[t] = id.intValue();
				}
				 fRows.ids = ids;
			
				//fRows = (FilteredRows) scriptInputs[i].value;
				WeaveRecordList data = DataService.getFilteredRows(fRows.ids, fRows.filters, null);
				Object[][] columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
				input.put(scriptInputs[i].name, columnData);
				
				//TODO handling filters still has to be done
			}
			
			else 
			{
				input.put(scriptInputs[i].name, scriptInputs[i].value);
			}
		}
		
		endTime = System.currentTimeMillis();
		
		time1 = endTime - startTime;
		
		startTime = System.currentTimeMillis();
		
		//R
		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R) 
		{
			try {
				resultData = rService.runScript(FilenameUtils.concat(algorithmScriptsPath, scriptName), input);
			} catch(Exception e) 
			{
				
			}
		//Python	
		} else if (AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.PYTHON)
		{
			pyService = new AwsPythonService();
			resultData = pyService.runScript(FilenameUtils.concat(algorithmScriptsPath, scriptName), input);

		}
		endTime = System.currentTimeMillis();
		
 		time2 = endTime - startTime;
		result.data = resultData;
	 	result.times[0] = time1;
	 	result.times[1] = time2;
		
		return resultData;
	}
	

	//public Object runScript(String scriptName, StringMap<Object> scriptInputs, NestedColumnFilters filters) throws Exception
//	{
//		Object resultData = null;
//		ScriptResult result = new ScriptResult();
//		
// 		long startTime = 0; 
// 		long endTime = 0;
// 		long time1 = 0;
// 		long time2 = 0;
// 		
// 		// Start the timer for the data request
// 		startTime = System.currentTimeMillis();
//
// 		StringMap<Object> input = new StringMap<Object>();
// 		ArrayList<Integer> colIds = new ArrayList<Integer>();
// 		ArrayList<String> colNames = new ArrayList<String>();
// 		
//		for(String key : scriptInputs.keySet()) {
//			Object value = scriptInputs.get(key);
//			
//			if(value instanceof String) {
//				input.put(key, value);
//			} else if (value instanceof Number) {
//				input.put(key, value);
//			} else if (value instanceof Boolean) {
//				input.put(key, value);
//			} else if (value instanceof StringMap<?>){
//				// collect the names and id for single query below
//			//	colNames.add(key);
//				colIds.add((Integer) ((Double) ( (StringMap<Object>) scriptInputs.get(key)).get("id")).intValue());
//			} else if (value instanceof ArrayList) {
//				
//				ArrayList<Integer> ids = new ArrayList<Integer>();
//				ArrayList<Object> values = (ArrayList<Object>) value;
//				for(int i = 0; i < values.size(); i++)
//				{	
//					StringMap<Object> strMap = (StringMap<Object>) values.get(i);
//					ids.add((Integer) ((Double) strMap.get("id")).intValue());
//				}
//				
//				Object[][] data = (Object[][]) AWSUtils.transpose(DataService.getFilteredRows(Ints.toArray(ids), filters, null).recordData);
//				input.put(key, data);
//			}
//		}
//		
//		if(colIds.size() > 0) {
//			// use the collection of ids from above to retrieve the data.
//			WeaveRecordList data = DataService.getFilteredRows(Ints.toArray(colIds), filters, null);
//			
//			// transpose the data to obtain the column form
//			Object[][] columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
//			
//			input.put("data", columnData);
//			//TODO use a flag to distinguish between use of columns vs use of data matrix
//			// assign each columns to proper column name
////			for(int i =  0; i < colNames.size(); i++) {
////				input.put(colNames.get(i), columnData[i]);
////			}
//		}
//		
//		endTime = System.currentTimeMillis();
//		
//		time1 = endTime - startTime;
//		
//		startTime = System.currentTimeMillis();
//		
//		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R) 
//		{
//			try {
//				resultData = rService.runScript(FilenameUtils.concat(algorithmScriptsPath, scriptName), input);
//			} catch(Exception e) 
//			{
//				
//			}
//		} else {
//			resultData = AwsStataService.runScript(scriptName, input,
//					 programPath, tempDirPath, stataScriptsPath);
//
//		}
//		endTime = System.currentTimeMillis();
//		
// 		time2 = endTime - startTime;
//		result.data = resultData;
//	 	result.times[0] = time1;
//	 	result.times[1] = time2;
//		return result;
//	}
}
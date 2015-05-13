package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

import java.rmi.RemoteException;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.apache.commons.io.FilenameUtils;

import weave.beans.WeaveRecordList;
import weave.config.AwsContextParams;
import weave.config.WeaveContextParams;
import weave.models.computations.AwsRService;
import weave.models.computations.AwsStataService;
import weave.utils.AWSUtils;
import weave.utils.SQLUtils.WhereClause.NestedColumnFilters;

import com.google.gson.internal.StringMap;
/**
 * @author Franck Kamayou
 * @author Shweta Purushe
 *
 */
public class ComputationalServlet extends WeaveServlet
{	
	public ComputationalServlet() throws Exception
	{
//		try {
//			rService = new AwsRService();
//		} catch (Exception e) {
//			throw new Exception("Cannot Start RService. Make sure Rserve is running.");
//		}
	}
	
	private String programPath = "";
	private String tempDirPath = "";
	private String stataScriptsPath = "";
	private String rScriptsPath = "";
	private AwsRService rService = null;
	private StringMap<Object> scriptInputs = new StringMap<Object>();
	
	public static String filteredRows = "FILTEREDROWS";
	public static String dataMatrix = "DATACOLUMNMATRIX";
	public static String reidentification = "REIDENTIFICATION";

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

	/**
	 * 
	 * @param scriptInputs the columns to be sent as parameters to the script
	 * @param filters filters that help filter the column data
	 * @param remapValues replacement values for original data 
	 * @return
	 * @throws Exception
	 */
	public int getDataFromServer(InputObjects[] inputObjects, ReMapObjects[] remapValues) throws Exception
	{
		
		WeaveRecordList data = new WeaveRecordList();
		Object[][]columnData = null;
		RowsObject rows = new RowsObject();
 		int numRows = 0;
		//getting data
 		for(int i = 0; i < inputObjects.length; i++)//for every input 
		{
			//get its type
			//process its value accordingly
			String type = inputObjects[i].type;
			if(type.equalsIgnoreCase(filteredRows) || type.equalsIgnoreCase(dataMatrix))
			{
				rows = (RowsObject)cast(inputObjects[i].value, RowsObject.class);
				data = DataService.getFilteredRows(rows.columnIds, rows.filters, null);
				//TODO handling filters still has to be done
				numRows = data.recordData.length;
				//transposition
				columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
				
				if(remapValues != null)//only if remapping needs to be done
				{
					columnData = remapScriptInputData(rows.namesToAssign, columnData, remapValues);//this function call will return the remapped data
				}

				// if individual columns --> assign each columns to proper column name
				if (type.equalsIgnoreCase(filteredRows))
				{
					// Once all the columns have been downloaded, we can 
					// run the remapping of the values
					
					for(int x =  0; x < rows.namesToAssign.length;  x++) {
						scriptInputs.put(rows.namesToAssign[x], columnData[x]);
					}
					
				}
				
				//if multi columns --> assign each columns to proper column name
				// under the same hashmap. the hashmap will then be converted into
				// a data frame or table
				else if(type.equalsIgnoreCase(dataMatrix)){
					StringMap<Object> dataMatrixMap = new StringMap<Object>();
					for(int x =  0; x < rows.namesToAssign.length;  x++) {
						dataMatrixMap.put(rows.namesToAssign[x], columnData[x]);
					}
					scriptInputs.put(inputObjects[i].name, dataMatrixMap);
				}
			} //TODO handle remaining types of input objects
			
			//handling re-identification prevention in aggregation scripts
			else if(type.equalsIgnoreCase(reidentification))
			{
				ReIdentificationObject reId = (ReIdentificationObject)cast(inputObjects[i].value, ReIdentificationObject.class);
				scriptInputs.put("idPrevention", reId.idPrevention);
				scriptInputs.put("threshold",reId.threshold );
			}
			else {
				scriptInputs.put(inputObjects[i].name, inputObjects[i].value);
			}
		}
 		
		return numRows;
	}
	
	public Object runScript(String scriptName) throws Exception
	{
		Object resultData = null;
		
		if(AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.R) 
		{
			try {
				rService = new AwsRService();
				resultData = rService.runScript(FilenameUtils.concat(rScriptsPath, scriptName), scriptInputs);
			} catch(Exception e) 
			{
				scriptInputs.clear();
				throw (e);
			}
		} 
		else if (AWSUtils.getScriptType(scriptName) == AWSUtils.SCRIPT_TYPE.STATA) {
			resultData = AwsStataService.runScript(scriptName, scriptInputs,
					 programPath, tempDirPath, stataScriptsPath);

		} else {
			throw new RemoteException("Unrecognized script type.");
		}
		//clearing scriptInputs before every successive run
		scriptInputs.clear();
		return resultData;
	}
	
	@SuppressWarnings("serial")
	public static class MapKeyTypeToKeysAndColumns extends HashMap<String, KeysAndColumns>
	{
	}
	public static class KeysAndColumns
	{
		public String[] keys;
		public Map<String, Object[]> columns;
	}
	
	public Object runScriptWithInputs(String scriptName, Map<String, Object> simpleInputs, MapKeyTypeToKeysAndColumns columnData) throws Exception
	{
		Object resultData = null;
		
		for(String key : simpleInputs.keySet()) {
			scriptInputs.put(key, simpleInputs.get(key));
		}

		if (columnData.size() > 1)
			throw new RemoteException("Columns with different keyTypes are not supported yet.");
		for (String keyType : columnData.keySet())
		{
			KeysAndColumns keysAndColumns = columnData.get(keyType);
			for(String key : keysAndColumns.columns.keySet())
			{
				scriptInputs.put(key, keysAndColumns.columns.get(key));
			}
		}
		
		resultData = runScript(scriptName);
		
		return resultData;
		
	}
	
	//*******************************REMAPPING OF REQUIRED COLUMNS*******************************
	/**
	 * @param remapValues objects representing the values to be used for overwriting
	 * @param filtered rows needed for matching ids of columns that need to be remapped
	 * @param originalData the original data matrix that needs to be overwritten
	 */
	private Object[][] remapScriptInputData(String[] columnNames, Object[][] columns, ReMapObjects[] remapObjects) throws Exception
	{
		if(remapObjects.length > 0 ){
			for(int i = 0; i < remapObjects.length; i++)//for each of the remap columns
			{
				ReMapObjects remapObject = null;//use this object from the collection of the remapObjects for the remapping
				//check the type of the original data to be remapped
				//first column to remap
				remapObject = remapObjects[i];
				String columnNameToMatch = remapObject.columnName;
				// find the matching column name
				for(int j = 0; j < columnNames.length; j++)
				{
					if(columnNameToMatch.equalsIgnoreCase(columnNames[j]))
					{
						// once we have the column to remap, use the remap values to remap the column
						for(int k = 0; k < columns[j].length; k++)
						{
							Object value = columns[j][k];
							for(int l = 0; l < remapObject.originalValues.length; l++)
							{
								if(value == null)
									continue;
								if(value.equals(cast(remapObject.originalValues[l], value.getClass())))
								{
									columns[j][k] = cast(remapObject.reMappedValues[l], value.getClass());
								}
							}
						}
					}
				}
			}
		}
		
		return columns;
		//***************************end of REMAPPING********************************************
	}
	
	
	/**
	 * type : type of input object Example filtered columns, single column, booleans etc
	 * name: parameter needed for handling result on client end
	 * value : value entered on the client side
	 */
	public static class InputObjects
	{
		public String type;
		public String name;
		public Object value;
	}
	
	
	/**
	 * columnIds : the ids of the column data to be retrieved as script input
	 * columnTitles : the titles of the same columns to be used to assign in R/STATA
	 * filters : any filters that will be applied on the data before executing script
	 */
	public static class RowsObject
	{
		public int[] columnIds;
		public String[] namesToAssign;
		public NestedColumnFilters filters;
	}	
	
	/**
	 * columnsToRemapId : id of the column whose values are going to be remapped
	 * originalValue the original data
	 * reMappedValue : the value that will substitute the original value before script execution
	 */
	public static class ReMapObjects
	{
		 public String columnName;
		 public  Object[] originalValues;
		 public Object[] reMappedValues;
	}
	
	/**
	 * this object represents the parameters needed to prevent the re-identification during aggregation 
	 * */
	public static class ReIdentificationObject
	{
		public int threshold;
		public boolean idPrevention;
	}
}
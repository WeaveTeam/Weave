package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

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
	public boolean getDataFromServer(InputObjects[] inputObjects, ReMapObjects[] remapValues) throws Exception
	{
		
		WeaveRecordList data = new WeaveRecordList();
		Object[][]columnData = null;
		RowsObject rows = new RowsObject();
 		
		//getting data
 		for(int i = 0; i < inputObjects.length; i++)//for every input 
		{
			//get its type
			//process its value accordingly
			String type = inputObjects[i].type;
			
			rows = (RowsObject)cast(inputObjects[i].value, RowsObject.class);
			
			data = DataService.getFilteredRows(rows.columnIds, rows.filters, null);
			//TODO handling filters still has to be done
			
			//REMAPPING
			if(remapValues != null)//only if remapping needs to be done
			{
				data = remappingScriptInputData(remapValues, rows, data);//this function call will return the remapped data
			}
			
			//transposition
			columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
			
			// if individual columns --> assign each columns to proper column name
			if (type.equalsIgnoreCase(filteredRows))
			{
				for(int x =  0; x < rows.namesToAssign.length;  x++) {
					scriptInputs.put(rows.namesToAssign[x], columnData[x]);
				}
			}
			//if single datamatrix to be used ascribe only one name 'columndata'
			else if(type.equalsIgnoreCase(dataMatrix)){
				
				scriptInputs.put("columndata", columnData);
			}
			//TODO handle remaining types of input objects
			else 
			{
			}
			
		}
 		
		return true;
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
				throw (e);
			}
		} else {
			resultData = AwsStataService.runScript(scriptName, scriptInputs,
					 programPath, tempDirPath, stataScriptsPath);

		}
		//clearing scriptInputs before every successive run
		scriptInputs.clear();
		return resultData;
	}
	
	//*******************************REMAPPING OF REQUIRED COLUMNS*******************************
	/**
	 * @param remapValues objects representing the values to be used for overwriting
	 * @param filtered rows needed for matching ids of columns that need to be remapped
	 * @param originalData the original data matrix that needs to be overwritten
	 */
	private WeaveRecordList remappingScriptInputData(ReMapObjects[] remapValues, RowsObject fRows, WeaveRecordList originalData) throws Exception
	{
		if(remapValues.length > 0 ){
			for(int c = 0; c < remapValues.length; c++)//for each of the remap columns
			{
				int index = 0;
				ReMapObjects remapObject = null;//use this object from the collection of the remapObjects for the remapping
				//check the type of the original data to be remapped
				Object column_to_remap = null;//resetting it every time
				Object castedOriginalValue = null;
				Object castedRemappedValue = null;
				column_to_remap = originalData.recordData[0][index];//TODO remove hardcode this has to be done only once
				
				//we need this to know which column to handle for remapping
				for(int y = 0; y < remapValues.length; y++)
				{
					ReMapObjects singleObject = remapValues[y];
					for(int t=0; t< fRows.columnIds.length; t++)
					{
						if(singleObject.columnsToRemapId == fRows.columnIds[t])
						{
							index = t;//use index to loop through data later while remapping
							remapObject = remapValues[y];
						}
					}
				}
				
				try{
					castedOriginalValue = cast(remapObject.originalValue, column_to_remap.getClass());
					//need to cast because client side sometimes sends integers as strings
					castedRemappedValue = cast(remapObject.reMappedValue, column_to_remap.getClass());
				}
				catch(Exception e){
					throw e;
				}
				
				for(int x = 0; x < originalData.recordData.length; x++)
				{
					if(originalData.recordData[x][index] == null){
						continue;
					}
					
					else{//for non-null values
						
						if(originalData.recordData[x][index].equals(castedOriginalValue))
						{
							//System.out.println(x);
							originalData.recordData[x][index] = castedRemappedValue;
							
						}
						
					}
					
				}
				
			}//loop ends for one remapObject
		}
			
		//***************************end of REMAPPING********************************************
			
		return originalData;
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
		 public int columnsToRemapId;
		 public  Object originalValue;
		 public Object reMappedValue;
	}
}
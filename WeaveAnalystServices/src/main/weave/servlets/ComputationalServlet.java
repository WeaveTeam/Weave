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
import weave.models.computations.AwsRService;
import weave.models.computations.AwsStataService;
import weave.models.computations.ScriptResult;
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
		FilteredRows fRows = new FilteredRows();
 		
		//getting data
 		for(int i = 0; i < inputObjects.length; i++)//for every input 
		{
			//get its type
			//process its value accordingly
			String type = inputObjects[i].type;
			if (type.equalsIgnoreCase(filteredRows))
			{
				fRows = (FilteredRows)cast(inputObjects[i].value, FilteredRows.class);
				//TODO handling filters still has to be done
	
				data = DataService.getFilteredRows(fRows.columnIds, fRows.filters, null);
				columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
				
				// assign each columns to proper column name
				for(int x =  0; x < inputObjects[i].names.length;  x++) {
					scriptInputs.put(inputObjects[i].names[x], columnData[x]);
				}
				
				
			}
			else if(type.equalsIgnoreCase(dataMatrix)){
				DataColumnMatrix dm = (DataColumnMatrix)cast(inputObjects[i].value, DataColumnMatrix.class);
	
				data = DataService.getFilteredRows(dm.columnIds, null, null);
				columnData = (Object[][]) AWSUtils.transpose((Object)data.recordData);
				
				scriptInputs.put(inputObjects[i].names[i], columnData);
			}
			//TODO handle remaining types of input objects
			else 
			{
				scriptInputs.put(inputObjects[i].names[i], inputObjects[i].value);
			}
			
		}
 		//*******************************REMAPPING OF REQUIRED COLUMNS*******************************
		if(remapValues != null)//only if remapping needs to be done
		{
			if(remapValues.length > 0 ){
				for(int c = 0; c < remapValues.length; c++)//for each of the remap columns
				{
					int index = 0;
					ReMapObjects remapObject = null;//use this object from the collection of the remapObjects for the remapping
					//we need this to know which column to handle for remapping
					for(int y = 0; y < remapValues.length; y++)
					{
						ReMapObjects singleObject = remapValues[y];
						for(int t=0; t< fRows.columnIds.length; t++)
						{
							if(singleObject.columnsToRemapId == fRows.columnIds[t])
							{
								index = t;//use index to loop through data
								remapObject = remapValues[y];
							}
						}
					}
					
					//check the type of the original data to be remapped
					Object column_to_remap = null;//resetting it every time
					Object castedOriginalValue = null;
					column_to_remap = data.recordData[0][index];//TODO remove hardcode this has to be done only once
					try{
						castedOriginalValue = cast(remapObject.originalValue, column_to_remap.getClass());
					}
					catch(Exception e){
						throw e;
					}
					
					for(int x = 0; x < data.recordData.length; x++)
					{
						
						if(data.recordData[x][index].equals(castedOriginalValue))
						{
							data.recordData[x][index] = remapObject.reMappedValue;
							
						}
						
					}
				}//loop ends for one remapObject
			}
			
		}//***************************end of REMAPPING********************************************
			
		
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
	
	
	/**
	 * type : type of input object Example filtered columns, single column, booleans etc
	 * name: parameter names to be assigned in computation engine
	 * value : value entered on the client side
	 */
	public static class InputObjects
	{
		public String type;
		public String[] names;
		public Object value;
	}
	
	
	/**
	 * columnIds : the ids of the column data to be retrieved as script input
	 * columnTitles : the titles of the same columns to be used to assign in R/STATA
	 * filters : any filters that will be applied on the data before executing script
	 */
	public static class FilteredRows
	{
		public int[] columnIds;
		public NestedColumnFilters filters;
	}	
	
	public static class DataColumnMatrix
	{
		public int [] columnIds;
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
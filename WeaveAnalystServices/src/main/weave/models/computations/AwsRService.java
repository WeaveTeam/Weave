package weave.models.computations;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Vector;

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
import org.rosuda.REngine.Rserve.RserveException;

import weave.utils.ListUtils;

import com.google.gson.internal.StringMap;

public class AwsRService implements IScriptEngine
{
	
	public AwsRService() throws Exception
	{
		try{
			rConnection = new RConnection();
		} catch (Exception e) {
			throw new Exception("Cannot get connection to Rserve. Make sure Rserve is running.");
		}
	}
	
	public void destroy()
	{
		rConnection.close();
	}
	private RConnection rConnection = null;
	
	// this functions intends to run a script with filtered.
	// essentially this function should eventually be our main run script function.
	// in the request object, there will be: the script name
	// and the columns, along with their filters.
	// TODO not completed
	public Object runScript(String scriptAbsPath, StringMap<Object> scriptInputs) throws Exception
	{

		if(rConnection != null) {
			rConnection.assign("scriptPath", scriptAbsPath);
			
			for(String key : scriptInputs.keySet()) {
				rConnection.assign(key, getREXP(scriptInputs.get(key)));
			}
			
			Object results = null;
			Vector<String> names = null;
			String [] columnNames;
			String script = "scriptFromFile <- source(scriptPath)\n" +
					"scriptFromFile$value"; 
			
			try
			{
				REXP evalValue = rConnection.eval("try({ options(warn=1) \n" + script + "},silent=TRUE)");
				names = evalValue.asList().names;
				columnNames = new String[names.size()];
				names.toArray(columnNames);
				results = rexp2javaObj(evalValue);
				// clear R Objects
				rConnection.eval("rm(list=ls())");
			}
			catch (Exception e)	{
				e.printStackTrace();
				// System.out.println("printing error");
				// System.out.println(e.getMessage());
				throw new RemoteException("Unable to run script", e);
			}
			
			results = convertToRowResults(results, columnNames);
			return results;
		} else {
			return new Object();
		}
	}

	/**
	 * This will wrap an object in an REXP object.
	 * @param object
	 * @return
	 * @throws RemoteException if the object type is unsupported
	 */
	private static REXP getREXP(Object object) throws RemoteException
	{
		/*
		 * <p><table>
		 *  <tr><td> null	<td> REXPNull
		 *  <tr><td> boolean, Boolean, boolean[], Boolean[]	<td> REXPLogical
		 *  <tr><td> int, Integer, int[], Integer[]	<td> REXPInteger
		 *  <tr><td> double, Double, double[], double[][], Double[]	<td> REXPDouble
		 *  <tr><td> String, String[]	<td> REXPString
		 *  <tr><td> byte[]	<td> REXPRaw
		 *  <tr><td> Enum	<td> REXPString
		 *  <tr><td> Object[], List, Map	<td> REXPGenericVector
		 *  <tr><td> RObject, java bean (experimental)	<td> REXPGenericVector
		 *  <tr><td> ROpaque (experimental)	<td> only function arguments (REXPReference?)
		 *  </table>
		 */
		
		// if it's an array...
		if (object instanceof Object[])
		{
			Object[] array = (Object[])object;
			if (array.length == 0)
			{
				return new REXPList(new RList());
			}
			else if (array[0] instanceof String)
			{
				String[] strings = ListUtils.copyStringArray(array, new String[array.length]);
				return new REXPString(strings);
			}
			else if (array[0] instanceof Number)
			{
				double[] doubles = ListUtils.copyDoubleArray(array, new double[array.length]);
				return new REXPDouble(doubles);
			}
			else if (array[0] instanceof Object[]) // 2-d matrix
			{
				// handle 2-d matrix
				RList rList = new RList();
				for (Object item : array)
					rList.add(getREXP(item));

				try {
					return REXP.createDataFrame(rList);
				} catch (REXPMismatchException e) {
					throw new RemoteException("Failed to Create Dataframe",e);
				}
			}
			else
				throw new RemoteException("Unsupported value type");
		}
		
		// handle non-array by wrapping it in an array
		return getREXP(new Object[]{object});
	}
	
	/*
	 * Taken from rJava Opensource code and 
	 * added support for Rlist
	 * added support for RFactor(REngine)
	 */
	private static Object rexp2javaObj(REXP rexp) throws REXPMismatchException {
		if(rexp == null || rexp.isNull() || rexp instanceof REXPUnknown) {
			return null;
		}
		if(rexp.isVector()) {
			int len = rexp.length();
			if(rexp.isString()) {
				return len == 1 ? rexp.asString() : rexp.asStrings();
			}
			if(rexp.isFactor()){
				return rexp.asFactor();
			}
			if(rexp.isInteger()) {
				return len == 1 ? rexp.asInteger() : rexp.asIntegers();
			}
			if(rexp.isNumeric()) {
				int[] dim = rexp.dim();
				return (dim != null && dim.length == 2) ? rexp.asDoubleMatrix() :
					(len == 1) ? rexp.asDouble() : rexp.asDoubles();
			}
			if(rexp.isLogical()) {
				boolean[] bools = ((REXPLogical)rexp).isTRUE();
				return len == 1 ? bools[0] : bools;
			}
			if(rexp.isRaw()) {
				return rexp.asBytes();
			}
			if(rexp.isList()) {
				RList rList = rexp.asList();
				Object[] listOfREXP = rList.toArray();
				//convert object in List as Java Objects
				// eg: REXPDouble as Double or Doubles
				for(int i = 0; i < listOfREXP.length; i++){
					REXP obj = (REXP)listOfREXP[i];
					Object javaObj =  rexp2javaObj(obj);
					if (javaObj instanceof RFactor)
					{
						RFactor factorjavaObj = (RFactor)javaObj;
						String[] levels = factorjavaObj.asStrings();
						listOfREXP[i] = levels;
					}
					else
					{
						listOfREXP[i] =  javaObj;
					}
				}
				return listOfREXP;
			}
		}
		else
		{
			//rlist
			return rexp.toDebugString();
		}
		return rexp;
	}
	
	private Object convertToRowResults(Object columnResult, String[] columnNames) throws Exception
	{
		
		Object[] columns;

		if (columnResult instanceof Object[])
		{
			columns = (Object[])columnResult;
		}
		else
		{
			throw new RemoteException(String.format("Script result is not an Array as expected: \"%s\"", columnResult));
		}

		Object[][] final2DArray;//collecting the result as a two dimensional arrray 

		//getting the rowCounter variable 
			int rowCounter = 0;
			/*picking up first one to determine its length, 
			all objects are different kinds of arrays that have the same length
			hence it is necessary to check the type of the array*/
			Object currentRow = columns[0];
			if(currentRow instanceof int[])
			{
				rowCounter = ((int[]) currentRow).length;

			}
			else if (currentRow instanceof Integer[])
			{
				rowCounter = ((Integer[]) currentRow).length;

			}
			else if(currentRow instanceof Double[])
			{
				rowCounter = ((Double[]) currentRow).length;
			}
			else if(currentRow instanceof double[])
			{
				rowCounter = ((double[]) currentRow).length;
			}
			else if(currentRow instanceof RFactor)
			{
				rowCounter = ((RFactor[]) currentRow).length;
			}
			else if(currentRow instanceof String[])
			{
				rowCounter = ((String[]) currentRow).length;
			}

			//handling single row, that is the currentColumn has only one record
			else if (currentRow instanceof Double)
			{
				rowCounter = 1;
			}

			else if(currentRow instanceof Integer)
			{
				rowCounter = 1;
			}

			else if(currentRow instanceof String)
			{
				rowCounter = 1; 
			}
			int columnHeadingsCount = 1;

			rowCounter = rowCounter + columnHeadingsCount;//we add an additional row for column Headings

			final2DArray = new Object[rowCounter][columns.length];

			//we need to push the first entry as column names to generate this structure
			/*[
			["k","x","y","z"]
			["k1",1,2,3]
			["k2",3,4,6]
			["k3",2,4,56]
			] */

			final2DArray[0] = columnNames;//first entry is column names

			for( int j = 1; j < rowCounter; j++)
			{
				ArrayList<Object> tempList = new ArrayList<Object>();//one added for every column in 'columns'
				for(int f =0; f < columns.length; f++){
					//pick up one column
					Object currentCol = columns[f];
					//check its type
					if(currentCol instanceof int[])
					{
						//the second index in the new list should coincide with the first index of the columns from which values are being picked
						tempList.add(f, ((int[])currentCol)[j-1]);
					}
					else if (currentCol instanceof Integer[])
					{
						tempList.add(f,((Integer[])currentCol)[j-1]);
					}
					else if(currentCol instanceof double[])
					{
						tempList.add(f,((double[])currentCol)[j-1]);
					}
					else if(currentCol instanceof RFactor)
					{
						tempList.add(f,((RFactor[])currentCol)[j-1]);
					}
					else if(currentCol instanceof String[])
					{
						tempList.add(f,((String[])currentCol)[j-1]);
					}
					//handling single record
					else if(currentCol instanceof Double)
					{
						tempList.add(f, (Double)currentCol);
					}
					else if(currentCol instanceof String)
					{
						tempList.add(f, (String)currentCol);
					}
					else if(currentCol instanceof Integer)
					{
						tempList.add(f, (Integer)currentCol);
					}

				}
				Object[] tempArray = new Object[columns.length];
				tempList.toArray(tempArray);
				final2DArray[j] = tempArray;//after the first entry (column Names)
			}

			return final2DArray;
	}
	
	private static void assignNamesToVector(RConnection rConnection,String[] inputNames,Object[] inputValues) throws RserveException, RemoteException
	{
		for (int i = 0; i < inputNames.length; i++)
		{
			String name = inputNames[i];
			rConnection.assign(name, getREXP(inputValues[i]));
		}
	}
}

package weave.models.computations;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Vector;

import javax.script.ScriptException;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.RFactor;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;

import weave.beans.RResult;
import weave.servlets.RServiceUsingRserve;

public class AwsRService extends RServiceUsingRserve implements IScriptEngine
{
	private static final long serialVersionUID = 1L;
	
	
	
	public AwsRService(){
		
	}
	
	public void init(ServletConfig config) throws ServletException {
//		awsConfigPath = WeaveContextParams.getInstance(
//				config.getServletContext()).getConfigPath();
//		awsConfigPath = awsConfigPath + "/../aws-config/";
	}

	
	// this functions intends to run a script with filtered.
	// essentially this function should eventually be our main run script function.
	// in the request object, there will be: the script name
	// and the columns, along with their filters.
	// TODO not completed
	public static Object runScript(String scriptAbsPath, Object[][] dataSet) throws Exception
	{

		Object[] inputValues = {scriptAbsPath, dataSet};
		String[] inputNames = {"scriptAbsolutePath", "dataset"};

		String script = "scriptFromFile <- source(scriptAbsolutePath)\n" +
					         "scriptFromFile$value(dataset)"; 

		String[] outputNames = {};

		return runAWSScript(null, inputNames, inputValues, outputNames, script, "", false, false);
	}

	private static RResult[] runAWSScript( String docrootPath, String[] inputNames, Object[] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings) throws Exception
	{		
		RConnection rConnection = RServiceUsingRserve.getRConnection();

		RResult[] results = null;
		Vector<RResult> resultVector = new Vector<RResult>();
		try
		{
			// ASSIGNS inputNames to respective Vector in R "like x<-c(1,2,3,4)"			
			RServiceUsingRserve.assignNamesToVector(rConnection,inputNames,inputValues);

			evaluateWithTypeChecking( rConnection, script, resultVector, showIntermediateResults, showWarnings);

			if (plotScript != ""){// R Script to EVALUATE plotScript
				String plotEvalValue = RServiceUsingRserve.plotEvalScript(rConnection,docrootPath, plotScript, showWarnings);
				resultVector.add(new RResult("Plot Results", plotEvalValue));
			}
			for (int i = 0; i < outputNames.length; i++){// R Script to EVALUATE output Script
				String name = outputNames[i];						
				REXP evalValue = evalScript( rConnection, name, showWarnings);	
				resultVector.add(new RResult(name, RServiceUsingRserve.rexp2javaObj(evalValue)));					
			}
			// clear R objects
			evalScript( rConnection, "rm(list=ls())", false);

		}
		catch (Exception e)	{
			e.printStackTrace();
			System.out.println("printing error");
			System.out.println(e.getMessage());
			throw new RemoteException("Unable to run script", e);
		}
		finally
		{
			results = new RResult[resultVector.size()];
			resultVector.toArray(results);
			rConnection.close();
		}
		return results;
	}

	private static REXP evalScript(RConnection rConnection, String script, boolean showWarnings) throws REXPMismatchException,RserveException
	{

		REXP evalValue = null;

		if (showWarnings)			
			evalValue =  rConnection.eval("try({ options(warn=2) \n" + script + "},silent=TRUE)");
		else
			evalValue =  rConnection.eval("try({ options(warn=1) \n" + script + "},silent=TRUE)");

	return evalValue;
	}

	private static Vector<RResult> evaluateWithTypeChecking(RConnection rConnection, String script, Vector<RResult> newResultVector, boolean showIntermediateResults, boolean showWarnings ) throws ScriptException, RserveException, REXPMismatchException 
	{
		REXP evalValue= evalScript(rConnection, script, showWarnings);
		Object resultArray = RServiceUsingRserve.rexp2javaObj(evalValue);
		Object[] columns;
		if (resultArray instanceof Object[])
		{
			columns = (Object[])resultArray;
		}
		else
		{
			throw new ScriptException(String.format("Script result is not an Array as expected: \"%s\"", resultArray));
		}

		Object[][] final2DArray;//collecting the result as a two dimensional arrray 

		Vector<String> names = evalValue.asList().names;

	//try{
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

			String [] namesArray = new String[names.size()];
			names.toArray(namesArray);
			final2DArray[0] = namesArray;//first entry is column names

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

			System.out.print(final2DArray);
			newResultVector.add(new RResult("endResult", final2DArray));
			//newResultVector.add(new RResult("timeLogString", timeLogString));


			return newResultVector;

	//	}
	//	catch (Exception e){
			//e.printStackTrace();
	//	}

//do the rest to generate a single continuous string representation of the result 
		//	String finalresultString = "";
//		String namescheck = Strings.join(",", names);
//		finalresultString = finalresultString.concat(namescheck);
//		finalresultString = finalresultString.concat("\n");
//
//		
//
//		int numberOfRows = 0;
//		
//		Vector<String[]> columnsInStrings = new Vector<String[]>();
//		
//		String[] tempStringArray = new String[0];
//		
//		try
//		{
//			for (int r= 0; r < columns.length; r++)					
//			{
//				Object currentColumn = columns[r];
//						
//						if(currentColumn instanceof int[])
//						{
//							 int[] columnAsIntArray = (int[])currentColumn;
//							 tempStringArray = new String[columnAsIntArray.length] ; 
//							 for(int g = 0; g < columnAsIntArray.length; g++)
//							 {
//								 tempStringArray[g] = ((Integer)columnAsIntArray[g]).toString();
//							 }
//						}
//						
//						else if (currentColumn instanceof Integer[])
//						{
//							 Integer[] columnAsIntegerArray = (Integer[])currentColumn;
//							 tempStringArray = new String[columnAsIntegerArray.length] ;  
//							 for(int g = 0; g < columnAsIntegerArray.length; g++)
//							 {
//								 tempStringArray[g] = columnAsIntegerArray[g].toString();
//							 }
//						}
//						
//						else if(currentColumn instanceof double[])
//						{
//							double[] columnAsDoubleArray = (double[])currentColumn;
//							 tempStringArray = new String[columnAsDoubleArray.length] ;  
//							 for(int g = 0; g < columnAsDoubleArray.length; g++)
//							 {
//								 tempStringArray[g] = ((Double)columnAsDoubleArray[g]).toString();
//							 }
//						}
//						else if(currentColumn instanceof RFactor)
//						{
//							tempStringArray = ((RFactor)currentColumn).levels();
//						}
//						else if(currentColumn instanceof String[]){
//							 int lent = ((Object[]) currentColumn).length;
//							 //String[] columnAsStringArray = currentColumn;
//							 tempStringArray = new String[lent];  
//							 for(int g = 0; g < lent; g++)
//							 {
//								 tempStringArray[g] = ((Object[]) currentColumn)[g].toString();
//							 }
//						/*	String[] temp = (String[])
//							int arrsize = ((String[])currentColumn).length;
//							tempStringArray = new String[arrsize];
//							tempStringArray = (String[])currentColumn;*/
//						}
//						
//						columnsInStrings.add(tempStringArray);
//						numberOfRows = tempStringArray.length;
//			}
//			
//			
//			//if(rowresult.charAt(rowresult.length()-1) == ',')
//				//rowresult.substring(0, rowresult.length()-1);
//		}
//		catch (Exception e) {
//			e.printStackTrace();
//		}
//		
//		for(int currentRow =0; currentRow <numberOfRows; currentRow ++)
//		{
//			for(int currentColumn= 0; currentColumn < columnsInStrings.size(); currentColumn++)
//			{
//				finalresultString += columnsInStrings.get(currentColumn)[currentRow] + ',';
//			}
//			
//			/*remove last comma and  new line*/
//			finalresultString = finalresultString.substring(0, finalresultString.length()-1);
//			finalresultString += '\n';
//		}

		//newResultVector.add(new RResult("endResult", finalresultString));
		//newResultVector.add(new RResult("timeLogString", timeLogString));

	}
}

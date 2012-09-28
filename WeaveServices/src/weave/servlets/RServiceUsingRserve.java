/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.servlets;

import java.io.File;
import java.rmi.RemoteException;
import java.util.UUID;
import java.util.Vector;

import javax.script.ScriptException;

import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPDouble;
import org.rosuda.REngine.REXPList;
import org.rosuda.REngine.REXPLogical;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REXPString;
import org.rosuda.REngine.REXPUnknown;
import org.rosuda.REngine.RList;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.KMeansClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.utils.ListUtils;


 
/**
 * @author Andy
 *
 */
public class RServiceUsingRserve 
{
	private static final long serialVersionUID = 1L;

	public RServiceUsingRserve()
	{
	}

	private static String rFolderName = "R_output";
	
	private static RConnection getRConnection() throws RemoteException
	{
		
		
		RConnection rConnection = null; // establishing R connection		
		try
		{
			rConnection = new RConnection();
		}
		catch (RserveException e)
		{
			//e.printStackTrace();
			throw new RserveConnectionException(e);
		}
		return rConnection;
	}
	public  static class RserveConnectionException extends RemoteException{
		/**
		 * 
		 */
		private static final long serialVersionUID = 1L;

		public  RserveConnectionException(Exception e){
			super("Unable to connect to RServe",e);
		}
	}

	private static String plotEvalScript(RConnection rConnection,String docrootPath , String script, boolean showWarnings) throws RserveException, REXPMismatchException
	{
		String file = String.format("user_script_%s.jpg", UUID.randomUUID());
		String dir = docrootPath + rFolderName + "/";
		(new File(dir)).mkdirs();
		String str = null;
		try
		{
			str = String.format("jpeg(\"%s\")", dir + file);
			evalScript(rConnection, str, showWarnings);
			
			rConnection.eval(str = script);
			rConnection.eval(str = "dev.off()");
		}
		catch (RserveException e)
		{
			System.out.println(str);
			throw e;
		}
		catch (REXPMismatchException e)
		{
			System.out.println(str);
			throw e;
		}
		return rFolderName + "/" + file;
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
	
	
	/**
	 * This will wrap an object in an REXP object.
	 * @param object
	 * @return
	 * @throws RemoteException if the object type is unsupported
	 */
	private static REXP getREXP(Object object) throws RemoteException
	{
		// if it's an array...
		if (object instanceof Object[])
		{
			Object[] array = (Object[])object;
			if (array[0] instanceof Object[]) // 2-d matrix
			{
				// handle 2-d matrix
				RList rList = new RList();
				for (Object item : array)
					rList.add(getREXP(item));
				return new REXPList(rList);
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
			else
				throw new RemoteException("Unsupported value type");
		}
		
		// handle non-array by wrapping it in an array
		return getREXP(new Object[]{object});
	}

	private  static void assignNamesToVector(RConnection rConnection,String[] inputNames,Object[] inputValues) throws Exception
	{
		for (int i = 0; i < inputNames.length; i++)
		{
			String name = inputNames[i];
			rConnection.assign(name, getREXP(inputValues[i]));
		}
	}
	
	
	private static  void evaluvateInputScript(RConnection rConnection,String script,Vector<RResult> resultVector,boolean showIntermediateResults,boolean showWarnings ) throws ScriptException, RserveException, REXPMismatchException{
		evalScript(rConnection, script, showWarnings);
		if (showIntermediateResults){
			Object storedRdatas = evalScript(rConnection, "ls()", showWarnings);
			if(storedRdatas instanceof REXPString){
				String[] Rdatas =((REXPString) storedRdatas).asStrings();
				for(int i=0;i<Rdatas.length;i++){
					String scriptToAcessRObj = Rdatas[i];
					if(scriptToAcessRObj.compareTo("mycache") == 0)
						continue;
					REXP RobjValue = evalScript(rConnection, scriptToAcessRObj, false);
					//When function reference is called returns null
					if(RobjValue == null)
						continue;
					resultVector.add(new RResult(scriptToAcessRObj, rexp2javaObj(RobjValue)));	
				}
			}			
		}
	}
	
	
	
	public static RResult[] runScript( String docrootPath, String[] inputNames, Object[] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings) throws Exception
	{		
		RConnection rConnection = getRConnection();
		
		RResult[] results = null;
		Vector<RResult> resultVector = new Vector<RResult>();
		try
		{
			// ASSIGNS inputNames to respective Vector in R "like x<-c(1,2,3,4)"			
			assignNamesToVector(rConnection,inputNames,inputValues);
			evaluvateInputScript(rConnection, script, resultVector, showIntermediateResults, showWarnings);
			if (plotScript != ""){// R Script to EVALUATE plotScript
				String plotEvalValue = plotEvalScript(rConnection,docrootPath, plotScript, showWarnings);
				resultVector.add(new RResult("Plot Results", plotEvalValue));
			}
			for (int i = 0; i < outputNames.length; i++){// R Script to EVALUATE output Script
				String name = outputNames[i];						
				REXP evalValue = evalScript(rConnection, name, showWarnings);	
				resultVector.add(new RResult(name, rexp2javaObj(evalValue)));					
			}
			// clear R objects
			evalScript(rConnection, "rm(list=ls())", false);
			
		}
		catch (Exception e)	{
			e.printStackTrace();
			String errorStatement = e.getMessage();
			// to send error from R to As3 side results is created with one
			// object			
			resultVector.add(new RResult("Error Statement", errorStatement));
		}
		finally
		{
			results = new RResult[resultVector.size()];
			resultVector.toArray(results);
			rConnection.close();
		}
		return results;
	}
	
	
	/*
	 * Taken from rJava Opensource code and 
	 * added support for  Rlist
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
				Object[] listOfREXP = rList.toArray() ;
				//convert object in List as Java Objects
				// eg: REXPDouble as Double or Doubles
				for(int i = 0; i < listOfREXP.length ;  i++){
					REXP obj = (REXP)listOfREXP[i];
					listOfREXP[i] =  rexp2javaObj(obj);
				}
				return listOfREXP;
			}
		}
		else{//rlist
			
			return rexp.toDebugString();
		}
		return rexp;
		
		
	}

	public static LinearRegressionResult linearRegression(String docrootPath,double[] dataX, double[] dataY) throws RemoteException
	{
		RConnection rConnection = getRConnection();
		if (dataX.length == 0 || dataY.length == 0)
			throw new RemoteException("Unable to run computation on zero-length arrays.");
		if (dataX.length != dataY.length)
			throw new RemoteException("Unable to run computation on two arrays with different lengths (" + dataX.length
					+ " != " + dataY.length + ").");
		// System.out.println("entering linearRegression()");
		// System.out.println("got r connection");
		LinearRegressionResult result = new LinearRegressionResult();
		try
		{

			// Push the data to R
			rConnection.assign("x", dataX);
			rConnection.assign("y", dataY);

			// Perform the calculation
			rConnection.eval("fit <- lm(y~x)");

			// option to draw the plot, regression line and store the image

			rConnection.eval(String.format("jpeg(\"%s\")", docrootPath + rFolderName + "/Linear_Regression.jpg"));
			rConnection.eval("plot(x,y)");
			rConnection.eval("abline(fit)");
			rConnection.eval("dev.off()");

			// Get the data from R
			result.setIntercept(rConnection.eval("coefficients(fit)[1]").asDouble());
			result.setSlope(rConnection.eval("coefficients(fit)[2]").asDouble());
			result.setRSquared(rConnection.eval("summary(fit)$r.squared").asDouble());
			result.setSummary("");// rConnection.eval("summary(fit)").asString());
			result.setResidual(rConnection.eval("resid(fit)").asDoubles());

		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		finally
		{
			rConnection.close();
		}
		return result;
	}

	public static KMeansClusteringResult kMeansClustering(String docrootPath,double[] dataX, double[] dataY, int numberOfClusters) throws RemoteException
	{
		RConnection rConnection = getRConnection();
		int[] clusterNumber = new int[1];
		clusterNumber[0] = numberOfClusters;
		int[] iterations = new int[1];
		iterations[0] = 2;

		if (dataX.length == 0 || dataY.length == 0)
			throw new RemoteException("Unable to run computation on zero-length arrays.");
		if (dataX.length != dataY.length)
			throw new RemoteException("Unable to run computation on two arrays with different lengths (" + dataX.length
					+ " != " + dataY.length + ").");

		KMeansClusteringResult kclresult = new KMeansClusteringResult();

		try
		{

			// Push the data to R
			rConnection.assign("x", dataX);
			rConnection.assign("y", dataY);
			rConnection.assign("clusternumber", clusterNumber);
			rConnection.assign("iter.max", iterations);

			// Performing the calculation
			rConnection.eval("dataframe1 <- data.frame(x,y)");
			// Each run of the algorithm gives a different result, thus continue
			// till results are constant
			rConnection
					.eval("Clustering <- function(clusternumber, iter.max)\n{result1 <- kmeans(dataframe1, clusternumber, iter.max)\n result2 <- kmeans(dataframe1, clusternumber, (iter.max-1))\n while(result1$centers != result2$centers){ iter.max <- iter.max + 1 \n result1 <- kmeans(dataframe1, clusternumber, iter.max) \n result2 <- kmeans(dataframe1, clusternumber, (iter.max-1))} \n print(result1) \n print(result2)}");
			rConnection.eval("Cluster <- Clustering(clusternumber, iter.max)");

			// option for drawing a graph, shows centroids

			// Get the data from R
			// Returns a vector indicating which cluster each data point belongs
			// to
			kclresult.setClusterGroup(rConnection.eval("Cluster$cluster").asDoubles());
			// Returns the means of each of the clusters
			kclresult.setClusterMeans(rConnection.eval("Cluster$centers").asDoubleMatrix());
			// Returns the size of each cluster
			kclresult.setClusterSize(rConnection.eval("Cluster$size").asDoubles());
			// Returns the sum of squares within each cluster
			kclresult.setWithinSumOfSquares(rConnection.eval("Cluster$withinss").asDoubles());
			// Returns the image from R
			// option for storing the image of the graphic output from R
			String str = String.format("jpeg(\"%s\")", docrootPath + rFolderName + "/Kmeans_Clustering.jpg");
//			System.out.println(str);
			evalScript(rConnection, str,false);
			rConnection
					.eval("plot(dataframe1,xlab= \"x\", ylab= \"y\", main = \"Kmeans Clustering\", col = Cluster$cluster) \n points(Cluster$centers, col = 1:5, pch = 10)");
			rConnection.eval("dev.off()");
			kclresult.setRImageFilePath("Kmeans_Clustering.jpg");

		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		finally
		{
			rConnection.close();
		}
		return kclresult;
	}

	public static HierarchicalClusteringResult hierarchicalClustering(String docrootPath,double[] dataX, double[] dataY) throws RemoteException
	{
		RConnection rConnection = getRConnection();
		String[] agglomerationMethod = new String[7];
		agglomerationMethod[0] = "ward";
		agglomerationMethod[1] = "average";
		agglomerationMethod[2] = "centroid";
		agglomerationMethod[3] = "single";
		agglomerationMethod[4] = "complete";
		agglomerationMethod[5] = "median";
		agglomerationMethod[6] = "mcquitty";
		String agglomerationMethodType = new String("ward");

		if (dataX.length == 0 || dataY.length == 0)
			throw new RemoteException("Unable to run computation on zero-length arrays.");
		if (dataX.length != dataY.length)
			throw new RemoteException("Unable to run computation on two arrays with different lengths (" + dataX.length
					+ " != " + dataY.length + ").");

		HierarchicalClusteringResult hclresult = new HierarchicalClusteringResult();
		try
		{

			// Push the data to R
			rConnection.assign("x", dataX);
			rConnection.assign("y", dataY);

			// checking for user method match
			for (int j = 0; j < agglomerationMethod.length; j++)
			{
				if (agglomerationMethod[j].equals(agglomerationMethodType))
				{
					rConnection.assign("method", agglomerationMethod[j]);
				}
			}

			// Performing the calculations
			rConnection.eval("dataframe1 <- data.frame(x,y)");
			rConnection.eval("HCluster <- hclust(d = dist(dataframe1), method)");

			// option for drawing the hierarchical tree and storing the image
			rConnection.eval(String.format("jpeg(\"%s\")", docrootPath + rFolderName + "/Hierarchical_Clustering.jpg"));
			rConnection.eval("plot(HCluster, main = \"Hierarchical Clustering\")");
			rConnection.eval("dev.off()");

			// Get the data from R
			hclresult.setClusterSequence(rConnection.eval("HCluster$merge").asDoubleMatrix());
			hclresult.setClusterMethod(rConnection.eval("HCluster$method").asStrings());
			// hclresult.setClusterLabels(rConnection.eval("HCluster$labels").asStrings());
			hclresult.setClusterDistanceMeasure(rConnection.eval("HCluster$dist.method").asStrings());

		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		finally
		{
			rConnection.close();
		}
		return hclresult;
	}

}

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

import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPDouble;
import org.rosuda.REngine.REXPInteger;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REXPString;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.KMeansClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.utils.ListUtils;


 
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

	private static String plotEvalScript(RConnection rConnection,String docrootPath , String script, boolean showWarnings) throws REXPMismatchException,RserveException
	{
		String file = String.format("user_script_%s.jpg", UUID.randomUUID());
		String dir = docrootPath + rFolderName + "/";
		(new File(dir)).mkdirs();
		String str = String.format("jpeg(\"%s\")", dir + file);
		evalScript(rConnection, str, showWarnings);
		rConnection.eval(script);
		rConnection.eval("dev.off()");		
		return rFolderName + "/" + file;
	}
	
	private static REXP evalScript(RConnection rConnection, String script, boolean showWarnings) throws REXPMismatchException,RserveException
	{
		REXP evalValue = null;
		if(showWarnings)			
			evalValue =  rConnection.eval("try({ options(warn=2) \n" + script + "},silent=TRUE)");
			
		else
			evalValue =  rConnection.eval("try({ options(warn=1) \n" + script + "},silent=TRUE)");		
		return evalValue;
	}
	
	
	
	
	public static RResult[] runScript( String docrootPath, String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings) throws Exception
	{
		
		RConnection rConnection = getRConnection();
		//System.out.println(keys.length);
		String output = "";
		RResult[] results = null;
		REXP evalValue;
		try
		{
			// ASSIGNS inputNames to respective Vector in R "like x<-c(1,2,3,4)"
			for (int i = 0; i < inputNames.length; i++)
			{
				String name = inputNames[i];
				if (inputValues[i][0] instanceof String)
				{
					String[] value = ListUtils.copyStringArray(inputValues[i], new String[inputValues[i].length]);
					rConnection.assign(name, value);
				}
				else
				{
					double[] value = ListUtils.copyDoubleArray(inputValues[i], new double[inputValues[i].length]);
					rConnection.assign(name, value);
				}
			}
			// R Script to EVALUATE inputTA(from R Script Input TextArea)
			if (showIntermediateResults)
			{
				String[] rScript = script.split("\n");
				for (int i = 0; i < rScript.length; i++)
				{
					REXP individualEvalValue = evalScript(rConnection, rScript[i], showWarnings);
					// to-do remove debug information from string
					String trimedString = individualEvalValue.toString();
					while (trimedString.indexOf('[') > 0)
					{
						int pos = trimedString.indexOf('[');
						trimedString = trimedString.substring(pos + 1);
					}
					trimedString = "[" + trimedString;					
					output = output.concat(trimedString);
					output += "\n";
				}
			}
			else
			{
				REXP completeEvalValue = evalScript(rConnection, script, showWarnings);
				output = completeEvalValue.toString();
			}
			// R Script to EVALUATE outputTA(from R Script Output TextArea)
			if (showIntermediateResults)
			{
				int i;
				int iterationTimes;
				if (plotScript != "")
				{
					results = new RResult[outputNames.length + 2];
					String plotEvalValue = plotEvalScript(rConnection,docrootPath, plotScript, showWarnings);
					results[0] = new RResult("Plot Results", plotEvalValue);
					results[1] = new RResult("Intermediate Results", output);
					i = 2;
					iterationTimes = outputNames.length + 2;
				}
				else
				{
					results = new RResult[outputNames.length + 1];
					results[0] = new RResult("Intermediate Results", output);
					i = 1;
					iterationTimes = outputNames.length + 1;
				}
				// to add intermediate results extra object is created as first
				// input, so results length will be one greater than OutputNames
				// int i =1;
				// int iterationTimes =outputNames.length;
				for (; i < iterationTimes; i++)
				{
					String name;
					// Boolean addedTolist = false;
					if (iterationTimes == outputNames.length + 2){
						name = outputNames[i - 2];
					}
					else{
						name = outputNames[i - 1];
					}
					// Script to get R - output
					evalValue = evalScript(rConnection, name, showWarnings);
					if (evalValue.isVector()){
						if (evalValue instanceof REXPString)
							results[i] = new RResult(name, evalValue.asStrings());						
						else if (evalValue instanceof REXPInteger)
							results[i] = new RResult(name, evalValue.asIntegers());
						else if (evalValue instanceof REXPDouble){
							if (evalValue.dim() == null)
								results[i] = new RResult(name, evalValue.asDoubles());
							else
								results[i] = new RResult(name, evalValue.asDoubleMatrix());
						}
						else{
							// if no previous cases were true, return debug String
							results[i] = new RResult(name, evalValue.toDebugString());
						}
					}
					else{
						results[i] = new RResult(name, evalValue.toDebugString());
					}
					
				}//end of for - to store result
			}//end of IF for intermediate results
			else
			{
				int i;
				int iterationTimes;
				if (plotScript != "")
				{
					results = new RResult[outputNames.length + 1];
					String plotEvalValue = plotEvalScript(rConnection,docrootPath, plotScript, showWarnings);
					results[0] = new RResult("Plot Results", plotEvalValue);
					i = 1;
					iterationTimes = outputNames.length + 1;
				}
				else
				{
					results = new RResult[outputNames.length];
					i = 0;
					iterationTimes = outputNames.length;
				}
				// to outputNames script result
				// results = new RResult[outputNames.length];
				for (; i < iterationTimes; i++)
				{
					String name;
					// Boolean addedTolist = false;
					if (iterationTimes == outputNames.length + 1){
						name = outputNames[i - 1];
					}
					else{
						name = outputNames[i];
					}
					// Script to get R - output
					evalValue = evalScript(rConnection, name, showWarnings);				
//					System.out.println(evalValue);

					if (evalValue.isVector()){
						if (evalValue instanceof REXPString)
							results[i] = new RResult(name, evalValue.asStrings());
						else if (evalValue instanceof REXPInteger)
							results[i] = new RResult(name, evalValue.asIntegers());
						else if (evalValue instanceof REXPDouble){
							if (evalValue.dim() == null)
								results[i] = new RResult(name, evalValue.asDoubles());
							else
								results[i] = new RResult(name, evalValue.asDoubleMatrix());
						}
						else{
							// if no previous cases were true, return debug String
							results[i] = new RResult(name, evalValue.toDebugString());
						}
					}
					else{
						results[i] = new RResult(name, evalValue.toDebugString());
					}

//					System.out.println(name + " = " + evalValue.toDebugString() + "\n");					
				}
			}
		}
		catch (Exception e)	{
			e.printStackTrace();
			output += e.getMessage();
			// to send error from R to As3 side results is created with one
			// object
			results = new RResult[1];
			results[0] = new RResult("Error Statement", output);
		}
		finally
		{
			rConnection.close();
		}
		return results;
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

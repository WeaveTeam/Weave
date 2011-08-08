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
import java.io.PrintStream;
import java.lang.reflect.Constructor;
import java.rmi.RemoteException;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineFactory;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.KMeansClusteringResult;
import weave.beans.HierarchicalClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.config.WeaveContextParams;
import weave.servlets.GenericServlet;
import weave.utils.ListUtils;
import weave.utils.RUtils;

//import org.rosuda.JRI.REXP;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REngine;
import org.rosuda.REngine.REngineCallbacks;
import org.rosuda.REngine.REngineException;
import org.rosuda.REngine.REngineOutputInterface;

 @SuppressWarnings("unused")
class JRICallbacks implements REngineCallbacks, REngineOutputInterface {
	private PrintStream out = System.out;
	public void RFlushConsole(REngine eng) {
		out.flush();
	}
	public void RShowMessage(REngine eng, String msg) {
		out.print(msg);
	}
	public void RWriteConsole(REngine eng, String msg, int otype) {
		out.print(msg);
	}
}
 
public class JRIService extends GenericServlet
{
	private static final long serialVersionUID = 1L;

	public JRIService()
	{
	}

	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		docrootPath = WeaveContextParams.getInstance(config.getServletContext()).getDocrootPath();
	}

	private String docrootPath = "";
	private String rFolderName = "R_output";
	
	REngine rEngine = null;
	private REngine getREngine() throws Exception
	{		
		try
		{
			String cls = "org.rosuda.REngine.JRI.JRIEngine";
			String[] args = { "--vanilla", "--slave" };
			rEngine= REngine.engineForClass(cls, args, new JRICallbacks(), false);
			System.out.println(rEngine.getClass().getClassLoader());
			
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		return rEngine;
	}
	private String plotEvalScript(REngine rEngine, String script, boolean showWarnings) throws REXPMismatchException, REngineException, ScriptException
	{
		String file = String.format("user_script_%s.jpg", UUID.randomUUID());
		String dir = docrootPath + rFolderName + "/";
		(new File(dir)).mkdirs();
		String str = String.format("jpeg(\"%s\")", dir + file);
		evalScript(rEngine, str, showWarnings);
		rEngine.parseAndEval(script);
		rEngine.parseAndEval("dev.off()");		
		return rFolderName + "/" + file;
	}
	
	private REXP evalScript(REngine rEngine, String script, boolean showWarnings) throws REXPMismatchException, REngineException, ScriptException
	{
		// rConnection.voidEval("");
		REXP evalValue = null;
		if(showWarnings)			
			evalValue = (REXP) rEngine.parseAndEval("try({ options(warn=2) \n" + script + "},silent=TRUE)");
			
		else
			evalValue = (REXP) rEngine.parseAndEval("try({ options(warn=1) \n" + script + "},silent=TRUE)");	
		
		System.out.println("evalScript Evaluvation:" + " = " + evalValue.toDebugString() + "\n");
		return evalValue;
	}
	
	
	
//	public ScriptEngine testDiscovery() {		
//		String extension = "R";
//		ScriptEngineManager manager = new ScriptEngineManager();
//		// List<ScriptEngineFactory> factories = manager.getEngineFactories();
//		ScriptEngine engine = manager.getEngineByExtension(extension);
//		assert engine != null;		
//		return engine;
//	}
	
	@SuppressWarnings("unchecked")
	public RResult[] runScript(String[] keys,String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings ,boolean useColumnAsList) throws Exception
	{
		System.out.println(script);
		String output = "";
		if(rEngine == null){
			rEngine = getREngine();
		}
		RResult[] results = null;
		REXP evalValue;
		try
		{
			// ASSIGNS inputNames to respective Vector in R "like x<-c(1,2,3,4)"
			for (int i = 0; i < inputNames.length; i++)
			{
				String name = inputNames[i];				
				REXP rexp = null;
				if(useColumnAsList){//if column to consider as list in R
					@SuppressWarnings("rawtypes")
					HashMap hm = new HashMap();
					for(int keyID = 0; keyID < keys.length ;keyID++){
						hm.put(keys[keyID], inputValues[i][keyID]);
					}
					rexp = RUtils.jobj2rexp(hm);					
				}
				else{//if column to consider as vector in R					
					rexp = RUtils.jobj2rexp( inputValues[i]);
				}
				
				rEngine.assign(name, rexp);			
			}
			// R Script to EVALUATE inputTA(from R Script Input TextArea)
			if (showIntermediateResults)
			{
				String[] rScript = script.split("\n");
				for (int i = 0; i < rScript.length; i++)
				{
					REXP individualEvalValue = evalScript(rEngine, rScript[i], showWarnings);
					// to-do remove debug information from string
					String trimedString = individualEvalValue.toString();
					while (trimedString.indexOf('[') > 0)
					{
						int pos = trimedString.indexOf('[');
						System.out.println(pos + "\n");
						System.out.println(trimedString + "\n");
						trimedString = trimedString.substring(pos + 1);
					}
					trimedString = "[" + trimedString;					
					output = output.concat(trimedString);
					output += "\n";
				}
			}
			else
			{
				REXP completeEvalValue = evalScript(rEngine, script, showWarnings);
				output = completeEvalValue.toString();
				System.out.println("Complete Evaluvation:" + " = " + output + "\n");
			}
			// R Script to EVALUATE outputTA(from R Script Output TextArea)
			if (showIntermediateResults)
			{
				int i;
				int iterationTimes;
				if (plotScript != "")
				{
					results = new RResult[outputNames.length + 2];
					String plotEvalValue = plotEvalScript(rEngine, plotScript, showWarnings);
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
					evalValue = evalScript(rEngine, name, showWarnings);
					System.out.println("EvalValue" + " = " + evalValue.toString() + "\n");
					Object value = RUtils.rexp2jobj(evalValue);					
					results[i] = new RResult(name, value);
					System.out.println(name + " = " + value.toString() + "\n");
					
				}//end of for - to store result
			}//end of IF for intermediate results
			else
			{
				int i;
				int iterationTimes;
				if (plotScript != "")
				{
					results = new RResult[outputNames.length + 1];
					String plotEvalValue = plotEvalScript(rEngine, plotScript, showWarnings);
					System.out.println(plotEvalValue);
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
					evalValue = evalScript(rEngine, name, showWarnings);				
					Object value = RUtils.rexp2jobj(evalValue);	
					results[i] = new RResult(name, value);
					System.out.println(name + " = " + value.toString() + "\n");					
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
			rEngine.close();
		}
		return results;
	}

//	public LinearRegressionResult linearRegression(double[] dataX, double[] dataY) throws RemoteException
//	{
//		if (dataX.length == 0 || dataY.length == 0)
//			throw new RemoteException("Unable to run computation on zero-length arrays.");
//		if (dataX.length != dataY.length)
//			throw new RemoteException("Unable to run computation on two arrays with different lengths (" + dataX.length
//					+ " != " + dataY.length + ").");
//		// System.out.println("entering linearRegression()");
//		Rengine rEngine = getRengine();
//		// System.out.println("got r connection");
//		LinearRegressionResult result = new LinearRegressionResult();
//		try
//		{
//
//			// Push the data to R
//			rEngine.assign("x", dataX);
//			rEngine.assign("y", dataY);
//
//			// Perform the calculation
//			rEngine.eval("fit <- lm(y~x)");
//
//			// option to draw the plot, regression line and store the image
//
//			rEngine.eval(String.format("jpeg(\"%s\")", docrootPath + rFolderName + "/Linear_Regression.jpg"));
//			rEngine.eval("plot(x,y)");
//			rEngine.eval("abline(fit)");
//			rEngine.eval("dev.off()");
//
//			// Get the data from R
//			result.setIntercept(rEngine.eval("coefficients(fit)[1]").asDouble());
//			result.setSlope(rEngine.eval("coefficients(fit)[2]").asDouble());
//			result.setRSquared(rEngine.eval("summary(fit)$r.squared").asDouble());
//			result.setSummary("");// rConnection.eval("summary(fit)").asString());
//			result.setResidual(rEngine.eval("resid(fit)").asDoubleArray());
//
//		}
//		catch (Exception e)
//		{
//			e.printStackTrace();
//			throw new RemoteException(e.getMessage());
//		}
//		finally
//		{
//			rEngine.end();
//		}
//		return result;
//	}

//	public KMeansClusteringResult kMeansClustering(double[] dataX, double[] dataY, int numberOfClusters, boolean showWarnings) throws RemoteException
//	{
//		int[] clusterNumber = new int[1];
//		clusterNumber[0] = numberOfClusters;
//		int[] iterations = new int[1];
//		iterations[0] = 2;
//
//		if (dataX.length == 0 || dataY.length == 0)
//			throw new RemoteException("Unable to run computation on zero-length arrays.");
//		if (dataX.length != dataY.length)
//			throw new RemoteException("Unable to run computation on two arrays with different lengths (" + dataX.length
//					+ " != " + dataY.length + ").");
//
//		Rengine rEngine = getRngine();
//		KMeansClusteringResult kclresult = new KMeansClusteringResult();
//
//		try
//		{
//
//			// Push the data to R
//			rEngine.assign("x", dataX);
//			rEngine.assign("y", dataY);
//			rEngine.assign("clusternumber", clusterNumber);
//			rEngine.assign("iter.max", iterations);
//
//			// Performing the calculation
//			rEngine.eval("dataframe1 <- data.frame(x,y)");
//			// Each run of the algorithm gives a different result, thus continue
//			// till results are constant
//			rEngine
//					.eval("Clustering <- function(clusternumber, iter.max)\n{result1 <- kmeans(dataframe1, clusternumber, iter.max)\n result2 <- kmeans(dataframe1, clusternumber, (iter.max-1))\n while(result1$centers != result2$centers){ iter.max <- iter.max + 1 \n result1 <- kmeans(dataframe1, clusternumber, iter.max) \n result2 <- kmeans(dataframe1, clusternumber, (iter.max-1))} \n print(result1) \n print(result2)}");
//			rEngine.eval("Cluster <- Clustering(clusternumber, iter.max)");
//
//			// option for drawing a graph, shows centroids
//
//			// Get the data from R
//			// Returns a vector indicating which cluster each data point belongs
//			// to
//			kclresult.setClusterGroup(rEngine.eval("Cluster$cluster").asDoubleArray());
//			// Returns the means of each of the clusters
//			kclresult.setClusterMeans(rEngine.eval("Cluster$centers").asDoubleMatrix());
//			// Returns the size of each cluster
//			kclresult.setClusterSize(rEngine.eval("Cluster$size").asDoubleArray());
//			// Returns the sum of squares within each cluster
//			kclresult.setWithinSumOfSquares(rEngine.eval("Cluster$withinss").asDoubleArray());
//			// Returns the image from R
//			// option for storing the image of the graphic output from R
//			String str = String.format("jpeg(\"%s\")", docrootPath + rFolderName + "/Kmeans_Clustering.jpg");
//			System.out.println(str);
//			evalScript(rEngine, str, showWarnings);
//			rEngine
//					.eval("plot(dataframe1,xlab= \"x\", ylab= \"y\", main = \"Kmeans Clustering\", col = Cluster$cluster) \n points(Cluster$centers, col = 1:5, pch = 10)");
//			rEngine.eval("dev.off()");
//			kclresult.setRImageFilePath("Kmeans_Clustering.jpg");
//
//		}
//		catch (Exception e)
//		{
//			e.printStackTrace();
//			throw new RemoteException(e.getMessage());
//		}
//		finally
//		{
//			rEngine.end();
//		}
//		return kclresult;
//	}

//	public HierarchicalClusteringResult hierarchicalClustering(double[] dataX, double[] dataY) throws RemoteException
//	{
//		String[] agglomerationMethod = new String[7];
//		agglomerationMethod[0] = "ward";
//		agglomerationMethod[1] = "average";
//		agglomerationMethod[2] = "centroid";
//		agglomerationMethod[3] = "single";
//		agglomerationMethod[4] = "complete";
//		agglomerationMethod[5] = "median";
//		agglomerationMethod[6] = "mcquitty";
//		String agglomerationMethodType = new String("ward");
//
//		if (dataX.length == 0 || dataY.length == 0)
//			throw new RemoteException("Unable to run computation on zero-length arrays.");
//		if (dataX.length != dataY.length)
//			throw new RemoteException("Unable to run computation on two arrays with different lengths (" + dataX.length
//					+ " != " + dataY.length + ").");
//
//		Rengine rEngine = getRengine();
//		HierarchicalClusteringResult hclresult = new HierarchicalClusteringResult();
//		try
//		{
//
//			// Push the data to R
//			rEngine.assign("x", dataX);
//			rEngine.assign("y", dataY);
//
//			// checking for user method match
//			for (int j = 0; j < agglomerationMethod.length; j++)
//			{
//				if (agglomerationMethod[j].equals(agglomerationMethodType))
//				{
//					rEngine.assign("method", agglomerationMethod[j]);
//				}
//			}
//
//			// Performing the calculations
//			rEngine.eval("dataframe1 <- data.frame(x,y)");
//			rEngine.eval("HCluster <- hclust(d = dist(dataframe1), method)");
//
//			// option for drawing the hierarchical tree and storing the image
//			rEngine.eval(String.format("jpeg(\"%s\")", docrootPath + rFolderName + "/Hierarchical_Clustering.jpg"));
//			rEngine.eval("plot(HCluster, main = \"Hierarchical Clustering\")");
//			rEngine.eval("dev.off()");
//
//			// Get the data from R
//			hclresult.setClusterSequence(rEngine.eval("HCluster$merge").asDoubleMatrix());
//			hclresult.setClusterMethod(rEngine.eval("HCluster$method").asStringArray());
//			// hclresult.setClusterLabels(rConnection.eval("HCluster$labels").asStrings());
//			hclresult.setClusterDistanceMeasure(rEngine.eval("HCluster$dist.method").asStringArray());
//
//		}
//		catch (Exception e)
//		{
//			e.printStackTrace();
//			throw new RemoteException(e.getMessage());
//		}
//		finally
//		{
//			rEngine.end();
//		}
//		return hclresult;
//	}
}

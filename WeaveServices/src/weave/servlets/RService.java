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

import java.rmi.RemoteException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.KMeansClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.config.WeaveContextParams;


 
public class RService extends GenericServlet
{
	private static final long serialVersionUID = 1L;

	public RService()
	{
	}

	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		docrootPath = WeaveContextParams.getInstance(config.getServletContext()).getDocrootPath();
	}

	private String docrootPath = "";
	
	public RResult[] runScript(String[] keys,String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception
	{
		
		try{
			return RServiceUsingJRI.runScript( docrootPath, keys, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings, useColumnAsList);
		}
		catch (RServiceUsingJRI.JRIConnectionException excep)
		{
			try
			{
				return RServiceUsingRserve.runScript( docrootPath, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings);
			}
			catch (RServiceUsingRserve.RserveConnectionException e)
			{
				throw new RemoteException("Unable to connect to RServe & Unable to initialize REngine", e);
			}
		}
	}
	
	
	
	
	
	
	
	

	public LinearRegressionResult linearRegression(double[] dataX, double[] dataY) throws RemoteException
	{
		
		return RServiceUsingRserve.linearRegression( docrootPath, dataX, dataY);
	}

	public KMeansClusteringResult kMeansClustering(double[] dataX, double[] dataY, int numberOfClusters) throws RemoteException
	{
		
		return RServiceUsingRserve.kMeansClustering( docrootPath, dataX, dataY, numberOfClusters);
	}

	public HierarchicalClusteringResult hierarchicalClustering(double[] dataX, double[] dataY) throws RemoteException
	{
		return RServiceUsingRserve.hierarchicalClustering( docrootPath, dataX, dataY);
	}

}

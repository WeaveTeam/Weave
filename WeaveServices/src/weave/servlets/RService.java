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

import java.io.IOException;
import java.rmi.RemoteException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.config.WeaveContextParams;


 
public class RService extends GenericServlet
{
	private static final long serialVersionUID = 1L;

	public RService()
	{
	}

	private static Process rProcess = null;
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		docrootPath = WeaveContextParams.getInstance(config.getServletContext()).getDocrootPath();
		
	    try {
	    	String rServePath = WeaveContextParams.getInstance(config.getServletContext()).getRServePath();
	    	if (rServePath != null && rServePath.length() > 0)
	    		rProcess = Runtime.getRuntime().exec(rServePath);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void destroy()
	{
		try {
			if (rProcess != null)
				rProcess.destroy();
		} finally {
			super.destroy();
		}
	}

	private String docrootPath = "";
	
	enum ServiceType { JRI, RSERVE; }
	private static ServiceType serviceType = ServiceType.JRI;
	
	public boolean checkforJRIService()throws Exception
	{
	    boolean jriStatus;
	
	    try
			{
				if(RServiceUsingJRI.getREngine() != null)
						jriStatus = true;
					else
						jriStatus = false;
				
			}
			//if JRI not present
			catch (RServiceUsingJRI.JRIConnectionException e) {
				e.printStackTrace();
				jriStatus = false;
			}
	//	}
		
		return jriStatus;
	}
	
	public RResult[] runScript(String[] keys,String[] inputNames, Object[] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception
	{
		Exception exception = null;
		
		// check chosen service first
		ServiceType[] types = ServiceType.values();
		if (serviceType != types[0])
		{
			types[1] = types[0];
			types[0] = serviceType;
		}
		for (ServiceType type : types)
		{
			try
			{
				if (type == ServiceType.RSERVE)
					return RServiceUsingRserve.runScript( docrootPath, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings);
				
				// this crashes Tomcat
				if (type == ServiceType.JRI)
					return RServiceUsingJRI.runScript( docrootPath, keys, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings, useColumnAsList);
				
			}
			catch (RServiceUsingJRI.JRIConnectionException e)
			{
				e.printStackTrace();
				// remember exception associated with chosen service
				// alternate for next time
				if (type == serviceType)
					exception = e;
				else
					serviceType = type;
			}
			catch (RServiceUsingRserve.RserveConnectionException e)
			{
				e.printStackTrace();
				// remember exception associated with chosen service
				// alternate for next time
				if (type == serviceType)
					exception = e;
				else
					serviceType = type;
			}
		}
		throw new RemoteException("Unable to connect to RServe & Unable to initialize REngine", exception);
	}
	
	

	public LinearRegressionResult linearRegression(double[] dataX, double[] dataY) throws RemoteException
	{
		
		return RServiceUsingRserve.linearRegression( docrootPath, dataX, dataY);
	}

	public RResult[] kMeansClustering(String[] inputNames, Object[][] inputValues, boolean showWarnings,int numberOfClusters, int iterations) throws Exception
	{
		
		//return RServiceUsingRserve.kMeansClustering( docrootPath, dataX, dataY, numberOfClusters);
		return RServiceUsingRserve.kMeansClustering(inputNames, inputValues, showWarnings,numberOfClusters, iterations);
	}

	public HierarchicalClusteringResult hierarchicalClustering(double[] dataX, double[] dataY) throws RemoteException
	{
		return RServiceUsingRserve.hierarchicalClustering( docrootPath, dataX, dataY);
	}

	public RResult[] handlingMissingData(String[] inputNames, Object[][] inputValues, String[] outputNames, boolean showIntermediateResults, boolean showWarnings, boolean completeProcess) throws Exception
	{
		return RServiceUsingRserve.handlingMissingData(inputNames, inputValues, outputNames,showIntermediateResults, showWarnings, completeProcess);
	}
	
	
}

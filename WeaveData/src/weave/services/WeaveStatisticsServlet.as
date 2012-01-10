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

package weave.services
{
	import mx.rpc.AsyncToken;
	
	import weave.api.services.IWeaveStatisticsService;

	/**
	 * WSStatisticsServlet
	 * @author spurushe
	 * @author sanbalag
	 */
	public class WeaveStatisticsServlet implements IWeaveStatisticsService
	{
		public function WeaveStatisticsServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
		}
		
		protected var servlet:AMF3Servlet;
		
		// async result will be of type KMeansClusteringResult
		public function KMeansClustering(dataX:Array, dataY:Array, numberOfClusters:int):AsyncToken
		{			
			return servlet.invokeAsyncMethod("kMeansClustering", arguments);
		}
		
		// async result will be of type HierarchicalClusteringResult
		public function HierarchicalClustering(dataX:Array, dataY:Array):AsyncToken
		{
			return servlet.invokeAsyncMethod("hierarchicalClustering", arguments);
		}
		
		// NEED TO INSTALL (fpc) PACKAGE FROM R 
		
		// async result will be of type DensityBasedClusteringResult
		/*public function DensityBasedClustering(dataX:Array, dataY:Array):DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("densityBasedClustering", arguments);
		}*/		
		public function linearRegression(dataX:Array, dataY:Array):AsyncToken
		{
			return servlet.invokeAsyncMethod("linearRegression", arguments);
		}

		
		
		public function runScript(inputNames:Array, inputValues:Array, outputNames:Array, script:String,plotScript:String, showIntermediateResults:Boolean, showWarningMessages:Boolean ):AsyncToken
		{
			return servlet.invokeAsyncMethod("runScript", arguments);
		}

		
		
	}
}

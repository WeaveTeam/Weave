/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.services
{
	import mx.rpc.AsyncToken;
	
	/**
	 * @author spurushe
	 * @author sanbalag
	 */
	public class WeaveRServlet extends AMF3Servlet
	{
		public function WeaveRServlet(url:String)
		{
			super(url);
		}
		
		public function runScript(keys:Array, inputNames:Array, inputValues:Array, outputNames:Array, script:String,plotScript:String, showIntermediateResults:Boolean, showWarningMessages:Boolean , useColumnsAsList:Boolean ):AsyncToken
		{
			return invokeAsyncMethod("runScript", arguments);
		}
		
		public function checkforJRIService():AsyncToken
		{
			return invokeAsyncMethod("checkforJRIService",arguments);
		}
		
		public function runScriptOnCSVOnServer(queryObject:Array):AsyncToken
		{
			return invokeAsyncMethod("runScriptOnCSVOnServer", arguments);
		}
		
		public function runScriptOnSQLOnServer(queryObject:Array, queryStatement:String, schema:String):AsyncToken
		{
			return invokeAsyncMethod("runScriptOnSQLOnServer", arguments);
		}
		
		/** async result will be of type KMeansClusteringResult */
		public function KMeansClustering(inputValues:Array,showWarnings:Boolean,numberOfClusters:int,iterations:int):AsyncToken
		{			
			return invokeAsyncMethod("kMeansClustering", arguments);
		}
		
		/** async result will be of type HierarchicalClusteringResult */
		public function HierarchicalClustering(dataX:Array, dataY:Array):AsyncToken
		{
			return invokeAsyncMethod("hierarchicalClustering", arguments);
		}
		
		// NEED TO INSTALL (fpc) PACKAGE FROM R 
		
		/* * async result will be of type DensityBasedClusteringResult * /
		public function DensityBasedClustering(dataX:Array, dataY:Array):AsyncToken
		{
			return servlet.invokeAsyncMethod("densityBasedClustering", arguments);
		}
		*/
		
		public function linearRegression(method:String, dataX:Array, dataY:Array, polynomialDegree:int):AsyncToken
		{
			return invokeAsyncMethod("linearRegression", arguments);
		}

		public function handlingMissingData(inputNames:Array, inputValues:Array, outputNames:Array,showIntermediateResults:Boolean, showWarningMessages:Boolean, completeProcess:Boolean ):AsyncToken
		{
			return invokeAsyncMethod("handlingMissingData", arguments);
			
		}
		
		public function normalize(data:Array):AsyncToken
		{
			return invokeAsyncMethod("normalize", arguments);
			
		}
		
		public function doClassDiscrimination(dataX:Array, dataY:Array, flag:Boolean):AsyncToken
		{
			return invokeAsyncMethod("doClassDiscrimintation", arguments);
		}
	}
}

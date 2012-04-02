/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.services
{
	import mx.rpc.AsyncToken;
	
	/**
	 * WSStatisticsServlet
	 * @author spurushe
	 * @author sanbalag
	 */
	public interface IWeaveRService 
	{
		
		// async result will be of type KMeansClusteringResult
		function KMeansClustering(dataX:Array, dataY:Array, numberOfClusters:int):AsyncToken;		
		// async result will be of type HierarchicalClusteringResult
		function HierarchicalClustering(dataX:Array, dataY:Array):AsyncToken;			
		function linearRegression(dataX:Array, dataY:Array):AsyncToken;			
		function runScript(keys:Array,inputNames:Array, inputValues:Array, outputNames:Array, script:String,plotScript:String, showIntermediateResults:Boolean,showWarningMessages:Boolean, useColumnsAsList:Boolean ):AsyncToken;	
		}
}

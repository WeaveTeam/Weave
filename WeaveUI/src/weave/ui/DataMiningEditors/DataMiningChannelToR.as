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
package weave.ui.DataMiningEditors
{
	import weave.services.beans.KMeansClusteringResult;

	/**
	 *This class uses all the data mining algorithm objects and makes independent asynchronous calls to R for each algorithm and also collects their results
	 * @spurushe
	 **/
	
	public class DataMiningChannelToR
	{
		//final results of ALL data mining algorithms run in R
		public var DMResultObjects:Array = new Array();
		
		
		private var kMeans:KMeansClustering = null;
		
		
		public function DataMiningChannelToR(_arrayOfDataMiningObjects:Array, _inputColumns:Array, _inputKeys:Array)
		{
			sortingDMObjects(_arrayOfDataMiningObjects, _inputColumns,_inputKeys);
		}
		
		public function foo():void{
			
			var kMeansResult:KMeansClusteringResult = kMeans.finalResult;
		}
		
		private function sortingDMObjects(inputObjects:Array, inputColumns:Array, inputKeys:Array):void
		{
			for(var i:int = 0; i < inputObjects.length; i++)
			{
				//pick up the object
				var tempObject:DataMiningAlgorithmObject = inputObjects[i] as DataMiningAlgorithmObject;
				//start sorting
				if(tempObject.label == "KMeans Clustering")
				{
					if(kMeans == null)kMeans = new KMeansClustering(foo);
					kMeans.doKMeans(inputColumns,inputKeys,tempObject.parameterMapping["kClusterNumber"], tempObject.parameterMapping["kIterationNumber"],tempObject.parameterMapping["kMeansAlgo"],7);
				}
			}
		}
		
		
	}
}
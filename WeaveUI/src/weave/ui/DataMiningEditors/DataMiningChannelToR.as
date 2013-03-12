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
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.DataSources.CSVDataSource;
	import weave.services.beans.FuzzyKMeansClusteringResult;
	import weave.services.beans.IDataMiningResult;
	import weave.services.beans.KMeansClusteringResult;
	import weave.services.beans.PartitionAroundMedoidsClusteringResult;
	import weave.utils.ColumnUtils;
	import weave.utils.ResultUtils;

	/**
	 *This class uses all the data mining algorithm objects and makes independent asynchronous calls to R for each algorithm and also collects their results
	 * @spurushe
	 **/
	
	public class DataMiningChannelToR
	{
		//final results of ALL data mining algorithms run in R
		public var DMResultObjects:Dictionary = new Dictionary();//made into a dictionary so that we can identify the result columns being returned back
		private var columnNames:Array = new Array();//used for labelling clustering columns while constructing the CSV datasource
		private var finalColumnsGroup:ICallbackCollection; // linkable object used to group norm columns and check busy status
		private var clusterVectors:Array = new Array();//collects the cluster vector from each clustering result returned from R
		private var numberColumnsCollection:Array = new Array(); //collects the NumberColumns generated from the clustering vetors
		private var keys:Array = null;
		private var sendingAsyncCallCounter:int;
		private var receivedAsyncCallCounter:int;
		
		public function DataMiningChannelToR(incomingDataMiningObjects:Dictionary, _inputColumns:Array, _inputKeys:Array)
		{
			sortingDMObjects(incomingDataMiningObjects, _inputColumns,_inputKeys);
			sendingAsyncCallCounter = 0;
			receivedAsyncCallCounter = 0;
		}
		
		private function sortingDMObjects(inputObjects:Dictionary, inputColumns:Array, inputKeys:Array):void
		{
			for(var type:String  in inputObjects)
			{
				//pick up the object
				var tempObject:DataMiningAlgorithmObject = inputObjects[type] as DataMiningAlgorithmObject;
				//start sorting
				if(tempObject.label == "KMeans Clustering")
				{
					var kMeans:KMeansClustering = new KMeansClustering(this,fillingRResults);
					kMeans.doKMeans(inputColumns,inputKeys,tempObject.parameterMapping["kClusterNumber"], tempObject.parameterMapping["kIterationNumber"],tempObject.parameterMapping["kMeansAlgo"],7);
					sendingAsyncCallCounter++;
				}
				
				if(tempObject.label == "Fuzzy KMeans Clustering")
				{
					var fuzzKMeans:FuzzyKMeansClustering = new FuzzyKMeansClustering(this,fillingRResults);
					fuzzKMeans.doFuzzyKMeans(inputColumns,inputKeys,tempObject.parameterMapping["fkClusterNumber"], tempObject.parameterMapping["fkIterationNumber"],tempObject.parameterMapping["fkMeansmetric"]);
					sendingAsyncCallCounter++;  
				}
				
				if(tempObject.label == "Partition Around Medoids Clustering")
				{
					var pam:PartitionAroundMedoidsClustering = new PartitionAroundMedoidsClustering(this,fillingRResults);
				    pam.doPAM(inputColumns,inputKeys,tempObject.parameterMapping["pamClusternumber"], tempObject.parameterMapping["pammetric"]);
					sendingAsyncCallCounter++;
				}
				
			}
		}
		
		/*----------------------------FILLING IN ALGORITHM RESULTS---------------------------------------------------------------------------*/
		
		private function fillingRResults(incomingRObject:IDataMiningResult):void
		{
			 keys = incomingRObject.keys;
			if(incomingRObject.identifier == "KMeansClustering")
			{
				var tempkMObject:KMeansClusteringResult = incomingRObject as KMeansClusteringResult;
				//to do: not only collect clustering vector but entire result
				DMResultObjects[tempkMObject.identifier] = tempkMObject.clusterVector;//collecting only the clustering vector
				clusterVectors.push(DMResultObjects[tempkMObject.identifier]);
				columnNames.push(tempkMObject.identifier);
				receivedAsyncCallCounter++;
				trace("got Kmeans!")
			}
			
			if(incomingRObject.identifier == "FuzzyKMeans")
			{
				var tempfKmObject:FuzzyKMeansClusteringResult = incomingRObject as FuzzyKMeansClusteringResult;
				//to do: not only collect clustering vector but entire result
				DMResultObjects[tempfKmObject.identifier] = tempfKmObject.clusteringVector;//collecting only the clustering vector 
				clusterVectors.push(DMResultObjects[tempfKmObject.identifier]);
				columnNames.push(tempfKmObject.identifier);
				receivedAsyncCallCounter++;
				
				trace("got FuzzyKMeans");
			}
			
			if(incomingRObject.identifier == "PamClustering")
			{
				var tempPamObject:PartitionAroundMedoidsClusteringResult = incomingRObject as PartitionAroundMedoidsClusteringResult;
				//to do: not only collect clustering vector but entire result
				DMResultObjects[tempPamObject.identifier] = tempPamObject.clusterVector;//collecting only the clustering vector
				clusterVectors.push(DMResultObjects[tempPamObject.identifier]);
				columnNames.push(tempPamObject.identifier);
				receivedAsyncCallCounter++;
				trace("got PAm");
			}
			
			// RESULTS  BEING FILLED
			if (sendingAsyncCallCounter == receivedAsyncCallCounter)
			{
				/*collectingArray is an array of arrays
				1. each array is one column returned by one clustering algo
				2. convert each array entry into a Numbercolumn
				3. collect these Numbercolumns in an array
				4. alter the array to reate final array
				/* This is the final array(clusterArray) added as a CSVDataSource having structure
				[
				["key","x", "y",  "z"]
				["k1",  1,   2,    3 ]
				["k2",  3,   4,    6]
				["k3",  2,   4,   56]
				] 
				5. use this final array to make CSV Datasource*/

				disposeObjects(finalColumnsGroup);
				finalColumnsGroup = newDisposableChild(this, CallbackCollection);
				for(var v:int = 0; v < clusterVectors.length; v++)
				{
					var tempColumn:NumberColumn = ResultUtils.resultAsNumberColumn(keys,clusterVectors[v],columnNames[v]);
					numberColumnsCollection.push(tempColumn);
					registerLinkableChild(finalColumnsGroup, tempColumn);
				}
				
				finalColumnsGroup.addImmediateCallback(this, checkifColumnsFilled);
				
			}
			
			
		}
		
		
		
		/*------------------------------------------MANAGING RESULTS AFTER BEING FILLED-----------------------------------------------------------*/
		private function checkifColumnsFilled():void 
				//to do figure out what to do with other data mining results which may not be columns
		{
				//do the next chunck of code only after the columns have been generated and collected
			if(WeaveAPI.SessionManager.linkableObjectIsBusy(finalColumnsGroup))
				return;
			
			var clusterArray:Array = new Array();
			
			//looping through each key
			for(var k:int = 0; k < keys.length; k++)
			{
				var _key:IQualifiedKey = keys[k] as IQualifiedKey;
				var tempArray:Array = new Array();
				for(var d:int = 0; d < numberColumnsCollection.length; d++)
				{
					var col:IAttributeColumn = numberColumnsCollection[d] as IAttributeColumn;
					var value:Number = col.getValueFromKey(_key,Number);
					tempArray.push(value);
				}
				
				tempArray.unshift(_key.localName);
				clusterArray.push(tempArray);
			}
			
			columnNames.unshift("Key");
			clusterArray.unshift(columnNames);
			
			var generatedClusterColumns:String = Weave.root.generateUniqueName("Clustering Results");
			var clusterResultCSVdata:CSVDataSource = Weave.root.requestObject(generatedClusterColumns,CSVDataSource,false);
			clusterResultCSVdata.setCSVData(clusterArray);
			clusterResultCSVdata.keyType.value = (keys[0] as IQualifiedKey).keyType;
			clusterResultCSVdata.keyColName.value = "Key";
				
		}
		
		
	}
}
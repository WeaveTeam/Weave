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
/**
 * Makes calls to R to carry out partition around medoids clustering
 * Takes columns as input
 * returns clustering object 
 * 
 * 
 * @spurushe
 * */

package weave.ui.DataMiningEditors
{
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.CSVColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.services.WeaveRServlet;
	import weave.services.addAsyncResponder;
	import weave.services.beans.PartitionAroundMedoidsClusteringResult;
	import weave.services.beans.RResult;
	import weave.utils.VectorUtils;

	public class PartitionAroundMedoidsClustering implements ILinkableObject
	{
		public const identifier:String = "PamClustering";
		private var algoCaller:Object;
		
		public const inputColumns:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		private var Rservice:WeaveRServlet = new WeaveRServlet(Weave.properties.rServiceURL.value);
		public var finalResult:PartitionAroundMedoidsClusteringResult;
			
		private var checkingIfFilled:Function;
	
		public function PartitionAroundMedoidsClustering(caller:Object, fillingFuzzKMeansResult:Function = null)
		{
				checkingIfFilled = fillingFuzzKMeansResult;
				this.algoCaller = caller;
		}
			
			
			//sends the columns to R to do partitioning around medoids clustering
		public function doPAM(_columns:Array,token:Array,_numberOfClusters:Number, _metric:String):void
		{
				var inputValues:Array = new Array();
				inputValues.push(_columns);
				inputValues.push(_numberOfClusters);
				inputValues.push(_metric);
				var inputNames: Array = ["inputColumns","clusterNumber","check"];
				
				
				var pamScript:String = "library(cluster)\n" +
					"frame <- data.frame(inputColumns)\n" +
					"pResult <- pam(frame, clusterNumber, metric = check)\n";
				var outputNames:Array = ["pResult$clustering"];
				
				
				var query:AsyncToken = Rservice.runScript(token,inputNames, inputValues,outputNames,pamScript,"",false, false, false);
				addAsyncResponder(query,handleRunScriptResult, handleRunScriptFault,token);
				
		}
			
		public function handleRunScriptResult(event:ResultEvent, token:Array = null):void
		{
				//Object to stored returned result - Which is array of object{name: , value: }
				var Robj:Array = event.result as Array;
				var clusterResult:Array = new Array();
				trace('Robj:',ObjectUtil.toString(Robj));
				if (Robj == null)
				{
					reportError("R Servlet did not return an Array of results as expected.");
					return;
				}
				
				
				var RresultArray:Array = new Array();
				//collecting Objects of type RResult(Should Match result object from Java side)
				for (var i:int = 0; i < (event.result).length; i++)
				{
					if (Robj[i] == null)
					{
						trace("WARNING! R Service returned null in results array at index "+i);
						continue;
					}
					var rResult:RResult = new RResult(Robj[i]);
					clusterResult.push(rResult.value);
				}
				
				RresultArray.push(Robj[0]);				
				
				if(algoCaller is DataMiningChannelToR)
				{
					finalResult = new PartitionAroundMedoidsClusteringResult(clusterResult,token);
					if(checkingIfFilled != null)
						checkingIfFilled(finalResult);
				}
				
				
				else 
				{
					
					//To make availabe for Weave -Mapping with key returned from Token
					var keys:Array = token as Array;
					
					//Objects "(object{name: , value:}" are mapped whose value length that equals Keys length
					for (var p:int = 0;p < RresultArray.length; p++)
					{
						
						if(RresultArray[p].value is Array){
							if(keys){
								if ((RresultArray[p].value).length == keys.length){
									if (RresultArray[p].value[0] is String)	{
										var testStringColumn:StringColumn = Weave.root.requestObject(RresultArray[p].name, StringColumn, false);
										var keyVec:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
										var dataVec:Vector.<String> = new Vector.<String>();
										VectorUtils.copy(keys, keyVec);
										VectorUtils.copy(Robj[p].value, dataVec);
										testStringColumn.setRecords(keyVec, dataVec);
										if (keys.length > 0)
											testStringColumn.metadata.@keyType = (keys[0] as IQualifiedKey).keyType;
										testStringColumn.metadata.@name = RresultArray[p].name;
									}
									else{
										var table:Array = [];
										for (var k:int = 0; k < keys.length; k++)
											table.push([ (keys[k] as IQualifiedKey).localName, Robj[p].value[k] ]);
										
										//testColumn are named after respective Objects Name (i.e) object{name: , value:}
										var testColumn:CSVColumn = Weave.root.requestObject(RresultArray[p].name, CSVColumn, false);
										testColumn.keyType.value = keys.length > 0 ? (keys[0] as IQualifiedKey).keyType : null;
										testColumn.numericMode.value = true;
										testColumn.data.setSessionState(table);
										testColumn.title.value = RresultArray[p].name;
									}
								}
							}						
						}										
					}
			    }
	    }
			
		public function handleRunScriptFault(event:FaultEvent, token:Object = null):void
		{
				trace(["fault", token, event.message].join('\n'));
				reportError(event);
		}
		
	}
}
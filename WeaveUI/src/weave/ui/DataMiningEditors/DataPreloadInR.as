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
 * Makes calls to R as soon as the data is loaded providing metrics important for analysis
 * 1) calculates statistics
 * 2) calculates column distributions
 * @spurushe
 * */package weave.ui.DataMiningEditors
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.DataGrid;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.reportError;
	import weave.core.LinkableHashMap;
	import weave.services.WeaveRServlet;
	import weave.services.addAsyncResponder;
	import weave.services.beans.RResult;
	import weave.utils.ColumnUtils;
	import weave.utils.ResultUtils;

	public class DataPreloadInR
	{
		[Bindable]
		public var distributionObjCanvasArray:Array = new Array();//collects all the canvases for all the columns (one canvas per column)
		private var statDataGrid:DataGrid = null;
		private var columnObjectCollection:ArrayCollection = new ArrayCollection();
		
		public var colNames:Array = new Array();//
		private var latestjoinedColumnKeys:Array = new Array();
		public var Rservice:WeaveRServlet = new WeaveRServlet(Weave.properties.rServiceURL.value);
		
		private static var dataPreloadInstance:DataPreloadInR = null;
		private var checkingIfFilled:Function; 
		
		public function DataPreloadInR(fillingResult:Function = null)
		{
			checkingIfFilled = fillingResult;
		}
		
		public static function getDataPreloadInRinstance(fillingResult:Function):DataPreloadInR
		{
			if(dataPreloadInstance == null)
				dataPreloadInstance = new DataPreloadInR(fillingResult);
			return dataPreloadInstance;
		}
		
		private function handleNormScriptResult(event:ResultEvent, token:Object = null):void
		{
			if (token != latestjoinedColumnKeys){return;}//handles two asynchronous calls made one after the other
			var _binnedColumns:Array = new Array();//collects the results for drawing distributions
			//Object to stored returned result - Which is array of object{name: , value: }
			var Robj:Array = event.result as Array;	
			var allStatRResults:Array = new Array();//collects the statistics objects
			
			if (Robj == null)
			{
				reportError("R Servlet did not return an Array of results as expected.");
				return;
			}
			
			//collecting Objects of type RResult(Should Match result object from Java side)
			for (var i:int = 0; i < (event.result).length; i++)
			{
				if (Robj[i] == null)
				{
					trace("WARNING! R Service returned null in results array at index "+i);
					continue;
				}
				var rResult:RResult = new RResult(Robj[i]);
				if(rResult.name == "finalResult")
					_binnedColumns = (rResult.value) as Array;
				else
					allStatRResults.push(rResult);
				//_binnedColumns = (rResult.value) as Array;
				
			}	
			
			//Once normalized and binned Columns are returned from R, draw the distribution and display the statistics
			/*drawingColumnDistribution(_binnedColumns);
			displayStatistics(allStatRResults);*/
			
			//testing
			var result:Array = new Array();
			result.push(_binnedColumns);
			result.push(allStatRResults);
			if(checkingIfFilled != null)
				checkingIfFilled(result);
			
		}
		
		public function drawingColumnDistribution(_binnedColumns:Array):Array
		{
			//x axis values are normalized between 0 and 1 (are multipled by factor to fit canvas size)
			//bar heights are normalized using the tallest bar
			distributionObjCanvasArray = [];
			//distrList.labelField = "label"; distrList.iconField = "icon";
			var allcolCounts:Array = _binnedColumns[0];//second elemet is the range split collection for all the columns
			var allcolBreaks:Array = _binnedColumns[1];//first element is the frequencies collection of all columns, hence hard coded
			
			// looping over columns
			for(var k:int = 0; k < allcolBreaks.length; k++)// allcolBreaks == allcolCounts (use whichever)
			{
				var distributionObj:Object = new Object();
				
				distributionObj["label"] = colNames[k];
				var can:Canvas = new Canvas();
				can.width= 100; 
				can.height = 100;
				can.graphics.clear();
				
				can.graphics.lineStyle(1,0x000000,0.75);
				
				var margin:Number = 20;
				var singleColCounts:Array = allcolCounts[k];//getting the counts for a single column
				var singleColbreaks:Array = allcolBreaks[k];// getting the breaks for a single column
				
				//drawing x- axis
				can.graphics.moveTo(margin, (can.height - margin));
				can.graphics.lineTo((can.width - margin), (can.height - margin));
				
				//ratio
				var scaleFactor:Number = can.height - (margin*2); //margin on the left and right hand side
				
				var maxColHeight:Number = Math.max.apply(null,singleColCounts);//getting the maximum height of the bars and normalizing the bar height
				
				var startPoint:Point = new Point(); 
				startPoint.x = 20; 
				startPoint.y = (can.height - margin);
				
				//drawing the distribution
				can.graphics.moveTo(startPoint.x, startPoint.y);
				
				//looping over the bins in each column
				for(var i :int = 0; i < singleColCounts.length; i++)
				{
					var endP:Point = new Point();
					var middleP:Point = new Point();
					var middleP2:Point = new Point();
					
					var normBarHeight:Number = singleColCounts[i]/maxColHeight;//gives a value between 0 and 1
					//range between two succesiive bins
					var range: Number = singleColbreaks[i+1] - singleColbreaks[i];
					middleP.x = startPoint.x ; middleP.y =  startPoint.y - (normBarHeight * scaleFactor);
					middleP2.x = middleP.x + (range * scaleFactor); middleP2.y = middleP.y;
					endP.x = middleP2.x; endP.y = startPoint.y ;
					
					
					can.graphics.lineTo(middleP.x,  middleP.y);
					can.graphics.lineTo(middleP2.x, middleP2.y);
					can.graphics.lineTo(endP.x, endP.y);
					
					startPoint = endP;
					can.graphics.moveTo(startPoint.x, startPoint.y);
					
				} 
				
				
				distributionObj["icon"] = can;
				distributionObjCanvasArray[k] = distributionObj;//pushing the respective distribution of the column
			}
			
			return distributionObjCanvasArray;
			
		}
		
		
		public function displayStatistics(allStatRResults:Array):DataGrid
		{
			if(statDataGrid == null)
			{
				statDataGrid = new DataGrid();
				statDataGrid.percentWidth = 100;
				statDataGrid.percentHeight = 100; 
			}
			
			statDataGrid.initialize();
			
			columnObjectCollection.removeAll();
			statDataGrid.dataProvider = columnObjectCollection;
			for (var k:int = 0; k < allStatRResults.length; k++)
			{
				var columnObject:Object = new Object(); 
				//TO:DO find a better way of looping through arrays and assign properties without hardcoding
				var valueArray:Array = ((allStatRResults[k] as RResult).value) as Array
				columnObject.Column = colNames[k];
				columnObject.ColumnMaximum = valueArray[0];
				columnObject.ColumnMinimum = valueArray[1];
				columnObject.ColumnAverage = valueArray[2];
				columnObject.ColumnVariance = valueArray[3];
				
				columnObjectCollection.addItem(columnObject);
			}
			
			//statisticsBox.addChild(statDataGrid);
			
			return statDataGrid;
		}
		
		private function handleRunScriptFault(event:FaultEvent, token:Object = null):void
		{
			trace(["fault", token, event.message].join('\n'));
			reportError((event));
		}
		
		public function doSampling(_sampleSize:int): void
		{
			
		}
		
		public function collectNumbericalColumns(variables:LinkableHashMap): Array
		{
			var selectedColumns:Array = variables.getObjects(); //Columns from ColumnListComponent 
			var _attributeColumns:Array = [];
			for (var f:int = 0; f < selectedColumns.length; f++)
			{
				var _col:IAttributeColumn = selectedColumns[f];
				var dataType:String = ColumnUtils.getDataType(_col);
				
				
				if(dataType == "number")//screening only numeric columns for normalization
				{
					colNames.push(ColumnUtils.getTitle(_col  as IAttributeColumn));
					_attributeColumns.push( _col as IAttributeColumn);
				}
				
			}
			
			return _attributeColumns;
			
		}
		
		//this function sneds the dataset to R, where the data is normalized, binned and statistics of each numerical column are calculated
		public function normaBinAndStatR(variables:LinkableHashMap):void 
		{
			var selectedColumns:Array = variables.getObjects(); //Columns from ColumnListComponent 
			if(selectedColumns.length == 0)//handles the case when all columns are removed form the columnListComponent
			{
				distributionObjCanvasArray = [];
				columnObjectCollection.removeAll();
			}
			//clear for every call
			var _attributeColumns:Array = [];
			colNames = [];
			for (var f:int = 0; f < selectedColumns.length; f++)
			{
				var _col:IAttributeColumn = selectedColumns[f];
				var dataType:String = ColumnUtils.getDataType(_col);
				
				
				if(dataType == "number")//screening only numeric columns for normalization
				{
					colNames.push(ColumnUtils.getTitle(_col  as IAttributeColumn));
					_attributeColumns.push( _col as IAttributeColumn);
				}
				
			}
			//columns sent as a matrix, all at one time
			var inputValues:Array = new Array(); var inputNames:Array =  ["myMatrix"];
			var normScript:String = " frame <- data.frame(myMatrix)\n" +
				"normandBin <- function(frame)\n" +  
				"structure(list(counts = getCounts(frame), breaks = getBreaks(frame)), class = \"normandBin\");\n"+
				"getNorm <- function(frame){\n" +				
				"myRows <- nrow(frame)\n" +
				"myColumns <- ncol(frame)\n" +
				"for (z in 1:myColumns ){\n" +
				"maxr <- max(frame[z])\n" +
				"minr <- min(frame[z])\n" +
				"for(i in 1:myRows ){\n" +
				"frame[i,z] <- (frame[i,z] - minr) / (maxr - minr)\n" +
				" }\n" +
				"}\n" +
				"return(frame)\n" +
				"}\n" +
				"getCounts <- function(normFrame){\n" +
				"normFrame <- getNorm(frame)\n" +
				"c <- ncol(normFrame)\n" +
				"histoInfo <- list()\n" +
				"answerCounts <- list()\n" +
				"for( s in 1:c){\n" + 
				"histoInfo[[s]] <- hist(normFrame[[s]], plot = FALSE)\n" + 
				"answerCounts[[s]] <- histoInfo[[s]]$counts\n" +
				"}\n" +
				"return(answerCounts)\n" +
				"}\n" +
				"getBreaks <- function(frame){\n" +
				"normFrame <- getNorm(frame)\n" +
				" c <- ncol(normFrame)\n" +
				"histoInfo <- list()\n" +
				"answerBreaks <- list()\n" +
				"for( i in 1:c){\n" +
				"histoInfo[[i]] <- hist(normFrame[[i]], plot = FALSE)\n" +
				"answerBreaks[[i]] <- histoInfo[[i]]$breaks\n" +
				"}\n" +
				"return(answerBreaks)\n" +
				"}\n" +
				"finalResult <- normandBin(frame)\n" +
				"lappend <- function(lst, stat, name) {\n" +
				"lst[name] <- stat\n" +
				"return(lst)}\n" +
				"getAllColumnStats <- function(myMatrix){\n" +
				"allColumnStats <- list()\n" +
				"oneColumnStat <- list()\n" +
				"answer <- list()\n" +
				"columnName <- \"\"\n" +
				"stgOne <- \"ColumnMaximum\"\n" +
				"stgTwo <- \"ColumnMinimum\"\n" +
				"stgThree <- \"ColumnMean\"\n" +
				"stgFour <- \"ColumnVariance\"\n" +
				"for( i in 1:length(myMatrix)){\n" +
				"columName <- \"\"\n" +
				"answer <- lappend(answer, colMax <- max(myMatrix[[i]]), stgOne)\n" +
				"answer <- lappend(answer, colMin <- min(myMatrix[[i]]), stgTwo)\n" +
				"answer <- lappend(answer, colMean <- mean(myMatrix[[i]]), stgThree)\n" +
				"answer <- lappend(answer, colVariance <- var(myMatrix[[i]]), stgFour)\n" +
				"columnName <- sprintf(\"Column%.0f\",i)\n" +
				"oneColumnStat <- list(answer)\n" +
				"allColumnStats[columnName] <- oneColumnStat\n" +
				"}\n" +
				"return(allColumnStats)\n" +
				"}\n" +
				"finalStatResult <- getAllColumnStats(frame)\n";;
			
			var result:Array = ResultUtils.joinColumns(_attributeColumns);
		    var joinedColumns:Array ;
			latestjoinedColumnKeys = result[0];
			joinedColumns = result[1];
			
			if ( latestjoinedColumnKeys.length != 0)
			{
				inputValues.push(joinedColumns); 
				var outputNames:Array = new Array();
				for( var s:int = 1 ; s <=  _attributeColumns.length; s++)
				{
					outputNames.push("finalStatResult$Column" +[s]);
				} 
				outputNames.push("finalResult");
				var query:AsyncToken = Rservice.runScript(null,inputNames,inputValues,outputNames,normScript,"",false,false,false);
				addAsyncResponder(query, handleNormScriptResult, handleRunScriptFault,latestjoinedColumnKeys);
			}
		}
	}
}
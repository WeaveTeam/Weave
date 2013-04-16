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


package disabilityPack
{
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.reportError;
	import weave.editors.Disability;
	import weave.services.WeaveRServlet;
	import weave.services.beans.RResult;
	
	/** 
	 * @mervetuccar
	 */
	
	public class SegmentValue
	{
		
		
		public var Segment:Array; 
		public var corr:Number;
		public var fTests:Array;
		public var percentageTotal:Number;
		public var diffAM:Number;
		public var currSegNum:Number;
		public var totalNumber:Number;
		public var actualRunsNum:Number;
		public var outlier:Boolean;
		public var runsTestB:Boolean;
		public var dataX:Array;
		public var segmentIndices:Array;
		public var mDisability:Disability;
		
		private var fDecisionCount:int = 0;
		
		public var Rservice:WeaveRServlet;	
		import weave.services.DelayedAsyncInvocation;
		import weave.services.DelayedAsyncResponder;
		
		private var RdecisionScript:String ="segment <- identity(dataY)\n" +	
			"corr <- cor(dataX, dataY)\n" +											
			"fit <- lm(dataY~dataX)\n"+
			"intercept <- coefficients(fit)[1]\n"+
			"slope <- coefficients(fit)[2]\n"+
			//"rSquared <- summary(fit)$r.squared\n"+
			"grubbs <- outliers::grubbs.test(dataY, type = 10)\n";
		
		private var FdecisionScript:String ="ftest <- var.test(dataX1, dataY1, conf.level=0.05)\n";	
		
		
		public var intercept:Number;
		public var slope:Number;
		
		
		public function SegmentValue()
		{
			dataX = new Array();
			actualRunsNum = 0;
			fTests = new Array();
			Rservice= new WeaveRServlet(Weave.properties.rServiceURL.value);	
			segmentIndices = new Array();
		}
		
		public function setSegment(msegment:Array):void
		{
			Segment = msegment;
			dataX = null;
			dataX = new Array();
			for (var i:int = segmentIndices[0]; i<segmentIndices[1]; i++)
			{
				dataX.push(i);
			}		
		}
		
		
		public function getValues():void
		{
			var query:AsyncToken;
			
			if(segmentIndices[0] == segmentIndices[1])
				return;
			
			if( Segment.length < 3)
			{			
				mDisability.splittedSegments.push(segmentIndices);
				mDisability.splitComplete();
				return;
			}
			query = Rservice.runScript(null,["dataX", "dataY"], [dataX, Segment], ["segment","corr", "intercept", "slope", "grubbs"], RdecisionScript, "", false, true, false);
			DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
		}
		
		public function split():void
		{
			getValues();
			
		}
		
		private function handleRScript(event:ResultEvent, token:Object):void
		{
			//trace ("aaa");
			if(segmentIndices[0] == 0 && segmentIndices[1] == 3)
			{
				//trace("asddf");
			}
			var query:AsyncToken;
			var Robj:Array = event.result as Array;
			var RresultArray:Array = new Array();
			var grubbs:Array = new Array();
			var dataY1:Array = new Array();
			var dataY2:Array = new Array();
			var dataX1:Array = new Array();
			var dataX2:Array = new Array();
			var tmpSeg:Array = new Array();
			//collecting Objects of type RResult(Should Match result object from Java side)
			for(var i:int = 0; i<Robj.length; i++)
			{
				var rResult:RResult = new RResult(Robj[i]);
				RresultArray.push(rResult);				
			}
			if(((RresultArray[0] as RResult).name as String) == "Error Statement state")
			{
				reportError("Rscript returned NULL");
				return;
			}
			
			tmpSeg = (RresultArray[0] as RResult).value as Array;
			corr = Number((RresultArray[1] as RResult).value);
			intercept = (RresultArray[2] as RResult).value as Number;
			slope = (RresultArray[3] as RResult).value as Number;
			grubbs = (RresultArray[4] as RResult).value as Array;
			
			//trace("r squared " +rSquared);
			if(grubbs != null)
			{
				if(grubbs[0]>grubbs[1])	 
					outlier = true; /*there is an outlier */
					
				else 
					outlier = false;
			}
			else
				outlier = false;
			
			
			
			percentageTotal = Segment.length / Disability.firstSegLength;
			
			if(Segment.length <= 3)
			{
				
				mDisability.splittedSegments.push(segmentIndices);
				mDisability.splitComplete();
				return;
			}
			var entered:Boolean = false;
			for(var j:int=2; j<Segment.length - 1; j++)
			{
				entered = true;
				dataX1 = new Array();
				dataX2 = new Array();
				dataY1 = (Segment.slice(0,j));
				
				//trace(dataY1.length);
				for(var k:int = 0; k < dataY1.length ; k++)
				{
					dataX1.push(k);
				}
				
				k= 0;
				dataY2 = (Segment.slice(j, Segment.length));
				for(k = 0; k < dataY2.length ; k++)
				{
					dataX2.push(k);
				}
				
				query = Rservice.runScript(null,["dataX1", "dataY1"], [dataX1, dataY1], ["ftest"], FdecisionScript, "", false, false, false);
				DelayedAsyncResponder.addResponder(query, handleFtestScript, handleRunScriptFault, null);
				
				query = Rservice.runScript(null,["dataX1", "dataY1"], [dataX2, dataY2],["ftest"], FdecisionScript, "", false, false, false);
				DelayedAsyncResponder.addResponder(query, handleFtestScript, handleRunScriptFault, null);
				fDecisionCount+=2;
			}
			if(entered == false)
			{
				trace("no enter");
			}
		}
		
		private function handleRunScriptFault(event:FaultEvent, token:Object):void
		{
			//trace(["fault", token, event.message].join("\n"));
			reportError(event);
		}
		
		public function handleFtestScript(event:ResultEvent, token:Object):void
		{
			var Robj:Array = event.result as Array;
			var RresultArray:Array = new Array();
			
			//collecting Objects of type RResult(Should Match result object from Java side)
			for(var i:int = 0; i<Robj.length; i++)
			{
				var rResult:RResult = new RResult(Robj[i]);
				RresultArray.push(rResult);				
			}
			
			var ftest:Array = (RresultArray[0] as RResult).value as Array;
			if(ftest[0] > ftest[2])
				fTests.push(true);
			else
				fTests.push(false);
			
			fDecisionCount--
			if(fDecisionCount == 0)
			{
				// ftest hesaplama
				
				mDisability.split(this);
				
			}
		}
		
	}
}
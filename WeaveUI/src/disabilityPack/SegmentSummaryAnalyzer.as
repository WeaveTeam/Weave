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
	
	public class SegmentSummaryAnalyzer
	{
		import weave.services.DelayedAsyncInvocation;
		import weave.services.DelayedAsyncResponder;
		
		private var query:AsyncToken;
		public var Rservice:WeaveRServlet;
		public var sumSegments:Array = new Array();
		public var curRegModelToCompare:int = 0;
		public var curSumSegmentIndex:int = 0;
		
		public var RegressionmodelTypes:Array = new Array("Linear","NegativeLinear" , "Logarithmic", "NegativeLogarithmic","Polynomial" , "NegativePolyomial", "Exponential", "NegativeExponential", "BellyCurve","NegativeBellyCurve", "Stable");
		public var mRegressionModels:Array = new Array();
		public var mDisability:Disability;
		public var _RScript:String = "ftest <- var.test(dataX1, dataY1, conf.level=0.05)\n"+
									 "index <- identity(mIndex)\n";
		
		public function SegmentSummaryAnalyzer()
		{
			
			for(var i:int = 0 ; i < RegressionmodelTypes.length ; i++)
			{
				var tmpModel:RegressionModels = new RegressionModels(RegressionmodelTypes[i]);
				mRegressionModels.push(tmpModel);
				
			}
			
		}
		
		public function addSegmentSummary(sum:SummarySegment):void
		{
			sumSegments.push(sum);
			
		}
		
		public function getSummarySegments():Array
		{
			return sumSegments;
		}
		
		public function Analayse():void
		{
			Rservice= new WeaveRServlet(Weave.properties.rServiceURL.value);
			
			query = Rservice.runScript(null,["dataX1", "dataY1", "mIndex"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues, sumSegments[curSumSegmentIndex].getIndex()],["ftest", "index"], _RScript, "", false, false, false);
			DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
		}
		
		private function handleRScript(event:ResultEvent, token:Object):void
		{
		//	trace(curSumSegmentIndex + "  " + curRegModelToCompare);
		//	trace(sumSegments.length + " regres " + mRegressionModels.length);
			var Robj:Array = event.result as Array;
			var RresultArray:Array = new Array();
			
			//collecting Objects of type RResult(Should Match result object from Java side)
			for(var i:int = 0; i<Robj.length; i++)
			{
				var rResult:RResult = new RResult(Robj[i]);
				RresultArray.push(rResult);				
			}
			
			var ftest:Array = (RresultArray[0] as RResult).value as Array;
			var mIndex:int = Number((RresultArray[1] as RResult).value);
	

			if(ftest != null)
			{
				if(ftest[0] > ftest[2])
				{
					sumSegments[curSumSegmentIndex].setAnalysis(RegressionmodelTypes[curRegModelToCompare]);
					curRegModelToCompare = 0;
				//	trace(sumSegments[curSumSegmentIndex].getIndex() + "     " + mIndex);
					curSumSegmentIndex++;
					
					if(curSumSegmentIndex < sumSegments.length)
					{
						//trace("gitti " + sumSegments[curSumSegmentIndex].getIndex());
						query =  Rservice.runScript(null,["dataX1", "dataY1", "mIndex"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues, sumSegments[curSumSegmentIndex].getIndex()],["ftest", "index"], _RScript, "", false, false, false);
						DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
					}
					
					
				}
					
				else
				{
				//	trace("just compared " +  RegressionmodelTypes[curRegModelToCompare]);
					curRegModelToCompare++; // next reg model
					if(curRegModelToCompare < mRegressionModels.length)
					{
						//trace("gitti " + mIndex);
						query =  Rservice.runScript(null,["dataX1", "dataY1", "mIndex"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues, mIndex],["ftest", "index"], _RScript, "", false, false, false);
						DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
					}
					else
					{
				//		trace("3");
						curRegModelToCompare = 0;
						curSumSegmentIndex++; // next segment
						if(curSumSegmentIndex < sumSegments.length)
						{
						//	trace("gitti " + sumSegments[curSumSegmentIndex].getIndex());
							query =  Rservice.runScript(null,["dataX1", "dataY1", "mIndex"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues, sumSegments[curSumSegmentIndex].getIndex()],["ftest", "index"], _RScript, "", false, false, false);
							DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
						}			
					}
				}
			}
			else
			{
				
				curRegModelToCompare++; // next reg model
				if(curRegModelToCompare < mRegressionModels.length)
				{
					//trace("gitti " + mIndex);
					query =  Rservice.runScript(null,["dataX1", "dataY1", "mIndex"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues, mIndex],["ftest", "index"], _RScript, "", false, false, false);
					DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
				}
				else
				{
					curRegModelToCompare = 0;
					
					curSumSegmentIndex++; // next segment
					if(curSumSegmentIndex < sumSegments.length)
					{
					//	trace("gitti " + sumSegments[curSumSegmentIndex].getIndex());
						query =  Rservice.runScript(null,["dataX1", "dataY1", "mIndex"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues, sumSegments[curSumSegmentIndex].getIndex()],["ftest", "index"], _RScript, "", false, false, false);
						DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
					}			
				}
				
			}
			/*curRegModelToCompare++;
			if(curRegModelToCompare < mRegressionModels.length)
			{
				query = Rservice.runScript(null,["dataX1", "dataY1"], [sumSegments[curSumSegmentIndex].getDataValues(), mRegressionModels[curRegModelToCompare].dataValues],["ftest"], _RScript, "", false, false, false);
				DelayedAsyncResponder.addResponder(query, handleRScript, handleRunScriptFault, null);
			}*/
			if(curSumSegmentIndex == sumSegments.length)
			{
				mDisability.registerMultipleSegmentAnalysis();
			}
			
			
		}
		
		private function handleRunScriptFault(event:FaultEvent, token:Object):void
		{
			//trace(["fault", token, event.message].join("\n"));
			reportError(event);
		}
		
	}
}
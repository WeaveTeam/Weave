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
	import weave.api.core.ILinkableObject;
//	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.editors.Disability;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveRServlet;
	import weave.services.beans.RResult;
	
	public class LineChartDecisionTree
	{
		public function LineChartDecisionTree()
		{ 			
			//constructor
		}
		
		public function lineChartDT():Boolean
		{
			// 1=true=split 0=false=no split
			
			if(correlationCoefficient()>0.815541)
			{
				if(percentageOfTotalPoints() <= 0.62963)
				{
					return false;
				}
				else
				{
					if(correlationCoefficient() > 0.962782)
					{
						return false;
					}
					else
					{
						if(fTest() == true)
						{
							if(differenceBetweenActualRunsandMeanRuns() <= 0.052632) 
							{
								return true;
							}
							else
							{
								if(percentageOfTotalPoints() <= 0.894737)
								{
									if(totalNumberOfPoints() <= 10)
									{
										return true;
									}
									else
									{
										return false;
									}
								}
								else
								{
									if(differenceBetweenActualRunsandMeanRuns() <= 0.480712)
									{
										return false;
										
									}
									else
									{
										return true;
									}
								}
								
							}
						}
						else // Ftest = 1 = false
						{
							if(percentageOfTotalPoints() > 0.866667)
							{
								return true;
							}
							else
							{
								if(totalNumberOfPoints() <= 14)
								{
									return false;
								}
								else//totalNumberofPoints
								{
									if(actualRuns() <= 4)
									{
										return true;
									}
									else
									{
										return false;
									}
								}
							}
						}
					}
				}
			} 
			// 1=true=split 0=false=no split
			else // correlationCoeffiicent, main one
			{
				if(percentageOfTotalPoints() > 0.894737)
				{
					return true;
				}
				else
				{
					if(runsTest() == true)
					{
						return true;
					}
					else
					{
						if(fTest() == true)
						{
							return true;
						}
						else
						{
							if(percentageOfTotalPoints() <= 0.392857)
							{
								if(actualRuns() > 5)
								{
									return false;
								}
								else
								{
									if(numberOfPointsinCurrentSegment() <=5 )
									{
										return false;
									}
									else
									{
										if(correlationCoefficient() <= 0.538139)
										{
											return true;
										}
										else
										{
											return false;
										}
									}
				
									
								}
							}
							else //percentage of total points > 0.392857
							{
								if(outlierDetection() == true)
								{
									return true;
								}
								
								else
								{
									if(totalNumberOfPoints() > 18)
									{
										return false;
									}
									else
									{
										if(correlationCoefficient() > 0.725035)
										{
											return false;
										}
										else
										{
											if(differenceBetweenActualRunsandMeanRuns() <= 0.215768)
											{
												return true;
											}
											else
											{
												if(totalNumberOfPoints() <= 17)
												{
													return false;
												}
												else
												{
													return true;
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		 
/*		private var rService:WeaveRServlet = null;
		private var dtDisability:Disability = new Disability();
		
		private function resetRService():void
		{
		rService = new WeaveRServlet(Weave.properties.rServiceURL.value);
		}
		
		private function Rcalculations():void
		{
		var computeCorrelationCoeff:String = "coefficient <- cor(var1, var2)";
		var inputValues:Array = new Array();
		
		for (var i:int = 0; i<dtDisability.joinColsRArray.length; i++)
		{
		inputValues.push(dtDisability.joinColsRArray[i][0].valueOf());
		//reportError(joinColsRArray);
		}
		
		var query:AsyncToken = rService.runScript(dtDisability.joinKeysRArray,["var1","var2"],inputValues,["coefficient"],computeCorrelationCoeff,"",false,false,false);
		DelayedAsyncResponder.addResponder(query, handleRResult, handleRFault, dtDisability.joinKeysRArray)
		}
		private function handleRResult(event:ResultEvent, token:Object=null):void
		{
		var Robj:Array = event.result as Array;
		if (Robj == null)
		reportError("R Servlet did not return an Array of results as expected.");
		return;
		
		var RresultArray:Array = new Array();
		
		//collecting Objects of type RResult(Should Match result object from Java side)
		for(var i:int = 0; i<Robj.length; i++)
		{
		var rResult:RResult = new RResult(Robj[i]);
		RresultArray.push(rResult);               
		}
		if (RresultArray.length > 1)
		{
		corrCoefficient = Number((RresultArray[0] as RResult).value);           
		//    getCallbackCollection(this).triggerCallbacks();
		}
		
		}
		
		private var corrCoefficient:Number = new Number();
		
		private function handleRFault(event:FaultEvent, token:Object = null):void
		{
		trace(["fault", token, event.message].join("\n"));
		//corrCoefficient = NaN;
		reportError(event);
		}
		*/
		
		public function totalNumberOfPoints():Number {	return 5;}
		
		public function numberOfPointsinCurrentSegment():Number {		return 5;	}
		
		public function correlationCoefficient():Number {return 0.82;}
		
		public function percentageOfTotalPoints():Number {return 0.62;}
		
		public function fTest():Boolean {return false;}
		
		public function changingPointsFtest():Number {return 5;}
		
		public function runsTest():Boolean {	return false;	}
		public function actualRuns():Number {	return 5;}
		
		public function meanRuns():Number {	var runsMean:Number = new Number(); 	return runsMean; }
	    public function standardDevOfRuns():Number
		{
			
			var sdRunsTest:Number = new Number();
			return sdRunsTest;
		}
		
		public function differenceBetweenActualRunsandMeanRuns():Number
		{
			// (r-rmean)/rmean
			return 5;
		}
		public function outlierDetection():Boolean {	return false;	}
		
		public function numberOfOutliers():Number
		{
			//the num of standardized residuals ri, which are greater than the critiical value
			return 5;
		}
	
	
	
   }
}
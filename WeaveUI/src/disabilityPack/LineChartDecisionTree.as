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
	import flash.display.JointStyle;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableHashMap;
	import weave.data.KeySets.KeySet;
	import weave.editors.Disability;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveRServlet;
	import weave.services.beans.RResult;
	import weave.utils.ColumnUtils;

	/**
	 * @author mervetuccar
	 **/
	
	public class LineChartDecisionTree
	{
		private var InitialSegmentLength:int;
		
		
		public function setSegmentLength(length:int):void
		{
			InitialSegmentLength = length;
		}
		
		public function LineChartDecisionTree()
		{ 			
			//constructor
		}
		
		public function lineChartDT(segment:Array, corr:Number, fTests:Array, percentageTotal:Number, diffAM:Number, currSegNum:Number, totalNumber:Number, actualRunsNum:Number, outlier:Boolean, runsTestB:Boolean):Boolean
		{
			// 1=true=split 0=false=no split
			
			if(corr>0.815541)
			{
				if(percentageTotal <= 0.62963)
				{
					return false;
				}
				else
				{
					if(corr > 0.962782)
					{
						return false;
					}
					else
					{
						if(fTest(fTests) == true)
						{
							if(diffAM <= 0.052632) 
							{
								return true;
							}
							else
							{
								if(percentageTotal <= 0.894737)
								{
									if(totalNumber <= 10)
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
									if(diffAM <= 0.480712)
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
							if(percentageTotal > 0.866667)
							{
								return true;
							}
							else
							{
								if(totalNumber <= 14)
								{
									return false;
								}
								else//totalNumberofPoints
								{
									if(actualRunsNum <= 4)
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
				if(percentageTotal > 0.894737)
				{
					return true;
				}
				else
				{
					if(runsTestB == true)
					{
						return true;
					}
					else
					{
						if(fTest(fTests) == true)
						{
							return true;
						}
						else
						{
							if(percentageTotal <= 0.392857)
							{
								if(actualRunsNum > 5)
								{
									return false;
								}
								else
								{
									if(currSegNum <=5 )
									{
										return false;
									}
									else
									{
										if(corr <= 0.538139)
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
								if(outlier == true)
								{
									return true;
								}
								
								else
								{
									if(totalNumber > 18)
									{
										return false;
									}
									else
									{
										if(corr > 0.725035)
										{
											return false;
										}
										else
										{
											if(diffAM <= 0.215768)
											{
												return true;
											}
											else
											{
												if(totalNumber <= 17)
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
		
	

		
		

    	
		
		private var keysArray:Array = new Array;
		public function getJoinKeysArray(joinKeysArray:Array):void
		{
			keysArray.push(joinKeysArray);
		}
		
		
	

		private var corrCoefficient:Number = new Number();
		
		private function handleRFault(event:FaultEvent, token:Object = null):void
		{
			
		trace("fault");
		trace(["fault", token, event.message].join("\n"));
		//corrCoefficient = NaN;
		reportError(event);
		}
		
		
	//	public function totalNumber:Number { 	return InitialSegmentLength;  }
		
	//	public function currSegNum(segment:Array):Number {	return segment.length;	}
		
		public function correlationCoefficient(segment:Array):Number
		{
			
			return 0.80;
		}
		
	//	public function percentageTotal:Number {return 0.92;}
		
		public function fTest(fTests:Array):Boolean {return false;}
		
		public function changingPointsFtest():Number {return 5;}
		
		//public function runsTestB:Boolean { return false; }
		
	//	public function actualRunsNum:Number {return 5;}
		
		public function meanRuns(runsMeanValue:Number):Number {return runsMeanValue;}
	    public function standardDevOfRuns():Number
		{
			
			var sdRunsTest:Number = new Number();
			return sdRunsTest;
		}
		/*
		public function diffAM:Number
		{
			// (r-rmean)/rmean
			return 5;
		}*/
	//	public function outlier:Boolean {	return false;	}
		
		public function numberOfOutliers():Number
		{
			//the num of standardized residuals ri, which are greater than the critiical value
			return 5;
		}
	
	
	
   }
}
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
		
		
		public function totalNumberOfPoints():Number
		{
			return 5;
		}
		
		public function numberOfPointsinCurrentSegment():Number
		{
			return 5;
		}
		public function correlationCoefficient():Number
		{ 
			return 0.82;
		}
		public function percentageOfTotalPoints():Number
		{
			return 0.62;
		}
		public function fTest():Boolean
		{
			return false;
			
		}
		public function changingPointsFtest():Number
		{
			return 5;
		}
		public function runsTest():Boolean
		{
			return false;	
		}
		public function actualRuns():Number
		{
			return 5;
		
		}
		
		public function meanRuns():Number
		{
			var runsMean:Number = new Number();
			return runsMean;
		}
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
		public function outlierDetection():Boolean
		{
			return false;
			
		}
		
		public function numberOfOutliers():Number
		{
			//the num of standardized residuals ri, which are greater than the critiical value
			return 5;
		}
	
	
	
   }
}
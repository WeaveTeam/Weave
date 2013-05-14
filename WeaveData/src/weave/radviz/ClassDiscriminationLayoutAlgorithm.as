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

package weave.radviz
{
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.ColumnUtils;
	import weave.utils.RadVizUtils;
	
	/**
	 * An implementation of the Class Discrimination Layout dimensional ordering algorithm.
	 * This algorithm groups dimensions according to the Classes found in the initial Column selected for class determination
	 * @author spurushe 
	 */	
	public class ClassDiscriminationLayoutAlgorithm extends AbstractLayoutAlgorithm implements ILayoutAlgorithm
	{

		public var tandpValuesMapping:Dictionary;//stores the column values belonging to a particular class{key = classname value = array of column values belonging to this class}
		//  String -> Array <of LinkableHashMap object names>
		public var tAndpMapping:Dictionary;//stores the columns belonging to a particular class{key = classname value = array of columns belonging to this class}

		public var ClassToColumnMap:Dictionary;
		/** structure of ClassToColumnMap (Bins)
		 for example :    type                        				Array
		 ClassToColumnMap[japanese]      			   			 Object 1
																 ColumnName1     values in Column1
		 														 ColumnName2		       Column2
		 														 ColumnName3		       Column3
		 
		 ClassToColumnMap[american]          					 Object 2
		 														 ColumnName1     values in Column1
																 ColumnName2		       Column2
																 ColumnName3		       Column3  
		 */
		
		
		
		/** This function determines the classes and  populates the Dictionary called ClassToColumnMap which is used for the Class Discrimination Layout Algorithm
		 can be used when the discriminator class is of a categorical nature  */
		public function fillingClassToColumnMap(selectedColumn:DynamicColumn,colObjects:Array, columnNames:Array, normalizedColumns:Array):void
		{
			ClassToColumnMap = new Dictionary();//create a new one for every different column selected
			
			var attrType:String = ColumnUtils.getDataType(selectedColumn);// check if column has numercial or categorical values 
			if(attrType == "string")
			{ 
				//Step 2 Looping thru the keys in the found column and populating the type dictionary
				for(var g:int = 0; g < selectedColumn.keys.length; g++)
				{
					var mkey:IQualifiedKey = selectedColumn.keys[g] as IQualifiedKey;
					
					var type:Object = selectedColumn.getValueFromKey(mkey,String);//"japanese", "american" etc
					
					
					if(!ClassToColumnMap.hasOwnProperty(type))// && !tAndpMapping.hasOwnProperty(type))
					{
						ClassToColumnMap[type] = new ClassInfoObject();
						//tAndpMapping[type] = new Array();
						
					}
					
					var infoObject:ClassInfoObject = ClassToColumnMap[type];
					for (var f:int = 0; f < colObjects.length; f ++)//filling in the type columnMapping with arrays
					{
						if(!infoObject.columnMapping.hasOwnProperty(columnNames[f]))							 
							
							infoObject.columnMapping[columnNames[f]] = new Array();
					}
					
					for(var b:int = 0; b < normalizedColumns.length; b++)
					{
						var tempEntry:Number = (normalizedColumns[b] as IAttributeColumn).getValueFromKey(mkey,Number);
						var zz:Array = infoObject.columnMapping[columnNames[b]] as Array ;
						zz.push(tempEntry);
					}
					
				}//ClassToColumnMap gets filled 
				
			}
			
		}
		
		
		public function ClassDiscriminationLayoutAlgorithm()
		{
			super();
		}				
		
		
		
		/**This function segregates the columns into classes using the statistical measure (t-statistic in this case) */
		public function performClassDiscrimination(columnNames:Array,ClassToColumnMap:Dictionary, layoutMeasure:String, thresholdValue:Number, columnNumPerClass:Number):Dictionary
		{
			tAndpMapping = new Dictionary();//maps column names
			tandpValuesMapping = new Dictionary();//maps column values
			for (var r:int = 0 ; r < columnNames.length; r++)//for each column loop through the classes
			{
				
				var firstLoop:Boolean = true;
				var tempType:Object;
				var compareNum:Number;
				
				for (var type:Object in ClassToColumnMap)
				{ 
					
					if(!tAndpMapping.hasOwnProperty(type))
					{
						tAndpMapping[type] = new Array();
						tandpValuesMapping[type+"metricvalues"] = new Array();
					}
					
					if(layoutMeasure == "PVal")//only if pvalue is selected
					{
						var tempPValue:Number = (ClassToColumnMap[type] as ClassInfoObject).pValuesArray[r];
						if(isNaN(thresholdValue))// if threshold has not been specified
						{
							
							if(firstLoop)
							{
								firstLoop = false;
								compareNum = (ClassToColumnMap[type] as ClassInfoObject).pValuesArray[r];
								tempType = type;
								
							}
								
							else
							{
								if(compareNum < tempPValue)
								{
									tempType = type;
									compareNum = tempPValue;
									
								}
							}
							
						}
						
						if(isNaN(thresholdValue) == false)//if threshold is specified
						{
							if (tempPValue > thresholdValue)
							{
								if(firstLoop)
								{
									firstLoop = false;
									compareNum = (ClassToColumnMap[type]as ClassInfoObject).pValuesArray[r];
									tempType = type;
								}
								else
								{
									if(compareNum < tempPValue)
									{
										compareNum = tempPValue;
										tempType = type;
									}
									
								}
							}
						}
					}
					
					else// as default and if tstatistic is chosen as a measure 
					{
						var tempTValue:Number = (ClassToColumnMap[type] as ClassInfoObject).tStatisticArray[r];
													
						if(firstLoop)
							 {
								 firstLoop = false;
								 compareNum = (ClassToColumnMap[type] as ClassInfoObject).tStatisticArray[r];
								 tempType = type;
								 
							 }
						 
						 else
						 {
								 if(compareNum < tempTValue)
								 {
									 tempType = type;
									 compareNum = tempTValue;
									 
								 }
						 }
						
					}//using Tstat loop ends here
					
					
				}//for every type loops ends here
				
				if(tempType != null)
				{
					if(isNaN(thresholdValue) == false)//if threshold is specified
					{
						if(compareNum >= thresholdValue)
						{
							tAndpMapping[tempType].push(columnNames[r]);
							tandpValuesMapping[tempType+"metricvalues"].push(compareNum);
						}
					}
					
					else
					{
						tAndpMapping[tempType].push(columnNames[r]);
						tandpValuesMapping[tempType+"metricvalues"].push(compareNum);
					}
					
					/*tAndpMapping[tempType].push(columnNames[r]);
					tandpValuesMapping[tempType+"metricvalues"].push(compareNum);*/
				}
				
			}//for every column loop ends here
			
			return tAndpMapping;
		}		
	}
}



/*if(columnNumberperType > 0)//allows only definite number of columns to be included in every class
{
	if(r < columnNumPerClass)
	{
		tAndpMapping[tempType].push(columnNames[r]);
		tandpValuesMapping[tempType+"metricvalues"].push(compareNum);
	}
	columnNumberperType--;
}

if(isNaN(columnNumberperType))
{
	tAndpMapping[tempType].push(columnNames[r]);
	tandpValuesMapping[tempType+"metricvalues"].push(compareNum);
}*/


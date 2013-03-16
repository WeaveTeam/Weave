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

package weave.data.BinningDefinitions
{
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableNumber;
	import weave.data.BinClassifiers.NumberClassifier;
	import weave.utils.AsyncSort;
	import weave.utils.VectorUtils;
	
	/**
	 * Implemented from Doug Curl (javascript) and Daniel J Lewis (python implementation) and  Simon Georget (Geostats)
	 * http://www.arcgis.com/home/item.html?id=0b633ff2f40d412995b8be377211c47b
	 * http://danieljlewis.org/2010/06/07/jenks-natural-breaks-algorithm-in-python/
	 * https://github.com/simogeo/geostats/blob/master/lib/geostats.js
	 * http://danieljlewis.org/files/2010/06/Jenks.pdf
	 */
	
	public class NaturalJenksBinningDefinition extends AbstractBinningDefinition
	{
		public function NaturalJenksBinningDefinition()
		{
			this.numOfBins.value = 5; //defaults to 5 bins	
		}
		
		public const numOfBins:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		
		// reusable temporary object
		private static const _tempNumberClassifier:NumberClassifier = new NumberClassifier();
		
		
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var breaks:Array = getJenksBreak(column);
			
			var binMin:Number;
			var binMax:Number; 
			
			
			for (var iBin:int = 0; iBin < numOfBins.value; iBin++)
			{
				var minIndex:Number;
				if(iBin == 0)
				{
					minIndex = 0;
				}
				else
				{
					minIndex = _previousSortedValues.lastIndexOf(_previousBreaks[iBin]);
					minIndex = minIndex +1;
				}
				
				_tempNumberClassifier.min.value = _previousSortedValues[minIndex];
				
				var maxIndex:Number;
				if(iBin == numOfBins.value -1)
				{
					maxIndex = _previousSortedValues.length -1;
				}
				else
				{
					/* Get the index of the next break */
					maxIndex = _previousSortedValues.lastIndexOf(_previousBreaks[iBin+1]);
				}
				_tempNumberClassifier.max.value = _previousSortedValues[maxIndex];
				_tempNumberClassifier.minInclusive.value = true;
				_tempNumberClassifier.maxInclusive.value = true;
				
				//first get name from overrideBinNames
				name = getOverrideNames()[iBin];
				//if it is empty string set it from generateBinLabel
				if(!name)
					name = _tempNumberClassifier.generateBinLabel(column as IPrimitiveColumn);
				output.requestObjectCopy(name, _tempNumberClassifier);
			}
				
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		/* This function returns the Good Fit Value for the breaks. Not used but just in case*/
		private function getGVF(column:IAttributeColumn):Number
		{
			var listMean:Number = getSumOfNumbers(_previousSortedValues);
			
			var SDAM:Number = 0;
			var sqDev:Number = 0;
			
			for(var i:int =0; i < _previousSortedValues.length; i++)
			{
				sqDev = Math.pow((_previousSortedValues[i]- listMean), 2);
				SDAM += sqDev;
			}
			
			
			var SDCM:Number = 0;
			var preSDCM:Number;
			var classStart:Number;
			var classEnd:Number;
			var classValues:Array;
			var classMean:Number;
			var sqDev2:Number;
			
			for(var j:int =0; j < numOfBins.value; j++)
			{
				if(_previousBreaks[j] ==0)
				{
					classStart = 0;
				}
				else
				{
					classStart = _previousSortedValues.indexOf(_previousBreaks[j]);
					classStart += 1;
				}
				
				classEnd = _previousSortedValues.indexOf(_previousBreaks[j+1]);
				
				classValues = _previousSortedValues.slice(classStart,classEnd);
				
				classMean = getSumOfNumbers(classValues)/classValues.length;
				
				for(var k:int =0; k < classValues.length; k++)
				{
					sqDev2 = Math.pow((classValues[k] - classMean),2);
					preSDCM += sqDev2;
				}
				
				SDCM += preSDCM;
			}
			
			return (SDAM - SDCM)/SDAM;
			
		}
		
		private var _previousSortedValues:Array = [];
		private var _previousBreaks:Array = [];
		
		private function getJenksBreak(column:IAttributeColumn):Array
		{	
			_previousBreaks.length = 0;
			_previousSortedValues.length = 0;
			
			var sortedValues:Array = getSortedNumbersFromColumn(column);
			
			VectorUtils.copy(sortedValues,_previousSortedValues);
			
			var mat1:Array = [];
			var mat2:Array = [];
			for (var i:int = 0; i < sortedValues.length+1; i++)
			{
				var temp1:Array = [];
				var temp2:Array = [];
				
				for(var j:int =0; j < numOfBins.value+1; j++)
				{
					temp1.push(0);
					temp2.push(0);
				}
				mat1.push(temp1);
				mat2.push(temp2);
			}
			
			for (var k:int =1; k < numOfBins.value + 1; k++)
			{
				mat1[0][k] = 1;
				mat2[0][k] = 0;
				
				for (var t:int =1; t<sortedValues.length+1; t++)
				{
					mat2[t][k] = Number.POSITIVE_INFINITY;
				}
			}
			
			var v:Number = 0;
			
			for (var count:int = 2; count < sortedValues.length + 1; count++)
			{
				var s1:Number = 0;
				var s2:Number = 0;
				
				var w:Number = 0;
				
				for(var m:int = 1; m < count + 1; m++)
				{
					var i3:Number = count - m +1;
					var val:Number = sortedValues[i3-1];
					
					s2 += val * val;
					s1 += val;
					
					w += 1;
					v = s2 - (s1 * s1) / w;
					var i4:Number= i3 -1;
					if(i4 !=0)
					{
						for (var p:Number = 2; p < numOfBins.value + 1; p++)
						{
							if((mat2[count][p]) >= (v + mat2[i4][p-1]))
							{
								mat1[count][p] = i3;
								mat2[count][p] = v + mat2[i4][p-1];
							}
						}
					}
				}
				mat1[count][1] = 1;
				mat2[count][1] = v;
			}
			
			var kClassCount:Number =  sortedValues.length;
			var kClass:Array = [];
			
			for(i = 0; i < numOfBins.value +1; i++)
			{
				kClass.push(0);
			}
			
			//this is the last number in the array
			kClass[numOfBins.value] = sortedValues[sortedValues.length -1];
			
			//this is the first numer in the array 
			kClass[0] = sortedValues[0];
			
			
			var countNum:Number = numOfBins.value;
			
			while (countNum >=2)
			{
				var id:Number = mat1[kClassCount][countNum] -2;
				kClass[countNum -1] = sortedValues[id];
				kClassCount = mat1[kClassCount][countNum] -1;
				// spits out the rank and value of the break values:
				// console.log("id="+id,"rank = " + String(mat1[k][countNum]),"val =
				// " + String(dataList[id]))
				// count down:
				countNum --;
			}
			
			// check to see if the 0 and 1 in the array are the same - if so, set 0
			// to 0:
			if (kClass[0] == kClass[1]) 
			{
				kClass[0] = 0
			}
			
			VectorUtils.copy(kClass,_previousBreaks);
			return kClass;
		}
		
		private function getSumOfNumbers(list:Array):Number
		{
			var result:Number = 0;
			try
			{
				for each (var num:Number in list)
				{
					result += num;
				}
			}
			catch(e:Error)
			{
				reportError(e, "Error adding numbers in array");
				return 0;
			}
			
			return result;
		}
		
		/**
		 * Returns all the values from the column sorted in ascedning order.
		 * @param column An IattributeColumn with numeric values 
		 * */
		private  function getSortedNumbersFromColumn(column:IAttributeColumn):Array
		{
			var keys:Array = column ? column.keys : [];
			var sortedColumn:Array = new Array(keys.length);
			var i:uint = 0;
			for each (var key:IQualifiedKey in keys)	
			{
				sortedColumn[i] = column.getValueFromKey(key,Number);
				i = i+1;
			}
			AsyncSort.sortImmediately(sortedColumn, ObjectUtil.numericCompare);
			return sortedColumn;
		}
		
	}
}
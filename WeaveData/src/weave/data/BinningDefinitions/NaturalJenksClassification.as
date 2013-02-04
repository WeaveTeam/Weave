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
	import mx.collections.errors.SortError;
	
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.core.LinkableNumber;
	import weave.utils.ColumnUtils;
	import weave.utils.VectorUtils;
	
	/**
	 * Implemented from Doug Curl (javascript) and Daniel J Lewis (python implementation) and  Simon Georget (Geostats)
	 * http://www.arcgis.com/home/item.html?id=0b633ff2f40d412995b8be377211c47b
	 * http://danieljlewis.org/2010/06/07/jenks-natural-breaks-algorithm-in-python/
	 * https://github.com/simogeo/geostats/blob/master/lib/geostats.js
	 * http://danieljlewis.org/files/2010/06/Jenks.pdf
	 */
	
	public class NaturalJenksClassification extends AbstractBinningDefinition
	{
		public function NaturalJenksClassification()
		{
			this.numOfBins.value = 5; //defaults to 5 bins	
		}
		
		public const numOfBins:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		
		override public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var sortedValues:Array = ColumnUtils.getSortedNumbersFromColumn(column);
			
			var mat1:Array = [];
			var mat2:Array = [];
			for (var i:int = 0; i < sortedValues.length+1; i++)
			{
				var temp1:Array = [];
				var temp2:Array = [];
				
				for(var j:int =0; j < numOfBins.value+1; j++)
				{
					temp1.push(0);
					temp2.psuh(0);
				}
				mat1.push(temp1);
				mat2.push(temp2);
			}
			
			for (var k:int =0; k < numOfBins.value + 1; k++)
			{
				mat1[0][k] = 1;
				mat2[0][k] = 0;
				
				for (var t:int =0; t<sortedValues.length; t++)
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
					v = s2 - (s1 * s2) / w;
					var i4:Number= i3 -1;
					if(i4 !=0)
					{
						for (var p:Number = 2; p < numOfBins.value; p++)
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
				var id:Number = mat1[k][countNum] -2;
				kClass[countNum -1] = sortedValues[id];
				k = mat1[k][countNum] -1;
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
			
			
			
		}
	}
}
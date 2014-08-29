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

package weave.data.AttributeColumns
{
	import weave.api.data.Aggregation;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.utils.Dictionary2D;
	
	/**
	 * @author adufilie
	 */
	public class NumberColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public function NumberColumn(metadata:Object = null)
		{
			super(metadata);
			
			dataTask = new ColumnDataTask(this, isFinite);
			dataCache = new Dictionary2D();
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataType.NUMBER;
			return super.getMetadata(propertyName);
		}

		public function setRecords(keys:Vector.<IQualifiedKey>, numericData:Vector.<Number>):void
		{
			dataTask.begin(keys, numericData);
			dataCache = new Dictionary2D();

			numberToStringFunction = null;
			// compile the string format function from the metadata
			var stringFormat:String = getMetadata(ColumnMetadata.STRING);
			if (stringFormat)
			{
				try
				{
					numberToStringFunction = compiler.compileToFunction(stringFormat, null, errorHandler, false, [ColumnMetadata.NUMBER, 'array']);
				}
				catch (e:Error)
				{
					errorHandler(e);
				}
			}
		}
		
		private function errorHandler(e:*):void
		{
			var str:String = e is Error ? e.message : String(e);
			str = StandardLib.substitute("Error in script for attribute column {0}:\n{1}", Compiler.stringify(_metadata), str);
			if (_lastError != str)
			{
				_lastError = str;
				reportError(e);
			}
		}
		
		private var _lastError:String;
		
		private static const compiler:Compiler = new Compiler();
		private var numberToStringFunction:Function = null;
		
		/**
		 * Get a string value for a given number.
		 */
		public function deriveStringFromNumber(number:Number):String
		{
			if (numberToStringFunction != null)
				return StandardLib.asString(numberToStringFunction(number, [number]));
			return StandardLib.formatNumber(number);
		}
		
		override protected function generateValue(key:IQualifiedKey, dataType:Class):Object
		{
			var array:Array = dataTask.arrayData[key];
			
			if (dataType === Number)
			{
				if (!array)
					return NaN;
				
				switch (_metadata ? _metadata[ColumnMetadata.AGGREGATION] : null)
				{
					default:
					case Aggregation.FIRST:
						return array[0];
					case Aggregation.LAST:
						return array[array.length - 1];
					case Aggregation.COUNT:
						return array.length;
					case Aggregation.MEAN:
						return StandardLib.mean(array);
					case Aggregation.SUM:
						return StandardLib.sum(array);
					case Aggregation.MIN:
						return Math.min.apply(null, array);
					case Aggregation.MAX:
						return Math.max.apply(null, array);
				}
			}
			
			if (dataType === String)
			{
				var number:Number = getValueFromKey(key, Number);
				if (numberToStringFunction != null)
					return StandardLib.asString(numberToStringFunction(number, array));
				return StandardLib.formatNumber(number);
			}
			
			return null;
		}

		override public function toString():String
		{
			return debugId(this) + '{recordCount: '+keys.length+', keyType: "'+getMetadata('keyType')+'", title: "'+getMetadata('title')+'"}';
		}
	}
}

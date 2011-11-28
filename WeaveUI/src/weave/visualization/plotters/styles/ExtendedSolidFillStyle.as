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

package weave.visualization.plotters.styles
{
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ImageColumn;

	/**
	 * Draws a fill pattern when no color is specified.
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	public class ExtendedSolidFillStyle extends SolidFillStyle
	{
		public function ExtendedSolidFillStyle()
		{
			super();
			_matrix = new Matrix();
 			_matrix.createGradientBox(10, 10, 45, 0, 0);
		}
		
		private var _matrix:Matrix = null;
		
		/**
		 * Private column that downloads the images.
		 */
		private var _imageColumn:ImageColumn;
		private function getImageColumn():ImageColumn
		{
			if (!_imageColumn)
				_imageColumn = newLinkableChild(this, ImageColumn);
			return _imageColumn;
		}
		
		/**
		 * set image URL on a per-record basis
		 */
		public const imageURL:AlwaysDefinedColumn = registerLinkableChild(this, getImageColumn().requestLocalObject(AlwaysDefinedColumn, true));
		
		public const enableMissingDataGradient:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		/**
		 * This function sets the fill on a Graphics object using the saved fill properties.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 * @return A value of true if this function began a fill, or false if it did not.
		 */
		override public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):Boolean
		{
			if (super.beginFillStyle(recordKey, target))
				return true;
			
			var _enabled:Boolean = StandardLib.asBoolean( enabled.getValueFromKey(recordKey) );
			if (_enabled)
			{
				var _bitmapData:BitmapData = _imageColumn.getValueFromKey(recordKey, BitmapData);
				if (_bitmapData)
				{
					target.beginBitmapFill(_bitmapData);
					return true;
				}
			
				if (enableMissingDataGradient.value)
				{
					target.beginGradientFill(
							GradientType.LINEAR,
							[0x808080, 0xFFFFFF],
							[0.5, 0.5],
							[0, 255],
							_matrix,
							SpreadMethod.REFLECT//.REPEAT
						);
					return true;
				}
			}
			target.endFill();
			return false;
		}
		
		// backwards compatibility
		[Deprecated(replacement="enableMissingDataGradient")] public function set enableMissingDataFillPattern(value:Boolean):void
		{
			if (value == false)
				enableMissingDataGradient.value = value;
		}
	}
}

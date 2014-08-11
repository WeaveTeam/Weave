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
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ImageColumn;

	/**
	 * Draws a fill pattern when no color is specified.
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	public class ExtendedFillStyle extends SolidFillStyle
	{
		public function ExtendedFillStyle()
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
		 * @param target The Graphics object to initialize.
		 * @return A value of true if this function began a fill, or false if it did not.
		 */
		override public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):Boolean
		{
			return beginFillExt(target, getBeginFillParamsExt(recordKey));
		}
		
		/**
		 * This function sets the fill on a Graphics object using params returned from getBeginFillParamsExt().
		 * @param target The Graphics object to initialize.
		 * @param paramsExt Parameters returned from getBeginFillParamsExt().
		 * @return A value of true if this function began a fill, or false if it did not.
		 */
		public function beginFillExt(target:Graphics, paramsExt:Array):Boolean
		{
			if (paramsExt)
			{
				var _color:Number = paramsExt[0];
				var _alpha:Number = paramsExt[1];
				var _url:String = paramsExt[2];
				var _enableMissingDataGradient:Boolean = paramsExt[3];
				
				// use color if specified
				if (isFinite(_color))
				{
					target.beginFill(_color, _alpha);
					return true;
				}
				
				// use bitmap if we have it
				var _bitmapData:BitmapData = _imageColumn.getImageFromUrl(_url);
				if (_bitmapData)
				{
					target.beginBitmapFill(_bitmapData);
					return true;
				}
				
				// use gradient if enabled
				if (_enableMissingDataGradient)
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
			
			// no fill
			target.endFill();
			return false;
		}
		
		/**
		 * @param recordKey The record key to get the fill style for.
		 * @return [color, alpha] or [NaN, NaN, url, enableMissingDataGradient] or null if there is no fill
		 */
		public function getBeginFillParamsExt(recordKey:IQualifiedKey):Array
		{
			if (!enable.getSessionState())
				return null;
			
			var params:Array = getBeginFillParams(recordKey);
			if (params)
				return params;
			
			var _url:String = imageURL.getValueFromKey(recordKey, String);
			var _enableMissingDataGradient:Boolean = enableMissingDataGradient.getSessionState();
			// if the image is not available now, do not provide the url
			// this makes it so beginFillExt() is deterministic with respect to the params list.
			if (!_imageColumn.getImageFromUrl(_url))
				_url = null;
			if (_url || _enableMissingDataGradient)
				return [NaN, NaN, _url, _enableMissingDataGradient];
			
			return null;
		}
		
		// backwards compatibility
		[Deprecated(replacement="enableMissingDataGradient")] public function set enableMissingDataFillPattern(value:Boolean):void
		{
			if (value == false)
				enableMissingDataGradient.value = value;
		}
	}
}

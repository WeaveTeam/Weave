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
	import flash.display.Graphics;
	import flash.net.URLRequest;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IFillStyle;
	import weave.compiler.StandardLib;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;

	/**
	 * BitmapFillStyle
	 * 
	 * @author adufilie
	 */
	public class BitmapFillStyle implements IFillStyle
	{
		public function BitmapFillStyle()
		{
		}

		/**
		 * enable or disable fill on a per-record basis
		 */
		public const enabled:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(true));
		/**
		 * enable or disable repeat on a per-record basis
		 */
		public const repeat:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(true));
		/**
		 * enable or disable smooth on a per-record basis
		 */
		public const smooth:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(false));
		/**
		 * set image URL on a per-record basis
		 */
		public const imageURL:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(null));
		
		/**
		 * This function sets the fill on a Graphics object using the saved fill properties.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 */
		public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			var _bitmapData:BitmapData = null;
			//TODO: fill _bitmapData
			//WeaveAPI.URLRequestUtils.getContent(new URLRequest(url), handleResult);
			
			var fillEnabled:Boolean = _bitmapData && StandardLib.asBoolean( enabled.getValueFromKey(recordKey) );
			if (fillEnabled)
			{
				var _repeat:Boolean = StandardLib.asBoolean( repeat.getValueFromKey(recordKey, Boolean) );
				var _smooth:Boolean = StandardLib.asBoolean( smooth.getValueFromKey(recordKey, Boolean) );
				target.beginBitmapFill(_bitmapData, null, _repeat, _smooth);
			}
			else
			{
				target.endFill();
			}
		}
	}
}

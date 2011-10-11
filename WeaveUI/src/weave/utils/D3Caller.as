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
package weave.utils
{
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;

	public class D3Caller
	{		
		[Embed("d3.js", mimeType="application/octet-stream")]
		private static const D3:Class;
		
		[Embed("bar.js", mimeType="application/octet-stream")]
		private static const BAR:Class;
		/**
		 * uniqueIDToTokenMap
		 * This maps a unique ID (generated when a request is made to download from a URL through this class)
		 * to an AsyncToken associated with it.
		 */
		private static const uniqueIDToTokenMap:Dictionary = new Dictionary(true);
		
		private static var _initialized:Boolean = false;
		
		private static function initialize():void
		{
			if(_initialized)
				return;
			
			try
			{
				// load the embedded d3 javascript file so it can be used as any other loaded
				// javascript file would
				var d3:String = String(new D3());
				var bar:String = String(new BAR());
								
				
				ExternalInterface.call('function(){' + d3 + '}');
				ExternalInterface.call('function(){' + bar + '}');
				
				_initialized = true;
			}
			catch (e:Error)
			{
				WeaveAPI.ErrorManager.reportError(e);
			}
		}

		public static function generateBarChart(barData:Object):void
		{
			initialize();
			
			ExternalInterface.call("setData", barData.yDataArray, barData.axisMax, barData.axisMin);
			ExternalInterface.call("setXgrid", barData.xTicks, barData.xAxisMax, barData.xAxisMin);			
			ExternalInterface.call("setYgrid", barData.yTicks, barData.axisMax, barData.axisMin);
			ExternalInterface.call("setWidthAndHeight", barData.width, barData.height);
			ExternalInterface.call("setMargins", barData.marginTop, barData.marginLeft, barData.marginBottom, barData.marginRight);
			ExternalInterface.call("setTitles", barData.title, barData.yTitle, barData.xTitle);
			
			var x:* = ExternalInterface.call('draw()');
			Alert.show(ObjectUtil.toString(barData.xTicks),'svg');
		}		
	}
}
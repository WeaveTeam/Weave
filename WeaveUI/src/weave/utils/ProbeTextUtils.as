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
	import flash.display.Stage;
	
	import mx.controls.ToolTip;
	import mx.core.Application;
	import mx.core.IToolTip;
	import mx.managers.ToolTipManager;
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StringLib;
	import weave.core.LinkableHashMap;
	import weave.primitives.Bounds2D;
	import weave.visualization.layers.InteractiveVisualization;
	import weave.visualization.layers.SimpleInteractiveVisualization;
	
	/**
	 * ProbeTextManager
	 * A static class containing functions to manage a list of probed attribute columns
	 * 
	 * @author adufilie
	 */
	public class ProbeTextUtils
	{
		public static function get probedColumns():LinkableHashMap
		{
			// this initializes the probed columns object map if not created yet, otherwise just returns the existing one
			return Weave.root.requestObject("Probed Columns", LinkableHashMap, true);
		}
		
		public static function get probeHeaderColumns():LinkableHashMap
		{
			return Weave.root.requestObject("Probe Header Columns", LinkableHashMap, true);
		}
		
		/**
		 * getProbeText
		 * @param keySet The key set you are interested in.
		 * @param additionalColumns An array of additional columns (other than global probed columns) to be displayed in the probe tooltip
		 * @param maxRecordsShown Maximum no. of records shown in one probe tooltip
		 * @return A string to be displayed on a tooltip while probing 
		 */		
		public static function getProbeText(keySet:IKeySet, additionalColumns:Array = null):String
		{
			var result:String = '';
			var columns:Array = probedColumns.getObjects(IAttributeColumn);
			if (additionalColumns != null)
				columns = columns.concat(additionalColumns);
			var headers:Array = probeHeaderColumns.getObjects(IAttributeColumn);
			var keys:Array = keySet.keys.concat().sort(ObjectUtil.compare);
			var key:IQualifiedKey;
			var recordCount:int = 0;
			var maxRecordsShown:Number = Weave.properties.maxTooltipRecordsShown.value;
			for (var iKey:int = 0; iKey < keys.length && iKey < maxRecordsShown; iKey++)
			{
				key = keys[iKey] as IQualifiedKey;

				var record:String = '';
				for (var iHeader:int = 0; iHeader < headers.length; iHeader++)
				{
					var header:IAttributeColumn = headers[iHeader] as IAttributeColumn;
					var headerValue:String = StringLib.toString(header.getValueFromKey(key, String));
					if (headerValue == '')
						continue;
					if (record != '')
						record += ', ';
					record += headerValue;
				}
				
				if (record != '')
					record += '\n';
				var lookup:Object = new Object() ;
				for (var iColumn:int = 0; iColumn < columns.length; iColumn++)
				{
					var column:IAttributeColumn = columns[iColumn] as IAttributeColumn;
					var value:String = String(column.getValueFromKey(key, String));
					if (value == '' || value == 'NaN')
						continue;
					var title:String = ColumnUtils.getTitle(column);
					var line:String = StringLib.lpad(value, 8) + ' (' + title + ')\n';
					if(lookup[line]  == undefined )
					{
						record += line;
						lookup[line] = true;
					}
				}
				if (record != '')
				{
					result += record + '\n';
					recordCount++;
				}
			}
			// remove ending '\n'
			while (result.substr(result.length - 1) == '\n')
				result = result.substr(0, result.length - 1);
			
			if (result == '')
			{
				result = 'Record Identifier' + (keys.length > 1 ? 's' : '') + ':\n';
				for (var i:int = 0; i < keys.length && i < maxRecordsShown; i++)
				{
					key = keys[i] as IQualifiedKey;
					result += '    ' + key.keyType + '#' + key.localName + '\n';
					recordCount++;
				}
			}
			
			if (recordCount >= maxRecordsShown && keys.length > maxRecordsShown)
			{
				result += '\n... (' + keys.length + ' records total, ' + recordCount + ' shown)';
			}

			return result;
		}
		
		private static function setProbeToolTipAppearance():void
		{
			(probeToolTip as ToolTip).setStyle("backgroundAlpha", Weave.properties.probeToolTipBackgroundAlpha.value);
			if (isFinite(Weave.properties.probeToolTipBackgroundColor.value))
				(probeToolTip as ToolTip).setStyle("backgroundColor", Weave.properties.probeToolTipBackgroundColor.value);
		}
		
		public static function showProbeToolTip(probeText:String, stageX:Number, stageY:Number, bounds:IBounds2D = null, margin:int = 5):void
		{
			if (bounds == null)
			{
				var stage:Stage = Application.application.stage;
				tempBounds.setBounds(stage.x, stage.y, stage.stageWidth, stage.stageHeight);
				bounds = tempBounds;
			}
			destroyProbeToolTip();
			
			// create new tooltip
			probeToolTip = ToolTipManager.createToolTip(probeText, 0, 0);
			
			// make tooltip completely opaque because text + graphics on same sprite is slow
			setProbeToolTipAppearance() ;
			var xMin:Number = bounds.getXNumericMin();
			var yMin:Number = bounds.getYNumericMin();
			var xMax:Number = bounds.getXNumericMax() - probeToolTip.width;
			var yMax:Number = bounds.getYNumericMax() - probeToolTip.height;
			var b:Boolean = false;
			var yAxisToolTip:IToolTip = SimpleInteractiveVisualization.yAxisTooltipPtr ;
			var xAxisToolTip:IToolTip = SimpleInteractiveVisualization.xAxisTooltipPtr ;
			
			// calculate y coordinate
			var y:int;
			// calculate y pos depending on toolTipAbove setting
			if (toolTipAbove)
			{
				y = stageY - (probeToolTip.height + 2 * margin);
				if(yAxisToolTip != null)
					y = yAxisToolTip.y - margin - probeToolTip.height ;
			}
			else // below
			{
				y = stageY + margin * 2;
				if(yAxisToolTip != null)
					y = yAxisToolTip.y+yAxisToolTip.height+margin;
			}
			
			// flip y position if out of bounds
			if ((y < yMin && toolTipAbove) || (y > yMax && !toolTipAbove))
				toolTipAbove = !toolTipAbove;
			
			// calculate x coordinate
			var x:int;
			if (cornerToolTip)
			{
				// want toolTip corner to be near probe point
				if (toolTipToTheLeft)
				{
					x = stageX - margin - probeToolTip.width;
					if(xAxisToolTip != null)
						x = xAxisToolTip.x - margin - probeToolTip.width; 
				}
				else // to the right
				{
					x = stageX + margin;
					if(xAxisToolTip != null)
						x = xAxisToolTip.x+xAxisToolTip.width+margin;
				}
				
				// flip x position if out of bounds
				if ((x < xMin && toolTipToTheLeft) || (x > xMax && !toolTipToTheLeft))
					toolTipToTheLeft = !toolTipToTheLeft;
			}
			else // center x coordinate
			{
				x = stageX - probeToolTip.width / 2;
			}
			
			// if at lower-right corner of mouse, shift to the right 10 pixels to get away from the mouse pointer
			if (x > stageX && y > stageY)
				x += 10;
			
			// enforce min/max values and position tooltip
			x = Math.max(xMin, Math.min(x, xMax));
			y = Math.max(yMin, Math.min(y, yMax));
			
			probeToolTip.move(x, y);
		}
		
		
		/**
		 * cornerToolTip:
		 * false = center of tooltip will be aligned with x probe coordinate
		 * true = corner of tooltip will be aligned with x probe coordinate
		 */
		private static var cornerToolTip:Boolean = true;
		private static var toolTipAbove:Boolean = true;
		private static var toolTipToTheLeft:Boolean = false;
		private static var probeToolTip:IToolTip = null;
		private static const tempBounds:IBounds2D = new Bounds2D();
		
		public static function destroyProbeToolTip():void
		{
			if (probeToolTip != null)
			{
				ToolTipManager.destroyToolTip(probeToolTip);
				probeToolTip = null;
			}
		}
	}
}

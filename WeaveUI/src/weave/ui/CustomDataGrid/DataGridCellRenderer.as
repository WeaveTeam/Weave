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
package weave.ui.CustomDataGrid
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	
	import mx.containers.Canvas;
	import mx.controls.DataGrid;
	import mx.controls.Image;
	import mx.controls.Label;
	
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.data.KeySets.KeySet;

	public class DataGridCellRenderer extends Canvas
	{
		public function DataGridCellRenderer()
		{
			addChild(img);
			addChild(lbl);
			lbl.percentWidth = 100;
			
			horizontalScrollPolicy = "off";
			
			img.x = 1; // because there is a vertical grid line on the left that overlaps the item renderer
			img.source = new Bitmap(null, 'auto', true);
		}
		
		private var img:Image = new Image();
		private var lbl:Label = new Label();
		
		public var attrColumn:IAttributeColumn = null;
		public var showColors:LinkableBoolean = null;
		
		/**
		 * This function should take two parameters: function(column:IAttributeColumn, key:IQualifiedKey, cell:UIComponent):Number
		 * The return value should be a color, or NaN for no color.
		 */		
		public var colorFunction:Function = null;
		public var keySet:KeySet = null;
		
		override public function set data(item:Object):void
		{
			var key:IQualifiedKey = item as IQualifiedKey;
			
			super.data = key;
			if (attrColumn is ImageColumn)
			{
				lbl.visible = false;
				lbl.text = toolTip = '';
				(img.source as Bitmap).bitmapData = attrColumn.getValueFromKey(key) as BitmapData;
			}
			else
			{
				lbl.visible = true;
				lbl.text = toolTip = attrColumn.getValueFromKey(key, String);
				img.source = null;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if (!owner)
				return;
			
			var g:Graphics = graphics;
			g.clear();
			
			var grid:DataGrid = owner as DataGrid || owner.parent as DataGrid;
			if (keySet.keys.length > 0)
			{
				if (grid.isItemSelected(data) || grid.isItemHighlighted(data))
				{
					lbl.setStyle("fontWeight", "bold");
					alpha = 1.0;
				}				
				else
				{
					lbl.setStyle("fontWeight", "normal");
					alpha = 0.3;
				}
			}
			else
			{
				lbl.setStyle("fontWeight", "normal");
				alpha = 1.0;	
			}
			
			// right-align numbers
			if (attrColumn.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.NUMBER)
				lbl.setStyle('textAlign', 'right');
			else
				lbl.setStyle('textAlign', 'left');
			
			if (showColors.value)
			{
				var colorValue:Number = colorFunction(attrColumn, data as IQualifiedKey, this);
				if (!isNaN(colorValue))
				{
					g.beginFill(colorValue);
					g.drawRect(0, 0, unscaledWidth, unscaledHeight);
					g.endFill();
				}
			}
		}
	}
}
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
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.Canvas;
	import mx.controls.DataGrid;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.core.UIComponent;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.data.KeySets.KeySet;

	public class DataGridCellRenderer extends Canvas
	{
		public function DataGridCellRenderer()
		{
			addChild(img);
			addChild(lbl);
			
			horizontalScrollPolicy = "off";
			
			img.x = 1; // because there is a vertical grid line on the left that overlaps the item renderer
			img.source = new Bitmap(null, 'auto', true);
		}
		
		private var img:Image = new Image();
		private var lbl:Label = new Label();
		
		public var attrColumn:IAttributeColumn = null;
		public var showColors:LinkableBoolean = null;
		public var colorColumn:ColorColumn = null;
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
			
			var g:Graphics = graphics;
			g.clear();
			
			if (!showColors.value)
				return;
			
			var grid:DataGrid = owner as DataGrid || owner.parent as DataGrid;
			if (keySet.keys.length > 0)
			{
				if (grid.isItemSelected(data) || grid.isItemHighlighted(data))
				{
					setStyle("fontWeight", "bold");
					alpha = 1.0;
				}				
				else
				{
					setStyle("fontWeight", "normal");
					alpha = 0.3;
				}
			}
			else
			{
				setStyle("fontWeight", "normal");
				alpha = 1.0;	
			}
			
			var colorValue:Number = colorColumn.getValueFromKey(data as IQualifiedKey);
			if (!isNaN(colorValue))
			{
				g.beginFill(colorValue);
				g.drawRect(0, 0, unscaledWidth, unscaledHeight);
				g.endFill();
			}
		}
	}
}
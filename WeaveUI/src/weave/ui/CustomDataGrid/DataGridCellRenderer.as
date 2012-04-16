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
	import mx.core.UIComponent;
	
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
			addChild(lbl);
			lbl.percentWidth = 100;
			
			horizontalScrollPolicy = "off";
		}
		
		private var img:Image;
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
				if (!img)
				{
					img = new Image();
					img.x = 1; // because there is a vertical grid line on the left that overlaps the item renderer
					img.source = new Bitmap(null, 'auto', true);
					addChild(img);
				}
				img.visible = true;
				(img.source as Bitmap).bitmapData = attrColumn.getValueFromKey(key) as BitmapData;
			}
			else
			{
				lbl.visible = true;
				lbl.text = toolTip = attrColumn.getValueFromKey(key, String);
				if (img)
				{
					img.visible = false;
					img.source.bitmapData = null;
				}
			}
		}
		
		private static function _setStyle(target:UIComponent, styleProp:String, newValue:*):void
		{
			if (target.getStyle(styleProp) != newValue)
				target.setStyle(styleProp, newValue);
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
					_setStyle(lbl, "fontWeight", "bold");
					alpha = 1.0;
				}				
				else
				{
					_setStyle(lbl, "fontWeight", "normal");
					alpha = 0.3;
				}
			}
			else
			{
				_setStyle(lbl, "fontWeight", "normal");
				alpha = 1.0;	
			}
			
			// right-align numbers
			if (attrColumn.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.NUMBER)
			{
				_setStyle(lbl, 'textAlign', 'right');
			}
			else
			{
				_setStyle(lbl, 'textAlign', 'left');
			}
			
			if (showColors.value)
			{
				var colorValue:Number = colorFunction(attrColumn, data as IQualifiedKey, this);
				_setStyle(this, 'backgroundColor', colorValue);
			}
			else
			{
				_setStyle(this, 'backgroundColor', null);
			}
		}
	}
}
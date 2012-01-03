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
	import flash.display.Graphics;
	
	import mx.controls.DataGrid;
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridListData;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.KeySets.KeySet;
	import weave.data.QKeyManager;
	import weave.visualization.plotters.styles.SolidFillStyle;

	public class DataGridCellRenderer extends Label
	{
		public function DataGridCellRenderer()
		{
			super();
		}
		
		public var colorColumn:ColorColumn = null;
		
		public var keySet:KeySet = null;
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();
			var grid:DataGrid = DataGrid(DataGridListData(listData).owner);
			if(keySet.keys.length > 0){
				if (grid.isItemSelected(data) || grid.isItemHighlighted(data)){
					setStyle("fontWeight", "bold");
					alpha = 1.0;
				}				
				else{
					setStyle("fontWeight", "normal");
					alpha = 0.3;
				}
			}
			else{
				setStyle("fontWeight", "normal");
				alpha = 1.0;	
			}
			
			
				
			
			var colorValue:Number = colorColumn.getValueFromKey(data as IQualifiedKey);
			if(!isNaN(colorValue)){
				g.beginFill(colorValue);
				g.drawRect(0, 0, unscaledWidth, unscaledHeight);
				g.endFill();
			}
				
			
		
			
		}
	}
}
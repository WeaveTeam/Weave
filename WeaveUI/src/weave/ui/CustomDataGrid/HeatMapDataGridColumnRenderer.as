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
	
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridBase;
	
	import weave.Weave;
	import weave.data.AttributeColumns.ColorColumn;
	

	/** HeatMapDataGridColumnRenderer
	 *	@author abaumann
	 *	A WeaveDataGridColumn can have a custom renderer created for it that allows a visualization to be put
	 *  into each cell rather than just text that shows the data value.  This class creates a heat map.  
	 **/
	public class HeatMapDataGridColumnRenderer extends Label
	{
		public function HeatMapDataGridColumnRenderer()
		{
			super();
			
			this.cacheAsBitmap = true;			
		}

		private var _normValue:Number = 0;
		private var _xmlData:XML = null;
		private var textBackup:String = null;
		private var heatMapMode:Boolean = false;
		// This function is called when the label for this cell is set.  Instead of just showing the text value, we use the value it represents
		// to color in the cell.  
		override public function set text(value:String):void
		{					
		    // extract data if this is a valid XML
		    try 
		    {
		    	_xmlData = XML(value);
		    	
		    	textBackup = _xmlData.@string;
		    
				super.text = _xmlData.@string;
							
				this.toolTip = _xmlData.@string;
				_normValue = _xmlData.@norm;	
		    }
		 	catch(e:Error)
		 	{
		 		_xmlData = null;
		 		
		 		textBackup = "";
		    
				super.text = "";
							
				this.toolTip = "";
				_normValue = 0;
		 	}  
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			  
			if(heatMapMode)
			{ 
				var g:Graphics = graphics;
				g.clear();
				
				 
				var colorColumn:ColorColumn = null;//Weave.getObject(Weave.GLOBAL_COLORCOLUMN_NAME) as ColorColumn;
				 
				var color:uint = colorColumn.ramp.getColorFromNorm(_normValue);
				var alpha:Number = 1.0;
				
				
				var highlighted:Boolean = DataGridBase(listData.owner).isItemHighlighted(listData.uid);
				var selected:Boolean    = DataGridBase(listData.owner).isItemSelected(listData.uid);
				
				if(!highlighted && !selected)
				{
					alpha = 0.3;	
				}
				
				/*if(unscaledHeight < this.textHeight)
				{
					super.text = "";//textBackup;	
				}
				else
				{
					super.text = textBackup;
				}*/
				
			     
			     
		         
			     
			     /*g.lineStyle(0,0,0);
			     g.beginFill(color, alpha);
		         g.drawRect(0, 0, unscaledWidth, unscaledHeight);
		         g.endFill();*/
		    }
		}
	}
}
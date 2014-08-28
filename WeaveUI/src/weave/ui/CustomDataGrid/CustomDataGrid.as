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
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	import mx.collections.ArrayCollection;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.listClasses.ListBaseContentHolder;
	import mx.core.EventPriority;
	import mx.core.ILayoutDirectionElement;
	import mx.core.SpriteAsset;
	import mx.core.mx_internal;
	import mx.events.DataGridEvent;
	
	use namespace mx_internal;	                          
	
	/**
	 * This is a wrapper around a DataGrid to fix a bug with the mx_internal addMask() function
	 * which was introduced in Flex 3.6 SDK. The issue is the lockedColumnContent is instantiated
	 * and contains invalid data when the lockedColumnCount is 0.
	 * 
	 * Also, uses AsyncSort.sortImmediately() instead of Array.sort() via CustomSort.
	 * 
	 * Added getColumn().
	 * 
	 * destroyItemEditor() no longer calls setFocus().
	 * 
	 * @author kmonico
	 * @author adufilie
	 */	
	public class CustomDataGrid extends DataGrid
	{
		public function CustomDataGrid()
		{
			headerClass = CustomDataGridHeader;
			// add this event listener before the one in super()
			addEventListener(DataGridEvent.HEADER_RELEASE, headerReleaseHandler, false, EventPriority.DEFAULT_HANDLER);
			setStyle('defaultDataGridItemRenderer', CustomDataGridItemRenderer);
			super();
		}
		private var in_destroyItemEditor:Boolean = false;
		override public function destroyItemEditor():void
		{
			in_destroyItemEditor = true;
			super.destroyItemEditor();
			in_destroyItemEditor = false;
		}
		override public function setFocus():void
		{
			if (!in_destroyItemEditor)
				super.setFocus();
		}
		
		protected var _columns:Array = [];
		
		[Bindable("columnsChanged")]
		[Inspectable(category="General", arrayType="mx.controls.dataGridClasses.DataGridColumn")]
		override public function get columns():Array
		{
			return super.columns;
		}
		override public function set columns(value:Array):void
		{
			_columns = super.columns = value;
		}
		
		public function getColumn(index:int):DataGridColumn
		{
			return _columns[index] as DataGridColumn;
		}
		
		override mx_internal function columnWordWrap(c:DataGridColumn):Boolean
		{
			return c ? super.columnWordWrap(c) : false;
		}
		
		private function headerReleaseHandler(event:DataGridEvent):void
		{
			var c:DataGridColumn = columns[event.columnIndex];
			if (c.sortable && !(collection.sort is CustomSort))
				collection.sort = new CustomSort(collection.sort);
		}
		
		public function drawItemForced(item:Object,
 										selected:Boolean = false,
 										highlighted:Boolean = false,
 										caret:Boolean = false,
 										transition:Boolean = false):void
		{
			var renderer:IListItemRenderer = itemToItemRenderer(item);
			drawItem(renderer, selected, highlighted, caret, transition);
		}
		/**
		 * @param items Array of items
		 * @param selected function(item):Boolean
		 */
		public function highlightItemsForced(items:Array, selected:Function):void
		{
			_drawingItems = 0;
			for each (var item:Object in items)
			{
				drawItemForced(item, selected(item), true);
				_drawingItems++;
			}
			_drawingItems = 0;
		}
		private var _drawingItems:int = 0;
		override protected function drawItem(item:IListItemRenderer, selected:Boolean=false, highlighted:Boolean=false, caret:Boolean=false, transition:Boolean=false):void
		{
			if (highlighted)
				highlightUID = null;
			
			super.drawItem(item, selected, highlighted, caret, transition);
		}
		override protected function drawHighlightIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void
		{
			$drawHighlightIndicator(indicator, x, y, unscaledWidth - viewMetrics.left - viewMetrics.right, height, color, itemRenderer);
			if (lockedColumnCount)
			{
				var columnContents:ListBaseContentHolder;
				if (itemRenderer.parent == listContent)
					columnContents = lockedColumnContent;
				else
					columnContents = lockedColumnAndRowContent;
				var selectionLayer:Sprite = columnContents.selectionLayer;
				
				if (!columnHighlightIndicator)
				{
					columnHighlightIndicator = new SpriteAsset();
					columnContents.selectionLayer.addChild(DisplayObject(columnHighlightIndicator));
				}
				else
				{
					if (columnHighlightIndicator.parent != selectionLayer)
						selectionLayer.addChild(columnHighlightIndicator);
					else
						selectionLayer.setChildIndex(DisplayObject(columnHighlightIndicator),
							selectionLayer.numChildren - 1);
				}
				
				// Let the columnHighlightIndicator inherit the layoutDirection
				if (columnHighlightIndicator is ILayoutDirectionElement)
					ILayoutDirectionElement(columnHighlightIndicator).layoutDirection = null;
				
				$drawHighlightIndicator(columnHighlightIndicator, x, y, columnContents.width, height, color, itemRenderer);
			}
		}
		private function $drawHighlightIndicator(
			indicator:Sprite, x:Number, y:Number,
			width:Number, height:Number, color:uint,
			itemRenderer:IListItemRenderer):void
		{
			var g:Graphics = Sprite(indicator).graphics;
			if (_drawingItems == 0)
				g.clear();
			g.beginFill(color);
			g.drawRect(x, y, width, height);
			g.endFill();
			
			indicator.x = 0;
			indicator.y = 0;
		}
		
		
		/**
		 * There's a bug in Flex 3.6 SDK where the locked column content may not be updated
		 * at the same time as the listItems for the DataGrid. This is an issue because they
		 * could have different lengths, and thus cause a null reference error.
		 * 
		 * @param layoutChanged If the layout changed.
		 */			
		override mx_internal function addClipMask(layoutChanged:Boolean):void
		{
			if (lockedColumnCount == 0)
				lockedColumnContent = null; // this should be null if there are no locked columns
			
			super.addClipMask(layoutChanged);
		}
				
		public function getColumnDisplayWidth():Number
		{
			var columnDisplayWidth:Number = this.width - this.viewMetrics.right - this.viewMetrics.left;		
			return columnDisplayWidth;
		}
		
		/**
		 * This function along with getRows() makes it easy to display and edit
		 * a table of data stored as a two-dimensional Array.
		 * @param tableWithHeader An Array of Arrays including a header row.
		 */
		public function setRows(tableWithHeader:Array):void
		{
			// make a copy of the data
			var rows:Array = tableWithHeader.map(function(row:Array, i:int, a:Array):Array { return row.concat(); });
			var header:Array = rows.shift();
			
			dataProvider = null;
			columns = header.map(
				function(title:String, index:int, a:Array):DataGridColumn {
					var dgc:DataGridColumn = new DataGridColumn(title);
					dgc.dataField = index;
					// if title is missing, override default headerText which is equal to dataField
					if (!title)
						dgc.headerText = '';
					return dgc;
				}
			);
			dataProvider = rows;
		}
		
		/**
		 * This function along with setRows() makes it easy to display and edit
		 * a table of data stored as a two-dimensional Array.
		 * @return The (possibly) modified rows with columns in modified order.
		 */
		public function getRows():Array
		{
			var ac:ArrayCollection = dataProvider as ArrayCollection;
			if (!ac)
				throw new Error("dataProvider is not an ArrayCollection as expected.  setRows() must be called before getRows().");
			var cols:Array = columns;
			// data rows from dataProvider, reordered according to new column order
			var rows:Array = ac.source.map(
				function(row:Array, i:int, rows:Array):Array {
					return row.map(
						function(value:*, i:int, row:Array):* {
							return row[(cols[i] as DataGridColumn).dataField];
						}
					);
				}
			);
			// header row from possibly reordered columns
			rows.unshift(cols.map(
				function(col:DataGridColumn, i:int, a:Array):* {
					return col.headerText;
				}
			));
			return rows;
		}
	}
}

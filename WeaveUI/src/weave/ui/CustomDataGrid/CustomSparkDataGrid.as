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
	import mx.collections.ArrayCollection;
	
	import spark.components.DataGrid;
	import spark.components.gridClasses.GridColumn;
	import spark.events.GridEvent;
	
	import weave.compiler.StandardLib;
	
	public class CustomSparkDataGrid extends DataGrid
	{
		public function CustomSparkDataGrid()
		{
			super();
			showDataTips = true;
			selectionMode = 'multipleCells';
			this.addEventListener(GridEvent.GRID_MOUSE_DOWN,dataGrid_gridMouseDownHandler);
			this.addEventListener(GridEvent.GRID_MOUSE_UP,dataGrid_gridMouseUpHandler);
			
			
		}
		// Single Click Editing support
		// taken From 
		// http://blogs.adobe.com/dloverin/2011/05/single-click-editing-and-more.html
		private var mouseDownRowIndex:int;
		private var mouseDownColumnIndex:int;
		
		protected function dataGrid_gridMouseDownHandler(event:GridEvent):void
		{
			mouseDownRowIndex = event.rowIndex;
			mouseDownColumnIndex = event.columnIndex;
		}
		
		protected function dataGrid_gridMouseUpHandler(event:GridEvent):void
		{
			// Start a grid item editor if:
			// - the rowIndex is valid
			// - mouseUp is on the same cell and mouseDown
			// - shift and ctrl keys are not down
			// - cell is editable
			// - an editor is not already running
			// An editor may already be running if the cell was already
			// selected and the data grid started the editor.
			if (event.rowIndex >= 0 &&
				event.rowIndex == mouseDownRowIndex && 
				event.columnIndex == mouseDownColumnIndex &&
				!(event.shiftKey || event.ctrlKey) &&
				event.column.editable &&
				!event.grid.dataGrid.itemEditorInstance)
			{
				event.grid.dataGrid.startItemEditorSession(event.rowIndex, event.columnIndex);
			}
		}
		
		/**
		 * This function along with getRows() makes it easy to display and edit
		 * a table of data stored as a two-dimensional Array.
		 * @param tableWithHeader An Array of Arrays including a header row.
		 */
		public function setRows(tableWithHeader:Array):void
		{
			// make sure we have at least one row (for the header)
			if (!tableWithHeader || !tableWithHeader.length)
				tableWithHeader = [[]];
			
			// make a copy of the data and find the max row length
			var rowLength:int = 0;
			var rows:Array = tableWithHeader.map(function(row:Array, i:int, a:Array):Array {
				rowLength = Math.max(rowLength, row.length);
				return row.concat();
			});
			// expand rows to match max row length
			rows.forEach(function(row:Array, i:int, a:Array):void {
				row.length = rowLength;
			});
			var header:Array = rows.shift();
			
			var columnArray:Array;
			dataProvider = null;
			var typicalItemArray:Array = new Array();
			var firstRow:Array = rows[0];
			columnArray = header.map(
				function(title:String, index:int, a:Array):GridColumn
				{
					var dgc:GridColumn = new GridColumn(title);
					dgc.dataField = index;
					// if title is missing, override default headerText which is equal to dataField
					if (!title)
						dgc.headerText = '';
					if (firstRow)
					{
						var headerString:String = header[index] || '';
						// required to add additional characters - column width calculation 
						// is based on Header string length due to Bold font,
						headerString += StandardLib.lpad('', Math.ceil(headerString.length / 20), '0');
						// required to find either header string or first string has maximum length
						// and generate typicalitem object , which decides the column width.
						if (headerString.length > String(firstRow[index]).length)
							typicalItemArray[index] = headerString;
						else
							typicalItemArray[index] = firstRow[index];
					}
					return dgc;
				}
			);
			columns = new ArrayCollection(columnArray);
			typicalItem = typicalItemArray;
			dataProvider = new ArrayCollection(rows);
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
			var cols:Array = columns.toArray();
			// data rows from dataProvider, reordered according to new column order
			var rows:Array = ac.source.map(
				function(row:Array, i:int, rows:Array):Array {
					return row.map(
						function(value:*, i:int, row:Array):* {
							return row[(cols[i] as GridColumn).dataField];
						}
					);
				}
			);
			// header row from possibly reordered columns
			rows.unshift(cols.map(
				function(col:GridColumn, i:int, a:Array):* {
					return col.headerText;
				}
			));
			return rows;
		}
	}
}

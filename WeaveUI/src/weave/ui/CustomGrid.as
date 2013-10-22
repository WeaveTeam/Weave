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
package weave.ui
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import mx.containers.Grid;
	import mx.containers.GridItem;
	import mx.containers.GridRow;
	
	[DefaultProperty("dataProvider")]
	
	/**
	 * Adds properties: dataProvider, generator, visitor
	 */
	public class CustomGrid extends Grid
	{
		private var _dataProviderChanged:Boolean = false;
		private var _dataProvider:Array = [];
		private var _generator:Function;
		private var _visitor:Function;
		
		/**
		 * Setting this will generate a table of GridRow and GridItem objects.
		 * The horizontalAlign and verticalAlign styles of this Grid will be copied to each GridItem.
		 * @param table A two-dimensional Array of items to generate a Grid from.
		 */
		public function set dataProvider(table:Array):void
		{
			_dataProvider = table || [];
			_dataProviderChanged = true;
			invalidateProperties();
		}
		
		/**
		 * @param generator A function that generates a DisplayObject from an item in the dataProvider.
		 */
		public function set generator(func:Function):void
		{
			_generator = func;
			_dataProviderChanged = true;
			invalidateProperties();
		}
		
		/**
		 * @param generator A function that will be passed each GridItem object that is generated.
		 */
		public function set visitor(func:Function):void
		{
			_visitor = func;
			_dataProviderChanged = true;
			invalidateProperties();
		}
		
		override public function validateProperties():void
		{
			if (_dataProviderChanged)
			{
				_dataProviderChanged = false;
				populateGrid(this, _dataProvider, _generator, _visitor);
			}
			super.validateProperties();
		}
		
		/**
		 * Populates a Grid with a set of items.  It also copies the horizontalAlign and verticalAlign styles from the Grid to each GridItem.
		 * @param grid A Grid container.
		 * @param items A two-dimensional Array of items
		 * @param generator A function that accepts an item and returns a DisplayObject.
		 * @param visitor A function that accepts a GridItem object.
		 */
		public static function populateGrid(grid:Grid, dataProvider:Array, generator:Function = null, visitor:Function = null):void
		{
			var gridRows:Array = initChildren(grid, dataProvider.length, GridRow);
			for (var r:int = 0; r < gridRows.length; r++)
			{
				var dataRow:Array = dataProvider[r] as Array || [];
				var gridRow:GridRow = gridRows[r] as GridRow;
				var gridItems:Array = initChildren(gridRow, dataRow.length, GridItem);
				grid.addChild(gridRow);
				for (var c:int = 0; c < gridItems.length; c++)
				{
					var gridItem:GridItem = gridItems[c] as GridItem;
					initChildren(gridItem, 0, null);
					gridRow.addChild(gridItem);
					var dataItem:Object = dataRow[c];
					var displayObject:DisplayObject = generator is Function
						? generator(dataItem) as DisplayObject
						: dataItem as DisplayObject;
					if (displayObject)
						gridItem.addChild(displayObject);
					
					for each (var style:String in ['horizontalAlign', 'verticalAlign'])
						gridItem.setStyle(style, grid.getStyle(style));
					
					if (visitor is Function)
						visitor(gridItem);
				}
			}
		}
		
		private static function initChildren(container:DisplayObjectContainer, desiredNumber:int, type:Class):Array
		{
			// remove extra children
			while (container.numChildren > desiredNumber)
				container.removeChildAt(container.numChildren - 1);
			
			var result:Array = [];
			for (var i:int = 0; i < desiredNumber; i++)
			{
				if (i < container.numChildren) // existing child
					result.push(container.getChildAt(i));
				else // new child
					result.push(container.addChild(new type()));
			}
			return result;
		}
	}
}
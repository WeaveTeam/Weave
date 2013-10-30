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
	import avmplus.getQualifiedClassName;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import mx.containers.Grid;
	import mx.containers.GridItem;
	import mx.containers.GridRow;
	import mx.core.Container;
	
	import weave.core.ClassUtils;
	
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
		 * @param generator A Class that extends Container, or a Function that accepts an item and returns a DisplayObject.
		 * @param visitor A function that accepts a GridItem object.
		 */
		public static function populateGrid(grid:Grid, dataProvider:Array, generator:Object = null, visitor:Function = null):void
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
					var children:Array = initChildren(gridItem, 1, generator as Class);
					gridRow.addChild(gridItem);
					var dataItem:Object = dataRow[c];
					var displayObject:DisplayObject = dataItem as DisplayObject;
					if (generator is Function)
					{
						displayObject = generator(dataItem) as DisplayObject;
					}
					else if (generator is Class)
					{
						if (!ClassUtils.classExtends(getQualifiedClassName(generator), getQualifiedClassName(Container)))
							throw new Error("If generator is a Class, it must extend Container.");
						var GeneratorClass:Class = generator as Class;
						var container:Container = (children[0] as GeneratorClass || new GeneratorClass()) as Container;
						if (container)
						{
							displayObject = container;
							container.data = dataItem;
						}
					}
					if (displayObject)
						gridItem.addChild(displayObject);
					for each (var style:String in ['horizontalAlign', 'verticalAlign'])
						gridItem.setStyle(style, grid.getStyle(style));
					
					if (visitor is Function)
						visitor(gridItem);
				}
			}
		}
		
		private static function initChildren(container:DisplayObjectContainer, desiredNumber:uint, type:Class):Array
		{
			// remove unwanted children
			var i:int = container.numChildren;
			while (i-- && type && !(container.getChildAt(0) is type))
				container.removeChildAt(i);
			
			// remove extra children
			i = container.numChildren;
			while (i-- > desiredNumber)
				container.removeChildAt(i);
			
			var result:Array = [];
			for (i = 0; i < desiredNumber; i++)
			{
				if (i < container.numChildren) // existing child
					result.push(container.getChildAt(i));
				else if (type) // new child
					result.push(container.addChild(new type()));
			}
			return result;
		}
	}
}
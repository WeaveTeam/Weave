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

package weave.radviz
{
	import flash.utils.Dictionary;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.core.CallbackCollection;
	import weave.core.LinkableHashMap;
	import weave.utils.DebugTimer;

	/**
	 * An abstract class with a callback collection which implements ILayoutAlgorithm
	 * @author kmanohar
	 */	
	public class AbstractLayoutAlgorithm extends CallbackCollection implements ILayoutAlgorithm
	{
		public function AbstractLayoutAlgorithm()
		{
			
		}
		
		private var _unorderedLayout:Array = new Array();
		
		public var orderedLayout:Array = new Array();
		
		/**
		 * @param array An array of IAttributeColumns
		 */		
		public function set unorderedLayout(array:Array):void
		{
			_unorderedLayout = array;
		}
		
		/**
		 * @return An array of unordered IAttributeColumns
		 */		
		public function get unorderedLayout():Array
		{
			return _unorderedLayout;
		}
		
		/**
		 * @param keyNumberMap recordKey->column->value mapping to speed up computation 
		 */		
		public var keyNumberMap:Dictionary;
						
		/**
		 * Runs the layout algorithm and calls performLayout() 
		 * @param array An array of IAttributeColumns to reorder
		 * @param keyNumberMap recordKey->column->value mapping to speed up computation
		 * @return An ordered array of IAttributeColumns
		 */	
		public function run(array:Array, keyNumberHashMap:Dictionary):Array
		{
			if(!array.length) 
				return null;
			
			if(!keyNumberHashMap)
				return null;
			
			DebugTimer.begin();
			
			this.keyNumberMap = keyNumberHashMap;
			orderedLayout = [];			
			performLayout(array);	
			
			DebugTimer.end('layout algorithm');
			
			return orderedLayout;
		}
		
		/**
		 * Classes that extend LayoutAlgorithm must implement this function 
		 * @param columns An array of IAttributeColumns
		 */		
		public function performLayout(columns:Array):void
		{
			// empty
		}
	}
}
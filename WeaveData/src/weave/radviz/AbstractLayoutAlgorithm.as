/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.radviz
{
	import flash.utils.Dictionary;
	
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.core.CallbackCollection;
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
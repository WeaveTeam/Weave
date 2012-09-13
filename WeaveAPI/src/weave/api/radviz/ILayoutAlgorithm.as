/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */
package weave.api.radviz
{
	import flash.utils.Dictionary;
	
	import weave.api.core.ICallbackCollection;

	/**
	 * An interface for dimensional layout algorithms
	 * 
	 * @author kmanohar
	 * 
	 */	
	public interface ILayoutAlgorithm extends ICallbackCollection
	{
		/**
		 * Runs the layout algorithm and calls performLayout() 
		 * @param array An array of IAttributeColumns to reorder
		 * @param keyNumberHashMap hash map to speed up computation
		 * @return An ordered array of IAttributeColumns
		 */		
		function run(array:Array, keyNumberHashMap:Dictionary):Array;
		
		/**
		 * Performs the calculations to reorder an array  
		 * @param columns an array of IAttributeColumns
		 */		
		function performLayout(columns:Array):void;		
	
	}
}
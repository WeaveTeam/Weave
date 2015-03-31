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

package weave.ui.DataMiningEditors
{
	import flash.utils.Dictionary;

	public class DataMiningAlgorithmObject
	{
		/**
		 *For each data mining algorithm selected, this object is created
		 * Parameters : parameterMapping which stores a mapping of name of parameter to its value
		 *             isSelectedInAlgorithmList tell us whether this algorithm has been selected to run or not
		 *             label tells us the name of the algorithm
		 * @spurushe
		 **/
		
		//tells us the name of the algorithm
		[Bindable]
		public var label:String;
		
		public var parameters:Array = new Array();// tells us the parameters needed for the algorithm. Each algorithm will have a different number of parameters
		
		
		/* default is false. When selected it becomes true
		 * tells us if an algorithm is selected in the list for running algorithms in R*/
		[Bindable]
		public var isSelectedInAlgorithmList:Boolean = false; 
		
		//maps the name of the parameter to its value for a dataminingObject
		public var parameterMapping:Dictionary = new Dictionary();
		
		
		public function DataMiningAlgorithmObject()
		{
			super();
		}
	}
}
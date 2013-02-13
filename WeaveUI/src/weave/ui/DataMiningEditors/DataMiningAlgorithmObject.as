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
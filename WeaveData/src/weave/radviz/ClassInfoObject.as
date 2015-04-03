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

	public class ClassInfoObject
	{
		public var columnMapping:Dictionary = new Dictionary();//stores a map of columnName as key and ColumnValues as its(the key's) values
		
		public var tStatisticArray:Array = new Array();//stores all the t-statistics of each column for a given type
		
		public var pValuesArray:Array = new Array();//stores all the p-values of esch column for a given type
		
		
		
		
		public function ClassInfoObject()
		{
		}
		
		
	}
}
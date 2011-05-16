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

package weave.data.BinningDefinitions
{
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.core.LinkableDynamicObject;
	
	/**
	 * This provides a wrapper for a dynamically created IBinningDefinition.
	 */
	public class DynamicBinningDefinition extends LinkableDynamicObject implements IBinningDefinition
	{
		public function DynamicBinningDefinition()
		{
			super(IBinningDefinition);
		}
		
		/**
		 * This function lets you skip the step of casting internalObject as an IBinningDefinition.
		 */
		public function get internalBinningDefinition():IBinningDefinition
		{
			return internalObject as IBinningDefinition;
		}
		
		/************************************
		 * Begin IBinningDefinition interface
		 ************************************/

		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			if (internalBinningDefinition)
				internalBinningDefinition.getBinClassifiersForColumn(column, output);
			else
				output.removeAllObjects();
		}
	}
}

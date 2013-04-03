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
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinClassifier;
	import weave.api.data.IBinningDefinition;
	import weave.core.LinkableHashMap;
	
	/**
	 * Defines bins explicitly and is not affected by what column is passed to generateBinClassifiersForColumn().
	 * 
	 * @author adufilie
	 */
	public class ExplicitBinningDefinition extends LinkableHashMap implements IBinningDefinition
	{
		public function ExplicitBinningDefinition()
		{
			super(IBinClassifier);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get asyncResultCallbacks():ICallbackCollection
		{
			return this; // when our callbacks trigger, the results are immediately available
		}

		/**
		 * @inheritDoc
		 */
		public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			// do nothing because our bins don't depend on any column.
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinClassifiers():Array
		{
			return getObjects();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinNames():Array
		{
			return getNames();
		}
	}
}

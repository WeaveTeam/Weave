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
	import weave.api.copySessionState;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.data.BinClassifiers.BinClassifierCollection;
	
	/**
	 * An ExplicitBinningDefinition defines all the bins explicitly rather than indirectly.
	 * 
	 * @author adufilie
	 */
	public class ExplicitBinningDefinition extends BinClassifierCollection implements IBinningDefinition
	{
		public function ExplicitBinningDefinition()
		{
			super();
		}

		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			copySessionState(this, output);
		}
	}
}

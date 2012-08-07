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
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackJuggler;
	import weave.core.LinkableString;
	import weave.utils.VectorUtils;

	public class AbstractBinningDefinition implements IBinningDefinition
	{
		public function AbstractBinningDefinition()
		{
		}
		
		protected const _statsJuggler:CallbackJuggler = new CallbackJuggler(this, handleStatsChange, false);
		protected function handleStatsChange():void
		{
			// hack -- trigger callbacks so bins will be recalculated
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public const overrideBinNames:LinkableString = registerLinkableChild(this, new LinkableString(''));
		
		private var names:Array = [];
		protected function getOverrideNames():Array
		{
			if (detectLinkableObjectChange(getOverrideNames, overrideBinNames))
				names = VectorUtils.flatten( WeaveAPI.CSVParser.parseCSV(overrideBinNames.value) );
			return names;
		}
		
		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			throw new Error("Not implemented");
		}
	}
}

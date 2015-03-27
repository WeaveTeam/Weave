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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinClassifier;
	import weave.api.data.IBinningDefinition;
	import weave.api.detectLinkableObjectChange;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;

	/**
	 * Extend this class and implement <code>generateBinClassifiersForColumn()</code>, which should store its results in the
	 * protected <code>output</code> variable and trigger <code>asyncResultCallbacks</code> when the task completes.
	 * 
	 * @author adufilie
	 */
	public class AbstractBinningDefinition implements IBinningDefinition
	{
		public function AbstractBinningDefinition(allowOverrideBinNames:Boolean, allowOverrideInputRange:Boolean)
		{
			if (allowOverrideBinNames)
				_overrideBinNames = registerLinkableChild(this, new LinkableString(''));
			
			if (allowOverrideInputRange)
			{
				_overrideInputMin = newLinkableChild(this, LinkableNumber);
				_overrideInputMax = newLinkableChild(this, LinkableNumber);
			}
		}
		
		/**
		 * Implementations that extend this class should use this as an output buffer.
		 */		
		protected var output:ILinkableHashMap = registerDisposableChild(this, new LinkableHashMap(IBinClassifier));
		private const _asyncResultCallbacks:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		
		/**
		 * @inheritDoc
		 */
		public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			throw new Error("Not implemented");
		}
		
		/**
		 * @inheritDoc
		 */		
		public function get asyncResultCallbacks():ICallbackCollection
		{
			return _asyncResultCallbacks;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinNames():Array
		{
			if (linkableObjectIsBusy(this))
				return null;
			return output.getNames();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinClassifiers():Array
		{
			if (linkableObjectIsBusy(this))
				return null;
			return output.getObjects();
		}
		
		//-------------------
		
		private var _overrideBinNames:LinkableString;
		private var _overrideInputMin:LinkableNumber;
		private var _overrideInputMax:LinkableNumber;
		private var _overrideBinNamesArray:Array = [];
		
		public function get overrideBinNames():LinkableString { return _overrideBinNames; }
		public function get overrideInputMin():LinkableNumber { return _overrideInputMin; }
		public function get overrideInputMax():LinkableNumber { return _overrideInputMax; }
		
		protected function getOverrideNames():Array
		{
			if (overrideBinNames && detectLinkableObjectChange(getOverrideNames, overrideBinNames))
				_overrideBinNamesArray = WeaveAPI.CSVParser.parseCSVRow(overrideBinNames.value) || [];
			return _overrideBinNamesArray;
		}
	}
}

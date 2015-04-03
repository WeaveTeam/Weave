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

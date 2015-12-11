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

package weavejs.data.bin
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IBinClassifier;
	import weavejs.api.data.IBinningDefinition;
	import weavejs.core.CallbackCollection;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableNumber;
	import weavejs.core.LinkableString;

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
				_overrideBinNames = Weave.linkableChild(this, new LinkableString(''));
			
			if (allowOverrideInputRange)
			{
				_overrideInputMin = Weave.linkableChild(this, LinkableNumber);
				_overrideInputMax = Weave.linkableChild(this, LinkableNumber);
			}
		}
		
		/**
		 * Implementations that extend this class should use this as an output buffer.
		 */		
		protected var output:ILinkableHashMap = Weave.disposableChild(this, new LinkableHashMap(IBinClassifier));
		private var _asyncResultCallbacks:ICallbackCollection = Weave.disposableChild(this, CallbackCollection);
		
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
			if (Weave.isBusy(this))
				return null;
			return output.getNames();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinClassifiers():Array
		{
			if (Weave.isBusy(this))
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
			if (overrideBinNames && Weave.detectChange(getOverrideNames, overrideBinNames))
				_overrideBinNamesArray = WeaveAPI.CSVParser.parseCSVRow(overrideBinNames.value) || [];
			return _overrideBinNamesArray;
		}
	}
}

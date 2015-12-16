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
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IBinClassifier;
	import weavejs.api.data.IBinningDefinition;
	import weavejs.core.LinkableHashMap;
	
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

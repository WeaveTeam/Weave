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

package weave.graphs
{
	import weave.api.graphs.IGraphAlgorithm;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;

	/**
	 * This is a wrapper around an IGraphAlgorithm
	 * 
	 * @author kmonico
	 */	
	public class DynamicGraphAlgorithm extends CallbackCollection
	{
		public function get internalObject():IGraphAlgorithm
		{
			return _internalObject;
		}
		
		public function setInternalObject(algorithmType:Class):void
		{
			_internalObject = registerLinkableChild(this, new algorithmType());
		}
		
		private var _internalObject:IGraphAlgorithm = null;
	}
}
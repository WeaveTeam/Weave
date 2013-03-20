/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.data
{
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	
	/**
	 * @author adufilie
	 */
	public interface IBinningDefinition extends ILinkableObject
	{
		/**
		 * This will begin an asynchronous task to generate a list of IBinClassifier objects.
		 * Only one task can be carried out at a time.
		 * The asyncResultCallbacks will be triggered when the task completes.
		 * 
		 * @param column A column for which to generate IBinClassifier objects.
		 * @param output The hash map to be used as an output buffer for generated IBinClassifier objects.
		 * @see weave.api.data.IBinClassifier
		 * @see #resultCallbacks
		 */
		function generateBinClassifiersForColumn(column:IAttributeColumn):void;
		
		/**
		 * These callbacks will be triggered when the current asynchronous task completes.
		 * The callbacks of the IBinningDefinition will NOT be triggered as a result of these callbacks triggering,
		 * so to know when the results change you must add a callback to this particular callback collection.
		 * @see #generateBinClassifiersForColumn()
		 * @see #getBinClassifiers()
		 * @see #getBinNames()
		 */		
		function get asyncResultCallbacks():ICallbackCollection;
		
		/**
		 * This accesses the result from the asynchronous task started by generateBinClassifiersForColumn().
		 * @return An Array of IBinClassifier objects, or null if the current task has not completed yet.
		 * @see #resultCallbacks
		 */
		function getBinClassifiers():Array;
		
		/**
		 * This accesses the result from the asynchronous task started by generateBinClassifiersForColumn().
		 * @return An Array of Strings, or null if the current task has not completed yet.
		 * @see #resultCallbacks
		 */
		function getBinNames():Array;
	}
}

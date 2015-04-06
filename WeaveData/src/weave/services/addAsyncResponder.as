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

package weave.services
{
	import mx.rpc.AsyncToken;

	/**
	 * This is shorthand for adding an AsyncResponder to an AsyncToken.
	 * @param destination The AsyncToken to add a responder to.
	 * @param result function(event:ResultEvent, token:Object = null):void
	 * @param fault function(event:FaultEvent, token:Object = null):void
	 * @param token Passed as a parameter to the result or fault function.
	 * 
	 * @author adufilie
	 */
	public function addAsyncResponder(destination:AsyncToken, result:Function, fault:Function = null, token:Object = null):void
	{
		DelayedAsyncResponder.addResponder(destination, result, fault, token);
		//destination.addResponder(new AsyncResponder(result, fault, token));
	}
}

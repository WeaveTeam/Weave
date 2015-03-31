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
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	use namespace mx_internal;
	
	/**
	 * This emulates an RPC service.
	 * 
	 * @author adufilie
	 */
	public class MockAsyncService
	{
		public function exampleFunction(param:Object):AsyncToken
		{
			if (!_currentToken)
				return callLater(exampleFunction, arguments);
			
			var result:Object = null;
			
			// code goes here
			
			return handleResult(result);
		}
		
		//////////////////////////////////////////////////
		
		protected var _currentToken:AsyncToken = null;
		
		protected function handleFault(e:Error):AsyncToken
		{
			_currentToken.applyFault(FaultEvent.createEvent(new Fault(String(e.errorID), e.name, e.message), _currentToken));
			return _currentToken;
		}
		
		protected function handleResult(value:Object):AsyncToken
		{
			_currentToken.applyResult(ResultEvent.createEvent(value, _currentToken));
			return _currentToken;
		}
		
		protected function callLater(method:Function, params:Array, token:AsyncToken = null):AsyncToken
		{
			if (token)
			{
				this._currentToken = token;
				try
				{
					method.apply(this, params);
				}
				catch (e:Error)
				{
					handleFault(e);
				}
				this._currentToken = null;
			}
			else
			{
				token = new AsyncToken();
				WeaveAPI.StageUtils.callLater(this, callLater, [method, params, token]);
			}
			return token;
		}
	}
}

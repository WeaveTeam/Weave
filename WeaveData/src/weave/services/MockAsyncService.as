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

package weave.services
{
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	
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
				WeaveAPI.StageUtils.callLater(this, callLater, [method, params, token], WeaveAPI.TASK_PRIORITY_3_PARSING);
			}
			return token;
		}
	}
}

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
	import mx.rpc.AsyncResponder;
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

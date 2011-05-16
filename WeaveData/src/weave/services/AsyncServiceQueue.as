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
	import weave.api.services.IAsyncService;
	
	/**
	 * AsyncServiceQueue
	 * 
	 * @author adufilie
	 */
	public class AsyncServiceQueue
	{
		/**
		 * @param asyncService The async service to create a queue for.
		 */
		public function AsyncServiceQueue(asyncService:IAsyncService)
		{
			_asyncService = asyncService;
		}
		
		private var _asyncService:IAsyncService;
		private const _queue:AsyncInvocationQueue = new AsyncInvocationQueue();

		/**
		 * generateQuery
		 * @param webMethod The name of the function to call on the WebService.
		 * @param parameters The parameters to the WebService function.
		 * @return A new DelayedAsyncCall object responsible for making the WebService call.
		 */
		public function generateQuery(methodName:String, methodParameters:Array):DelayedAsyncInvocation
		{
			return new DelayedAsyncInvocation(_asyncService, methodName, methodParameters);
		}

		/**
		 * generateAndPerformQuery
		 * Generates a new DelayedAsyncCall and performs it immediately.
		 * @param webMethod The name of the function to call on the WebService.
		 * @param parameters The parameters to the WebService function.
		 * @return A new DelayedAsyncCall object responsible for making the WebService call.
		 */
		public function generateAndPerformQuery(webMethod:String, parameters:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQuery(webMethod, parameters);
			query.invoke();
			return query;
		}

		/**
		 * generateQueryAndAddToQueue
		 * Generates a new DelayedAsyncCall and adds it to the queue.
		 * If useQueue is false, the query will be performed immediately.
		 * @param webMethod The name of the function to call on the WebService.
		 * @param parameters The parameters to the WebService function.
		 * @return A new DelayedAsyncCall object responsible for making the WebService call.
		 */
		public function generateQueryAndAddToQueue(webMethod:String, parameters:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQuery(webMethod, parameters);
			_queue.addToQueue(query);
			return query;
		}
	}
}

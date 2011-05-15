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

package org.oicweave.services
{
	import flash.events.Event;
	
	/**
	 * this class contains functions that handle a queue of remote procedure calls
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	public class AsyncInvocationQueue
	{
		public function AsyncInvocationQueue()
		{
		}

		// perform a query in the queue
		protected function performQuery(query:DelayedAsyncInvocation):void
		{
			//trace("performQuery (timeout = "+query.webService.requestTimeout+")",query.toString());
			query.addAsyncResponder(handleQueryResultOrFault, handleQueryResultOrFault, query);
			query.invoke();
		}
		
		// Queue to handle concurrent requests to be downloaded.
		private var _downloadQueue:Array = new Array();

		// interface to add a query to the download queue. 
		public function addToQueue(query:DelayedAsyncInvocation):void
		{
			//trace("addToQueue",query);
			
			// if this query has already been queued, then do not queue it again
			if (_downloadQueue.indexOf(query) >= 0)
			{
				//trace("already queued", query);
				return;
			}
			
			_downloadQueue.push(query);
			
			if(_downloadQueue.length == 1)
			{
				//trace("downloading immediately", query);
				performQuery(query);
			}
			else
			{
				//trace("added to queue", query);
			}
		}

		// returns the position of a query in the queue
		public function getQueuePosition(query:DelayedAsyncInvocation):int
		{
			return _downloadQueue.indexOf(query);
		}

		// interface to remove a specific query from the download queue
		// @return true if something was removed from the queue
		public function removeFromQueue(query:DelayedAsyncInvocation, removeEvenIfDownloading:Boolean = false):Boolean
		{
			if (query == null)
				return false;
			// see if the query is in the queue
			var index:int = _downloadQueue.indexOf(query);
			// stop if query not found in queue
			if (index < 0)
			{
				//trace("WARNING: query not found in queue", query);
				return false;
			}
			// stop if query is currently downloading and removeEvenIfDownloading is false
			if (index == 0 && !removeEvenIfDownloading)
				return false;
			
			//trace("remove from queue (position "+index+", length: "+_downloadQueue.length+")", query);
			
			// remove the query from the queue
			_downloadQueue.splice(index, 1);
			
			// if the position was 0, start downloading the next query
			if (index == 0 && _downloadQueue.length > 0)
			{
				//trace("perform next query", _downloadQueue[0] as DelayedAsyncCall);
				// get the next item in the list
				performQuery(_downloadQueue[0]);
			}
			return true;
		}
		
		// This function gets called when a query has been downloaded.  It will download the next query if available
		protected function handleQueryResultOrFault(event:Event, token:Object = null):void
		{
			removeFromQueue(token as DelayedAsyncInvocation, true);
		}
		
		public function removeQueriesOfOperationTypes(... operations):void
		{
			for each (var operation:String in operations)
			{
				// remove matching queries
				// stop when i == 0 because we don't want to remove the query that is currently being downloaded.
				for (var i:int = _downloadQueue.length - 1; i >= 1; i--)
				{
					if ((_downloadQueue[i] as DelayedAsyncInvocation).methodName == operation)
					{
						//trace("REMOVING QUERY",i);
						_downloadQueue.splice(i, 1);
					}
				}
			}
			//trace("remaining queries: " + _downloadQueue.length);
		}
	}
}

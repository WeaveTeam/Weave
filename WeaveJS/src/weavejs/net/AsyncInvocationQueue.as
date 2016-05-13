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

package weavejs.net
{	
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableObjectWithBusyStatus;
	import weavejs.util.JS;
	import weavejs.net.AMF3Servlet;
	import weavejs.util.WeavePromise;
	import weavejs.WeaveAPI;
	
	/**
	 * this class contains functions that handle a queue of remote procedure calls
	 * 
	 * @author adufilie
	 */
	public class AsyncInvocationQueue implements ILinkableObjectWithBusyStatus, IDisposableObject
	{
		public static var debug:Boolean = false;
		
		/**
		 * @param paused When set to true, no queries will be executed until begin() is called.
		 */
		public function AsyncInvocationQueue(paused:Boolean = false)
		{
			_paused = paused;
		}
		
		public function isBusy():Boolean
		{
			assertQueueValid();
			return _downloadQueue.length > 0;
		}
		
		public function dispose():void
		{
			assertQueueValid();
			for each (var query:WeavePromise in _downloadQueue)
				WeaveAPI.ProgressIndicator.removeTask(query);
			_downloadQueue.length = 0;
		}
		
		private var _paused:Boolean = false;
		
		/**
		 * If the 'paused' constructor parameter was set to true, use this function to start invoking queued queries.
		 */		
		public function begin():void
		{
			assertQueueValid();
			
			if (_paused)
			{
				_paused = false;
				
				for each (var query:WeavePromise in _downloadQueue)
					WeaveAPI.ProgressIndicator.addTask(query);
				
				if (_downloadQueue.length)
					performQuery(_downloadQueue[0]);
			}
		}

		private var map_queryToService: Object = new JS.WeakMap();

		// interface to add a query to the download queue. 
		public function addToQueue(query:WeavePromise/*/<any>/*/, service:AMF3Servlet):void
		{
			assertQueueValid();
			
			//trace("addToQueue",query);
			
			// if this query has already been queued, then do not queue it again
			if (_downloadQueue.indexOf(query) >= 0)
			{
				//trace("already queued", query);
				return;
			}
			
			if (!_paused)
				WeaveAPI.ProgressIndicator.addTask(query);

			map_queryToService.set(query, service);
			
			if (debug)
			{
				query.then(
					function(result:*):void
					{
						JS.log('Query returned: ', query);
					},
					function (fault:*):void
					{
						JS.log('Query failed: ', query);
					}
				);
			}

			
			_downloadQueue.push(query);
			
			if (!_paused && _downloadQueue.length == 1)
			{
				//trace("downloading immediately", query);
				performQuery(query);
			}
			else
			{
				//trace("added to queue", query);
			}
		}
	
		// Queue to handle concurrent requests to be downloaded.
		private var _downloadQueue:Array = new Array();

		// perform a query in the queue
		protected function performQuery(query:WeavePromise/*/<any>/*/):void
		{
			assertQueueValid();
			
			//trace("performQuery (timeout = "+query.webService.requestTimeout+")",query.toString());
			//
			
			query.then(
				function (result:*):void {handleQueryResultOrFault(result, query)},
				function (fault:*):void {handleQueryResultOrFault(fault, query)}
			);
			
			//URLRequestUtils.reportProgress = false;
			
			
			var service:AMF3Servlet = map_queryToService.get(query);

			if (service)
			{
				if (debug)
					JS.log('Query sent: ' + query);
				service.invokeDeferred(query);
			}
			else
				if (debug) JS.log('Query had no associated service: ', query);
			
			//URLRequestUtils.reportProgress = true;
		}
		
		// This function gets called when a query has been downloaded.  It will download the next query if available
		protected function handleQueryResultOrFault(result:*, query:WeavePromise/*/<any>/*/):void
		{
			if (Weave.wasDisposed(this))
				return;
			
			WeaveAPI.ProgressIndicator.removeTask(query);
			
			// see if the query is in the queue
			var index:int = _downloadQueue.indexOf(query);
			// stop if query not found in queue
			if (index < 0)
			{
				JS.log("Query not found in queue: " + query);
				return;
			}
			
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
			return;
		}
		
		private function assertQueueValid():void
		{
			if (Weave.wasDisposed(this))
				throw new Error("AsyncInvocationQueue was already disposed");
		}
	}
}

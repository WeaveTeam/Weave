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
	import flash.utils.Dictionary;
	
	import org.oicweave.core.CallbackCollection;
	import org.oicweave.api.core.ICallbackCollection;

	/**
	 * This class is used as a central location for reporting the progress of pending asynchronous requests.
	 * 
	 * @author adufilie
	 */
	public class ProgressIndicator
	{
		/**
		 * This is the callback interface for detecting when pendingRequestCount changes.
		 */
		public static const callbacks:ICallbackCollection = new CallbackCollection();

		/**
		 * This is the number of pending requests (Read-only).
		 */
		public static function get pendingRequestCount():int
		{
			return _tokenCount;
		}

		/**
		 * This function will register a pending request token and increase the pendingRequestCount if necessary.
		 */
		public static function addPendingRequest(token:Object):void
		{
			reportPendingRequestProgress(token, 0);
		}
		
		public static function reportPendingRequestProgress(token:Object, percent:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (_tokenToProgressMap[token] == undefined)
			{
				_tokenCount++;
				_maxTokenCount++;
			}
			_tokenToProgressMap[token] = percent;
			callbacks.triggerCallbacks();
		}
		
		/**
		 * This function will remove a previously registered pending request token and decrease the pendingRequestCount if necessary.
		 */
		public static function removePendingRequest(token:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (_tokenToProgressMap[token] == undefined)
				return;
			
			delete _tokenToProgressMap[token];
			_tokenCount--;
			// reset max count when count goes to zero
			if (_tokenCount == 0)
				_maxTokenCount = 0;
			
			callbacks.triggerCallbacks();
		}
		
		/**
		 * This function checks the overall progress of all pending requests.
		 * @return A Number between 0 and 1.
		 */
		public static function getNormalizedProgress():Number
		{
			// add up the percentages
			var sum:Number = 0;
			for each (var percentage:Number in _pendingRequestToPercentMap)
				sum += percentage;
			// make any pending requests that no longer exist count as 100% done
			sum += _maxTokenCount - _tokenCount;
			// divide by the max count to get overall percentage
			return sum / _maxTokenCount;
		}

		private static var _tokenCount:int = 0;
		private static var _maxTokenCount:int = 0;
		private static const _pendingRequestToPercentMap:Dictionary = new Dictionary();
		private static const _tokenToProgressMap:Dictionary = new Dictionary();
	}
}

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
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IProgressIndicator;
	import weave.core.CallbackCollection;

	/**
	 * This class is used as a central location for reporting the progress of pending asynchronous requests.
	 * 
	 * @author adufilie
	 */
	public class ProgressIndicator implements IProgressIndicator
	{
		/**
		 * This is the singleton instance of this class.
		 */
		public static function get instance():ProgressIndicator
		{
			return WeaveAPI.ProgressIndicator as ProgressIndicator;
		}
		
		public function getCallbackCollection():ICallbackCollection
		{
			return _callbacks;
		}

		/**
		 * This is the number of pending requests (Read-only).
		 */
		public function getPendingRequestCount():int
		{
			return _tokenCount;
		}

		/**
		 * This function will register a pending request token and increase the pendingRequestCount if necessary.
		 */
		public function addPendingRequest(token:Object):void
		{
			reportPendingRequestProgress(token, 0);
		}
		
		public function reportPendingRequestProgress(token:Object, percent:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (_tokenToProgressMap[token] == undefined)
			{
				_tokenCount++;
				_maxTokenCount++;
			}
			_tokenToProgressMap[token] = percent;
			_callbacks.triggerCallbacks();
		}
		
		/**
		 * This function will remove a previously registered pending request token and decrease the pendingRequestCount if necessary.
		 */
		public function removePendingRequest(token:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (_tokenToProgressMap[token] == undefined)
				return;
			
			delete _tokenToProgressMap[token];
			_tokenCount--;
			// reset max count when count goes to zero
			if (_tokenCount == 0)
				_maxTokenCount = 0;
			
			_callbacks.triggerCallbacks();
		}
		
		/**
		 * This function checks the overall progress of all pending requests.
		 * @return A Number between 0 and 1.
		 */
		public function getNormalizedProgress():Number
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

		private const _callbacks:ICallbackCollection = new CallbackCollection();
		private var _tokenCount:int = 0;
		private var _maxTokenCount:int = 0;
		private const _pendingRequestToPercentMap:Dictionary = new Dictionary();
		private const _tokenToProgressMap:Dictionary = new Dictionary();
	}
}

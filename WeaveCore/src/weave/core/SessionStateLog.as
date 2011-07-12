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

package weave.core
{
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.registerDisposableChild;
	import weave.api.setSessionState;

	/**
	 * This class records the session history of an ILinkableObject.
	 * 
	 * @author adufilie
	 */
	public class SessionStateLog implements ILinkableObject, IDisposableObject
	{
		public function SessionStateLog(subject:ILinkableObject)
		{
			_subject = subject;
			_prevState = getSessionState(_subject); // remember the initial state
			registerDisposableChild(_subject, this); // make sure this is disposed when _subject is disposed
			
			var cc:ICallbackCollection = getCallbackCollection(_subject);
			cc.addImmediateCallback(this, immediateCallback);
			cc.addGroupedCallback(this, groupedCallback);
		}
		
		public function dispose():void
		{
			_subject = null;
			_history = null;
			_future = null;
		}
		
		private var _subject:ILinkableObject;
		private var _prevState:Object = null;
		private var _history:Array = [];
		private var _future:Array = [];
		private var _serial:int = 0;
		private var _undoActive:Boolean = false;
		
		private var _recordLater:Boolean = false;
		private var _pendingRecord:Boolean = false;
		
		private function immediateCallback():void
		{
			// we have to wait until grouped callbacks are called before we record the diff
			_recordLater = true;
			
			// make sure only one call to recordDiff() is pending
			if (!_pendingRecord)
			{
				_pendingRecord = true;
				recordDiff();
			}
		}
		
		private function groupedCallback():void
		{
			// It is ok to record a diff the frame after grouped callbacks are called.
			// If callbacks are triggered again before the next frame, the immediateCallback will set this flag back to true.
			_recordLater = false;
		}
		
		private function recordDiff():void
		{
			if (_recordLater)
			{
				// we have to wait until the next frame to record the diff because grouped callbacks haven't finished.
				StageUtils.callLater(this, recordDiff, null, false);
				return;
			}
			
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			var state:Object = getSessionState(_subject);
			var forwardDiff:* = WeaveAPI.SessionManager.computeDiff(_prevState, state);
			if (forwardDiff !== undefined)
			{
				var backwardDiff:* = WeaveAPI.SessionManager.computeDiff(state, _prevState);
				if (_undoActive)
					_future.unshift(new LogEntry(_serial++, backwardDiff, forwardDiff)); // reverse
				else
					_history.push(new LogEntry(_serial++, forwardDiff, backwardDiff));
				
				debugHistory(true);
				
				cc.triggerCallbacks();
			}
			
			_prevState = state;
			_undoActive = false;
			_pendingRecord = false;
			
			cc.resumeCallbacks();
		}

		private function debugHistory(showLastDiff:Boolean):void
		{
			var h:Array = _history.concat();
			for (var i:int = 0; i < h.length; i++)
				h[i] = h[i].id;
			var f:Array = _future.concat();
			for (i = 0; i < f.length; i++)
				f[i] = f[i].id;
			if (_history.length > 0)
			{
				var item:LogEntry = _history[_history.length - 1];
				trace("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
				trace('NEW HISTORY (backward) ' + item.id + ':', ObjectUtil.toString(item.backward));
				trace("===============================================================");
				trace('NEW HISTORY (forward) ' + item.id + ':', ObjectUtil.toString(item.forward));
				trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
			}
			trace('history ['+h+']','future ['+f+']');
		}
		
		public function undo():void
		{
			if (_history.length > 0)
			{
				_undoActive = true;
				var item:LogEntry = _history.pop();
				_future.unshift(item);
				
				trace('apply undo ' + item.id + ':', ObjectUtil.toString(item.backward));
				setSessionState(_subject, item.backward, false);
				_prevState = getSessionState(_subject);
				
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		public function redo():void
		{
			if (_future.length > 0)
			{
				var item:LogEntry = _future.shift();
				history.push(item);
				
				trace('apply redo ' + item.id + ':',ObjectUtil.toString(item.forward));
				setSessionState(_subject, item.forward, false);
				_prevState = getSessionState(_subject);
				
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		public function get history():Array
		{
			return _history;
		}
		
		public function get future():Array
		{
			return _future;
		}
	}
}

internal class LogEntry
{
	public function LogEntry(id:int, forward:Object, backward:Object)
	{
		this.id = id;
		this.forward = forward;
		this.backward = backward;
	}
	
	public var id:int;
	public var forward:Object;
	public var backward:Object;
}

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
	 * This class saves the session history of an ILinkableObject.
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
		
		private var debug:Boolean = false;
		
		public function dispose():void
		{
			_subject = null;
			_undoHistory = null;
			_redoHistory = null;
		}
		
		private var _subject:ILinkableObject;
		private var _prevState:Object = null;
		private var _undoHistory:Array = [];
		private var _redoHistory:Array = [];
		private var _serial:int = 0;
		private var _undoActive:Boolean = false;
		private var _redoActive:Boolean = false;
		
		private var _saveLater:Boolean = false;
		private var _savePending:Boolean = false;
		
		private function immediateCallback():void
		{
			// we have to wait until grouped callbacks are called before we save the diff
			_saveLater = true;
			
			// make sure only one call to saveDiff() is pending
			if (!_savePending)
			{
				_savePending = true;
				saveDiff();
			}
		}
		
		private function groupedCallback():void
		{
			// Since grouped callbacks are currently running, it means something changed, so make sure the diff is saved.
			immediateCallback();
			// It is ok to save a diff the frame after grouped callbacks are called.
			// If callbacks are triggered again before the next frame, the immediateCallback will set this flag back to true.
			_saveLater = false;
		}
		
		private function saveDiff(immediately:Boolean = false):void
		{
			if (_saveLater && !immediately)
			{
				// we have to wait until the next frame to save the diff because grouped callbacks haven't finished.
				StageUtils.callLater(this, saveDiff, null, false);
				return;
			}
			
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			var state:Object = getSessionState(_subject);
			var forwardDiff:* = WeaveAPI.SessionManager.computeDiff(_prevState, state);
			if (forwardDiff !== undefined)
			{
				var backwardDiff:* = WeaveAPI.SessionManager.computeDiff(state, _prevState);
				var item:LogEntry;
				if (_undoActive)
				{
					item = new LogEntry(_serial++, backwardDiff, forwardDiff);
					// overwrite first redo entry because grouped callbacks may have behaved differently
					_redoHistory[0] = item;
				}
				else
				{
					item = new LogEntry(_serial++, forwardDiff, backwardDiff);
					if (_redoActive)
					{
						// overwrite last undo entry because grouped callbacks may have behaved differently
						_undoHistory[_undoHistory.length - 1] = item;
					}
					else
					{
						// save new undo entry
						_undoHistory.push(item);
					}
				}
				
				if (debug)
					debugHistory(item);
				
				cc.triggerCallbacks();
			}
			
			_prevState = state;
			_undoActive = false;
			_redoActive = false;
			_savePending = false;
			
			cc.resumeCallbacks();
		}

		public function undo():void
		{
			if (_undoHistory.length > 0)
			{
				if (_undoActive || _redoActive) // if we are performing several consecutive undo/redo actions, avoid computing intermediate diffs
					_prevState = getSessionState(_subject);
				else if (_savePending) // otherwise, if the session state changed, compute the diff now
					saveDiff(true);
				
				var item:LogEntry = _undoHistory.pop();
				_redoHistory.unshift(item);
				if (debug)
					trace('apply undo ' + item.id + ':', ObjectUtil.toString(item.backward));
				setSessionState(_subject, item.backward, false);
				_undoActive = _savePending;
				_redoActive = false;
				
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		public function redo():void
		{
			if (_redoHistory.length > 0)
			{
				if (_undoActive || _redoActive) // if we are performing several consecutive undo/redo actions, avoid computing intermediate diffs
					_prevState = getSessionState(_subject);
				else if (_savePending) // otherwise, if session state changed, compute the diff now
					saveDiff(true);
				
				var item:LogEntry = _redoHistory.shift();
				_undoHistory.push(item);
				if (debug)
					trace('apply redo ' + item.id + ':',ObjectUtil.toString(item.forward));
				setSessionState(_subject, item.forward, false);
				_redoActive = _savePending;
				_undoActive = false;
				
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		public function get undoHistory():Array
		{
			return _undoHistory;
		}
		
		public function get redoHistory():Array
		{
			return _redoHistory;
		}

		private function debugHistory(logEntry:LogEntry):void
		{
			var h:Array = _undoHistory.concat();
			for (var i:int = 0; i < h.length; i++)
				h[i] = h[i].id;
			var f:Array = _redoHistory.concat();
			for (i = 0; i < f.length; i++)
				f[i] = f[i].id;
			if (logEntry)
			{
				var type:String = _redoActive ? "REDO" : "UNDO";
				trace("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
				trace('NEW ' + type + ' ENTRY (backward) ' + logEntry.id + ':', ObjectUtil.toString(logEntry.backward));
				trace("===============================================================");
				trace('NEW ' + type + ' ENTRY (forward) ' + logEntry.id + ':', ObjectUtil.toString(logEntry.forward));
				trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
			}
			trace('undo ['+h+']','redo ['+f+']');
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

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
	import flash.utils.ByteArray;
	
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
		public static var debug:Boolean = false;
		
		public function SessionStateLog(subject:ILinkableObject)
		{
			_subject = subject;
			_prevState = getSessionState(_subject); // remember the initial state
			registerDisposableChild(_subject, this); // make sure this is disposed when _subject is disposed
			
			var cc:ICallbackCollection = getCallbackCollection(_subject);
			cc.addImmediateCallback(this, immediateCallback);
			cc.addGroupedCallback(this, groupedCallback);
		}
		
		/**
		 * @inheritDoc
		 */		
		public function dispose():void
		{
			if (_undoHistory == null)
				throw new Error("SessionStateLog.dispose() called more than once");
			
			_subject = null;
			_undoHistory = null;
			_redoHistory = null;
		}
		
		private var _subject:ILinkableObject; // the object we are monitoring
		private var _prevState:Object = null; // the previously seen session state of the subject
		private var _undoHistory:Array = []; // diffs that can be undone
		private var _redoHistory:Array = []; // diffs that can be redone
		private var _serial:int = 0; // gets incremented each time a new diff is created
		private var _undoActive:Boolean = false; // true while an undo operation is active
		private var _redoActive:Boolean = false; // true while a redo operation is active
		
		private var _saveLater:Boolean = false; // true if the next diff should be computed and logged in a later frame
		private var _savePending:Boolean = false; // true when a diff should be computed
		private var _enableLogging:Boolean = true; // if true, diffs will be automatically logged
		
		/**
		 * When this is set to true, changes in the session state of the subject will be automatically logged.
		 */		
		public function get enableLogging():Boolean
		{
			return _enableLogging;
		}
		public function set enableLogging(value:Boolean):void
		{
			if (_enableLogging == value)
				return;
			
			_enableLogging = value;
			
			synchronizeNow();
		}
		
		/**
		 * This will clear all undo and redo history.
		 */
		public function clearHistory():void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			synchronizeNow();
			if (_undoHistory.length > 0 || _redoHistory.length > 0)
				cc.triggerCallbacks();
			_undoHistory.length = 0;
			_redoHistory.length = 0;
			
			cc.resumeCallbacks();
		}
		
		/**
		 * This gets called as an immediate callback of the subject.
		 */		
		private function immediateCallback():void
		{
			if (!_enableLogging)
				return;
			
			// we have to wait until grouped callbacks are called before we save the diff
			_saveLater = true;
			
			// make sure only one call to saveDiff() is pending
			if (!_savePending)
			{
				_savePending = true;
				saveDiff();
			}
			
			if (debug && (_undoActive || _redoActive))
			{
				var state:Object = getSessionState(_subject);
				var forwardDiff:* = WeaveAPI.SessionManager.computeDiff(_prevState, state);
				trace('immediate diff:', ObjectUtil.toString(forwardDiff));
			}
		}
		
		/**
		 * This gets called as a grouped callback of the subject.
		 */		
		private function groupedCallback():void
		{
			if (!_enableLogging)
				return;
			
			// Since grouped callbacks are currently running, it means something changed, so make sure the diff is saved.
			immediateCallback();
			// It is ok to save a diff the frame after grouped callbacks are called.
			// If callbacks are triggered again before the next frame, the immediateCallback will set this flag back to true.
			_saveLater = false;
			
			if (debug && (_undoActive || _redoActive))
			{
				var state:Object = getSessionState(_subject);
				var forwardDiff:* = WeaveAPI.SessionManager.computeDiff(_prevState, state);
				trace('grouped diff:', ObjectUtil.toString(forwardDiff));
			}
		}
		
		/**
		 * This will save a diff in the history, if there is any.
		 * @param immediately Set to true if it should be saved immediately, or false if it can wait.
		 */
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

		/**
		 * This function will save any pending diff in session state.
		 * Use this function only when necessary (for example, when writing a collaboration service that must synchronize).
		 */
		public function synchronizeNow():void
		{
			saveDiff(true);
		}
		
		/**
		 * This will undo a number of steps from the saved history.
		 * @param numberOfSteps The number of steps to undo.
		 */
		public function undo(numberOfSteps:int = 1):void
		{
			applyDiffs(-numberOfSteps);
		}
		
		/**
		 * This will redo a number of steps that have been previously undone.
		 * @param numberOfSteps The number of steps to redo.
		 */
		public function redo(numberOfSteps:int = 1):void
		{
			applyDiffs(numberOfSteps);
		}
		
		/**
		 * This will apply a number of undo or redo steps.
		 * @param delta The number of steps to undo (negative) or redo (positive).
		 */
		private function applyDiffs(delta:int):void
		{
			var stepsRemaining:int = Math.min(Math.abs(delta), delta < 0 ? _undoHistory.length : _redoHistory.length);
			if (stepsRemaining > 0)
			{
				var logEntry:LogEntry;
				var diff:Object;
				var debug:Boolean = debug && stepsRemaining == 1;
				
				// if something changed and we're not currently undoing/redoing, save the diff now
				if (_savePending && !_undoActive && !_redoActive)
					synchronizeNow();
				
				getCallbackCollection(_subject).delayCallbacks();
				while (stepsRemaining-- > 0)
				{
					if (delta < 0)
					{
						logEntry = _undoHistory.pop();
						_redoHistory.unshift(logEntry);
						diff = logEntry.backward;
					}
					else
					{
						logEntry = _redoHistory.shift();
						_undoHistory.push(logEntry);
						diff = logEntry.forward;
					}
					if (debug)
						trace('apply ' + (delta < 0 ? 'undo' : 'redo'), logEntry.id + ':', ObjectUtil.toString(diff));
					
					// remember the session state right before applying the last step
					if (stepsRemaining == 0)
						_prevState = getSessionState(_subject);
					setSessionState(_subject, diff, false);
					
					if (debug)
					{
						var newState:Object = getSessionState(_subject);
						var resultDiff:Object = WeaveAPI.SessionManager.computeDiff(_prevState, newState);
						trace('resulting diff:', ObjectUtil.toString(resultDiff));
					}
				}
				getCallbackCollection(_subject).resumeCallbacks();
				
				_undoActive = delta < 0 && _savePending;
				_redoActive = delta > 0 && _savePending;
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * @TODO create an interface for the objects in this Array
		 */
		public function get undoHistory():Array
		{
			return _undoHistory;
		}
		
		/**
		 * @TODO create an interface for the objects in this Array
		 */
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
				trace("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
				trace('NEW HISTORY (backward) ' + logEntry.id + ':', ObjectUtil.toString(logEntry.backward));
				trace("===============================================================");
				trace('NEW HISTORY (forward) ' + logEntry.id + ':', ObjectUtil.toString(logEntry.forward));
				trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
			}
			trace('undo ['+h+']','redo ['+f+']');
		}
		
		/**
		 * This version number is used to detect old history formats generated by serialize().
		 * This value should be incremented each time modifications to this class would result in a different serialization format.
		 */		
		private static const _serializationVersion:int = 0;
		
		/**
		 * This will write the session state log to a ByteArray.
		 * @param output The output ByteArray.
		 */
		public function serialize(output:ByteArray):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			synchronizeNow();
			
			output.writeInt(_serializationVersion);
			
			output.writeObject(_prevState);
			output.writeObject(_undoHistory);
			output.writeObject(_redoHistory);
			output.writeInt(_serial);
			output.writeBoolean(_enableLogging);
			
			cc.resumeCallbacks();
		}
		
		/**
		 * This will load a session state log from a ByteArray.
		 * @param input The ByteArray containing the output from seralize().
		 */
		public function deserialize(input:ByteArray):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			var version:int = input.readInt();
			if (version != _serializationVersion)
				throw new Error("Weave history format version " + version + " is unsupported.");
			
			_prevState = input.readObject();
			_undoHistory = LogEntry.convertGenericObjectsToLogEntries(input.readObject());
			_redoHistory = LogEntry.convertGenericObjectsToLogEntries(input.readObject());
			_serial = input.readInt();
			_enableLogging = input.readBoolean();
			
			_undoActive = false;
			_redoActive = false;
			_saveLater = false;
			_savePending = false;
			
			setSessionState(_subject, _prevState);
			
			cc.triggerCallbacks();
			cc.resumeCallbacks();
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
	
	/**
	 * This will convert an Array of generic objects to an Array of LogEntry objects.
	 * Generic objects are easier to create backwards compatibility for.
	 */
	public static function convertGenericObjectsToLogEntries(array:Array):Array
	{
		for (var i:int = 0; i < array.length; i++)
		{
			var o:Object = array[i];
			if (!(o is LogEntry))
				array[i] = new LogEntry(o.id, o.forward, o.backward);
		}
		return array;
	}
}

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
	import flash.utils.getTimer;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.getCallbackCollection;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;

	/**
	 * This class saves the session history of an ILinkableObject.
	 * 
	 * @author adufilie
	 */
	public class SessionStateLog implements ILinkableVariable, IDisposableObject
	{
		public static var debug:Boolean = false;
		public static var enableHistoryRewrite:Boolean = true; // should be set to true except for debugging
		
		public function SessionStateLog(subject:ILinkableObject, syncDelay:uint = 0)
		{
			_subject = subject;
			_syncDelay = syncDelay;
			_prevState = WeaveAPI.SessionManager.getSessionState(_subject); // remember the initial state
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
		private var _syncDelay:uint; // the number of milliseconds to wait before automatically synchronizing
		private var _prevState:Object = null; // the previously seen session state of the subject
		private var _undoHistory:Array = []; // diffs that can be undone
		private var _redoHistory:Array = []; // diffs that can be redone
		private var _nextId:int = 0; // gets incremented each time a new diff is created
		private var _undoActive:Boolean = false; // true while an undo operation is active
		private var _redoActive:Boolean = false; // true while a redo operation is active
		
		private var _syncTime:int = getTimer(); // this is set to getTimer() when synchronization occurs
		private var _triggerDelay:int = -1; // this is set to (getTimer() - _syncTime) when immediate callbacks are triggered for the first time since the last synchronization occurred
		private var _saveTime:uint = 0; // this is set to getTimer() + _syncDelay to determine when the next diff should be computed and logged
		private var _savePending:Boolean = false; // true when a diff should be computed
		
		/**
		 * When this is set to true, changes in the session state of the subject will be automatically logged.
		 */
		public const enableLogging:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), synchronizeNow);
		
		/**
		 * This will squash a sequence of undos or redos into a single undo or redo.
		 * @param directionalSquashCount Number of undos (negative) or redos (positive) to squash.
		 */		
		public function squashHistory(directionalSquashCount:int):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			synchronizeNow();

			var count:int = StandardLib.constrain(directionalSquashCount, -_undoHistory.length, _redoHistory.length);
			if (count < -1 || count > 1)
			{
				cc.triggerCallbacks();
				
				var entries:Array;
				if (count < 0)
					entries = _undoHistory.splice(_undoHistory.length + count, -count);
				else
					entries = _redoHistory.splice(0, count);
				
				var entry:LogEntry;
				var squashBackward:Object = null;
				var squashForward:Object = null;
				var totalDuration:int = 0;
				var totalDelay:int = 0;
				var last:int = entries.length - 1;
				for (var i:int = 0; i <= last; i++)
				{
					entry = entries[last - i] as LogEntry;
					squashBackward = WeaveAPI.SessionManager.combineDiff(squashBackward, entry.backward);
					
					entry = entries[i] as LogEntry;
					squashForward = WeaveAPI.SessionManager.combineDiff(squashForward, entry.forward);
					
					totalDuration += entry.diffDuration;
					totalDelay += entry.triggerDelay;
				}
				
				entry = new LogEntry(_nextId++, squashForward, squashBackward, totalDelay, totalDuration);
				if (count < 0)
					_undoHistory.push(entry);
				else
					_redoHistory.unshift(entry);
			}
			
			cc.resumeCallbacks();
		}
		
		/**
		 * This will clear all undo and redo history.
		 * @param directional Zero will clear everything. Set this to -1 to clear all undos or 1 to clear all redos.
		 */
		public function clearHistory(directional:int = 0):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			synchronizeNow();
			
			if (directional <= 0)
			{
				if (_undoHistory.length > 0)
					cc.triggerCallbacks();
				_undoHistory.length = 0;
			}
			if (directional >= 0)
			{
				if (_redoHistory.length > 0)
					cc.triggerCallbacks();
				_redoHistory.length = 0;
			}
			
			cc.resumeCallbacks();
		}
		
		/**
		 * This gets called as an immediate callback of the subject.
		 */		
		private function immediateCallback():void
		{
			if (!enableLogging.value)
				return;
			
			// we have to wait until grouped callbacks are called before we save the diff
			_saveTime = uint.MAX_VALUE;
			
			// make sure only one call to saveDiff() is pending
			if (!_savePending)
			{
				_savePending = true;
				saveDiff();
			}
			
			if (debug && (_undoActive || _redoActive))
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(_subject);
				var forwardDiff:* = WeaveAPI.SessionManager.computeDiff(_prevState, state);
				trace('immediate diff:', ObjectUtil.toString(forwardDiff));
			}
		}
		
		/**
		 * This gets called as a grouped callback of the subject.
		 */
		private function groupedCallback():void
		{
			if (!enableLogging.value)
				return;
			
			// Since grouped callbacks are currently running, it means something changed, so make sure the diff is saved.
			immediateCallback();
			// It is ok to save a diff some time after the last time grouped callbacks are called.
			// If callbacks are triggered again before the next frame, the immediateCallback will reset this value.
			_saveTime = getTimer() + _syncDelay;
			
			if (debug && (_undoActive || _redoActive))
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(_subject);
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
			if (!enableLogging.value)
			{
				_savePending = false;
				return;
			}
			
			var currentTime:int = getTimer();
			
			// remember how long it's been since the last synchronization
			if (_triggerDelay < 0)
				_triggerDelay = currentTime - _syncTime;
			
			if (!immediately && getTimer() < _saveTime)
			{
				// we have to wait until the next frame to save the diff because grouped callbacks haven't finished.
				WeaveAPI.StageUtils.callLater(this, saveDiff, null, WeaveAPI.TASK_PRIORITY_IMMEDIATE);
				return;
			}
			
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			var state:Object = WeaveAPI.SessionManager.getSessionState(_subject);
			var forwardDiff:* = WeaveAPI.SessionManager.computeDiff(_prevState, state);
			if (forwardDiff !== undefined)
			{
				var diffDuration:int = currentTime - (_syncTime + _triggerDelay);
				var backwardDiff:* = WeaveAPI.SessionManager.computeDiff(state, _prevState);
				var oldEntry:LogEntry;
				var newEntry:LogEntry;
				if (_undoActive)
				{
					// To prevent new undo history from being added as a result of applying an undo, overwrite first redo entry.
					// Keep existing delay/duration.
					oldEntry = _redoHistory[0] as LogEntry;
					newEntry = new LogEntry(_nextId++, backwardDiff, forwardDiff, oldEntry.triggerDelay, oldEntry.diffDuration);
					if (enableHistoryRewrite)
					{
						_redoHistory[0] = newEntry;
					}
					else if (ObjectUtil.compare(oldEntry.forward, newEntry.forward) != 0)
					{
						_redoHistory.unshift(newEntry);
					}
				}
				else
				{
					newEntry = new LogEntry(_nextId++, forwardDiff, backwardDiff, _triggerDelay, diffDuration);
					if (_redoActive)
					{
						// To prevent new undo history from being added as a result of applying a redo, overwrite last undo entry.
						// Keep existing delay/duration.
						oldEntry = _undoHistory.pop() as LogEntry;
						newEntry.triggerDelay = oldEntry.triggerDelay;
						newEntry.diffDuration = oldEntry.diffDuration;
						
						if (!enableHistoryRewrite && ObjectUtil.compare(oldEntry.forward, newEntry.forward) == 0)
							newEntry = oldEntry; // keep old entry
					}
					// save new undo entry
					_undoHistory.push(newEntry);
				}
				
				if (debug)
					debugHistory(newEntry);
				
				_syncTime = currentTime; // remember when diff was saved
				cc.triggerCallbacks();
			}
			
			// always reset sync time after undo/redo even if there was no new diff
			if (_undoActive || _redoActive)
				_syncTime = currentTime;
			_prevState = state;
			_undoActive = false;
			_redoActive = false;
			_savePending = false;
			_triggerDelay = -1;
			
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
				
				var combine:Boolean = stepsRemaining > 2;
				var baseDiff:Object = null;
				getCallbackCollection(_subject).delayCallbacks();
				// when logging is disabled, revert to previous state before applying diffs
				if (!enableLogging.value)
				{
					var state:Object = WeaveAPI.SessionManager.getSessionState(_subject);
					// baseDiff becomes the change that needs to occur to get back to the previous state
					baseDiff = WeaveAPI.SessionManager.computeDiff(state, _prevState);
					if (baseDiff != null)
						combine = true;
				}
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
					
					if (stepsRemaining == 0 && enableLogging.value)
					{
						// remember the session state right before applying the last step so we can rewrite the history if necessary
						_prevState = WeaveAPI.SessionManager.getSessionState(_subject);
					}
					
					if (combine)
					{
						baseDiff = WeaveAPI.SessionManager.combineDiff(baseDiff, diff);
						if (stepsRemaining <= 1)
						{
							WeaveAPI.SessionManager.setSessionState(_subject, baseDiff, false);
							combine = false;
						}
					}
					else
					{
						WeaveAPI.SessionManager.setSessionState(_subject, diff, false);
					}
					
					if (debug)
					{
						var newState:Object = WeaveAPI.SessionManager.getSessionState(_subject);
						var resultDiff:Object = WeaveAPI.SessionManager.computeDiff(_prevState, newState);
						trace('resulting diff:', ObjectUtil.toString(resultDiff));
					}
				}
				getCallbackCollection(_subject).resumeCallbacks();
				
				_undoActive = delta < 0 && _savePending;
				_redoActive = delta > 0 && _savePending;
				if (!_savePending)
					_prevState = WeaveAPI.SessionManager.getSessionState(_subject);
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
		 * This will generate an untyped session state object that contains the session history log.
		 * @return An object containing the session history log.
		 */		
		public function getSessionState():Object
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			synchronizeNow();
			
			// The "version" property can be used to detect old session state formats and should be incremented whenever the format is changed.
			var state:Object = {
				"version": 0,
				"currentState": _prevState,
				"undoHistory": _undoHistory.concat(),
				"redoHistory": _redoHistory.concat(),
				"nextId": _nextId
				// not including enableLogging
			};
			
			cc.resumeCallbacks();
			return state;
		}
		
		/**
		 * This will load a session state log from an untyped session state object.
		 * @param input The ByteArray containing the output from seralize().
		 */
		public function setSessionState(state:Object):void
		{
			// make sure callbacks only run once while we set the session state
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			enableLogging.delayCallbacks();
			try
			{
				var version:Number = state.version;
				switch (version)
				{
					case 0:
					{
						// note: some states from version 0 may include enableLogging, but here we ignore it
						
						_prevState = state.currentState;
						_undoHistory = LogEntry.convertGenericObjectsToLogEntries(state.undoHistory, _syncDelay);
						_redoHistory = LogEntry.convertGenericObjectsToLogEntries(state.redoHistory, _syncDelay);
						_nextId = state.nextId;
						
						break;
					}
					default:
						throw new Error("Weave history format version " + version + " is unsupported.");
				}
				
				// reset these flags so nothing unexpected happens in later frames
				_undoActive = false;
				_redoActive = false;
				_savePending = false;
				_saveTime = 0;
				_triggerDelay = -1;
				_syncTime = getTimer();
			
				WeaveAPI.SessionManager.setSessionState(_subject, _prevState);
			}
			finally
			{
				enableLogging.resumeCallbacks();
				cc.triggerCallbacks();
				cc.resumeCallbacks();
			}
		}
	}
}
import flash.utils.getTimer;

internal class LogEntry
{
	/**
	 * This is an entry in the session history log.  It contains both undo and redo session state diffs.
	 * The triggerDelay is the time it took for the user to make a change since the last synchronization.
	 * This time difference does not include the time it took to set the session state.  This way, when
	 * the session state is replayed at a reasonable speed regardless of the speed of the computer.
	 * @param id
	 * @param forward The diff for applying redo.
	 * @param backward The diff for applying undo.
	 * @param triggerDelay The length of time between the last synchronization and the diff.
	 */
	public function LogEntry(id:int, forward:Object, backward:Object, triggerDelay:int, diffDuration:int)
	{
		this.id = id;
		this.forward = forward;
		this.backward = backward;
		this.triggerDelay = triggerDelay;
		this.diffDuration = diffDuration;
	}
	
	public var id:int;
	public var forward:Object; // the diff for applying redo
	public var backward:Object; // the diff for applying undo
	public var triggerDelay:int; // the length of time between the last synchronization and the diff
	public var diffDuration:int; // the length of time in which the diff took place
	
	/**
	 * This will convert an Array of generic objects to an Array of LogEntry objects.
	 * Generic objects are easier to create backwards compatibility for.
	 */
	public static function convertGenericObjectsToLogEntries(array:Array, defaultTriggerDelay:int):Array
	{
		for (var i:int = 0; i < array.length; i++)
		{
			var o:Object = array[i];
			if (!(o is LogEntry))
				array[i] = new LogEntry(o.id, o.forward, o.backward, o.triggerDelay || defaultTriggerDelay, o.diffDuration);
		}
		return array;
	}
}

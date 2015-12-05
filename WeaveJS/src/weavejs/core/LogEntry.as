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

package weavejs.core
{
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
}

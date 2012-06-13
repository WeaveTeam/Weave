/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.core
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	/**
	 * This allows you to add callbacks that will be called when an event occurs on the stage.
	 * 
	 * WARNING: These callbacks will trigger on every mouse and keyboard event that occurs on the stage.
	 *          Developers should not add any callbacks that run computationally expensive code.
	 * 
	 * @author adufilie
	 */
	public interface IStageUtils
	{
		/**
		 * WARNING: These callbacks will trigger on every mouse event that occurs on the stage.
		 *          Developers should not add any callbacks that run computationally expensive code.
		 * 
		 * This function will add the given function as a callback.  The function must not require any parameters.
		 * @param eventType The name of the event to add a callback for.
		 * @param callback The function to call when an event of the specified type is dispatched from the stage.
		 * @param runCallbackNow If this is set to true, the callback will be run immediately after it is added.
		 */
		function addEventCallback(eventType:String, relevantContext:Object, callback:Function, runCallbackNow:Boolean = false):void;
		
		/**
		 * @param eventType The name of the event to remove a callback for, one of the static values in the MouseEvent class.
		 * @param callback The function to remove from the list of callbacks.
		 */
		function removeEventCallback(eventType:String, callback:Function):void;
		
		/**
		 * This is a list of eventType Strings that can be passed to addEventCallback().
		 * @return An Array of Strings.
		 */
		function getSupportedEventTypes():Array;
		
		/**
		 * This calls a function in a future ENTER_FRAME event.  The function call will be delayed
		 * further frames if the maxComputationTimePerFrame time limit is reached in a given frame.
		 * @param relevantContext This parameter may be null.  If the relevantContext object gets disposed of, the specified method will not be called.
		 * @param method The function to call later.
		 * @param parameters The parameters to pass to the function.
		 * @param priority The task priority, which should be one of the static constants in WeaveAPI.
		 */
		function callLater(relevantContext:Object, method:Function, parameters:Array = null, priority:uint = 2):void;
		
		/**
		 * This will start an asynchronous task, calling iterativeTask() across multiple frames until it returns a value of 1 or the relevantContext object is disposed of.
		 * @param relevantContext This parameter may be null.  If the relevantContext object gets disposed of, the task will no longer be iterated.
		 * @param iterativeTask A function that performs a single iteration of the asynchronous task.
		 *   This function must take no parameters and return a number from 0.0 to 1.0 indicating the overall progress of the task.
		 *   A number below 1.0 indicates that the function should be called again to continue the task.
		 *   When the task is completed, iterativeTask() should return 1.0.
		 *   Example:
		 *       var array:Array = ['a','b','c','d'];
		 *       var index:int = 0;
		 *       function iterativeTask():Number
		 *       {
		 *           if (index >= array.length) // in case the length is zero
		 *               return 1;
		 * 
		 *           trace(array[index]);
		 * 
		 *           index++;
		 *           return index / array.length;  // this will return 1.0 on the last iteration.
		 *       }
		 * @param priority The task priority, which should be one of the static constants in WeaveAPI.
		 * @see weave.api.WeaveAPI
		 */
		function startTask(relevantContext:Object, iterativeTask:Function, priority:int):void;
		
		/**
		 * This is the last event that occurred on the stage.
		 * This variable is set while callbacks are running and is cleared immediately after.
		 */
		function get event():Event;
		
		/**
		 * This is the last mouse event that occurred on the stage.
		 * This variable is set while callbacks are running and is cleared immediately after.
		 */
		function get mouseEvent():MouseEvent;
		
		/**
		 * This is the last keyboard event that occurred on the stage.
		 * This variable is set while callbacks are running and is cleared immediately after.
		 */
		function get keyboardEvent():KeyboardEvent;
		
		/**
		 * @return The current pressed state of the ctrl key.
		 */
		function get shiftKey():Boolean;
		
		/**
		 * @return The current pressed state of the ctrl key.
		 */
		function get altKey():Boolean;
		
		/**
		 * @return The current pressed state of the ctrl key.
		 */
		function get ctrlKey():Boolean;
		
		/**
		 * @return The current pressed state of the mouse button.
		 */
		function get mouseButtonDown():Boolean;
		
		/**
		 * @return true if the mouse moved since the last frame.
		 */
		function get mouseMoved():Boolean;
		
		/**
		 * This is the total time it took to process the previous frame.
		 */
		function get previousFrameElapsedTime():int;
		
		/**
		 * This is the amount of time the current frame has taken to process so far.
		 */
		function get currentFrameElapsedTime():int;
	}
}

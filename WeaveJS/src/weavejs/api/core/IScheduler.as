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

package weavejs.api.core
{
	public interface IScheduler
	{
		/**
		 * These callbacks get triggered once per frame.
		 */
		function get frameCallbacks():ICallbackCollection;
		
		/**
		 * This calls a function later using setTimeout(method, 0).
		 * @param relevantContext The 'this' argument for the function.  If the relevantContext object is disposed, the function will not be called.
		 * @param method The function to call later.
		 * @param parameters The parameters to pass to the function.
		 */
		function callLater(relevantContext:Object, method:Function, parameters:Array = null):void;
		
		/**
		 * This will start an asynchronous task, calling iterativeTask() across multiple frames until it returns a value of 1 or the relevantContext object is disposed.
		 * @param relevantContext This parameter may be null.  If the relevantContext object gets disposed, the task will no longer be iterated.
		 * @param iterativeTask A function that performs a single iteration of the asynchronous task.
		 *   This function must take zero or one parameter and return a number from 0.0 to 1.0 indicating the overall progress of the task.
		 *   A return value below 1.0 indicates that the function should be called again to continue the task.
		 *   When the task is completed, iterativeTask() should return 1.0.
		 *   The optional parameter specifies the time when the function should return. If the function accepts the returnTime
		 *   parameter, it will not be called repeatedly within the same frame even if it returns before the returnTime.
		 *   It is recommended to accept the returnTime parameter because code that utilizes it properly will have higher performance.
		 * 
		 * @example Example iteraveTask #1 (for loop replaced by if):
		 * <listing version="3.0">
		 * var array:Array = ['a','b','c','d'];
		 * var index:int = 0;
		 * function iterativeTask():Number // this may be called repeatedly in succession
		 * {
		 *     if (index &gt;= array.length) // in case the length is zero
		 *         return 1;
		 *     
		 *     trace(array[index]);
		 *     
		 *     index++;
		 *     return index / array.length;  // this will return 1.0 on the last iteration.
		 * }
		 * </listing>
		 * 
		 * @example Example iteraveTask #2 (resumable for loop):
		 * <listing version="3.0">
		 * var array:Array = ['a','b','c','d'];
		 * var index:int = 0;
		 * function iterativeTaskWithTimer(returnTime:int):Number // this will be called only once in succession
		 * {
		 *     for (; index &lt; array.length; index++)
		 *     {
		 *         // return time check should be at the beginning of the loop
		 *         if (getTimer() &gt; returnTime)
		 *             return index / array.length; // progress so far
		 *         
		 *         // process the current item
		 *         trace(array[index]);
		 *     }
		 *     return 1; // loop finished
		 * }
		 * </listing>
		 * 
		 * @example Example iteraveTask #3 (nested resumable for loops):
		 * <listing version="3.0">
		 * var outerArray:Array = [['a','b','c'], ['aa','bb','cc'], ['x','y','z'], ['xx','yy','zz']];
		 * var outerIndex:int = 0;
		 * var innerArray:Array = null;
		 * var innerIndex:int = 0;
		 * function iterativeNestedTaskWithTimer(returnTime:int):Number // this will be called only once in succession
		 * {
		 *     for (; outerIndex &lt; outerArray.length; outerIndex++)
		 *     {
		 *         // return time check can go here at the beginning of the loop, but we already have one in the inner loop
		 *         
		 *         if (innerArray == null)
		 *         {
		 *             // time to initialize inner loop
		 *             innerArray = outerArray[outerIndex] as Array;
		 *             innerIndex = 0;
		 *             // more code can go inside this if-block that would normally go right before the inner loop
		 *         }
		 *         
		 *         for (; innerIndex &lt; innerArray.length; innerIndex++)
		 *         {
		 *             // return time check should be at the beginning of the loop
		 *             if (getTimer() &gt; returnTime)
		 *                 return (outerIndex + (innerIndex / innerArray.length)) / outerArray.length; // progress so far
		 *             
		 *             // process the current item
		 *             trace('item', outerIndex, innerIndex, 'is', innerArray[innerIndex]);
		 *         }
		 *         
		 *         innerArray = null; // inner loop finished
		 *         // more code can go here to be executed after the nested loop
		 *     }
		 *     return 1; // outer loop finished
		 * }
		 * </listing>
		 * @param priority The task priority, which should be one of the static constants in WeaveAPI.
		 * @param finalCallback A function that should be called after the task is completed.
		 * @param description A description for the task.
		 */
		function startTask(relevantContext:Object, iterativeTask:Function, priority:uint, finalCallback:Function = null, description:String = null):void;
	}
}

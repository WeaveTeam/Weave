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

package weave.api.ui
{
	import flash.display.BitmapData;
	
	import weave.api.primitives.IBounds2D;

	/**
	 * An IPlotTask provides information for an IPlotter for rendering a plot asynchronously.
	 * @see weave.api.ui.IPlotter#drawPlotAsyncIteration
	 * 
	 * @author adufilie
	 */
	public interface IPlotTask
	{
		/**
		 * This is the off-screen buffer, which may change
		 */
		function get buffer():BitmapData;
		
		/**
		 * This specifies the range of data to be rendered
		 */
		function get dataBounds():IBounds2D;
		
		/**
		 * This specifies the pixel range where the graphics should be rendered
		 */
		function get screenBounds():IBounds2D;
		
		/**
		 * These are the IQualifiedKey objects identifying which records should be rendered
		 */
		function get recordKeys():Array;
		
		/**
		 * This counter is incremented after each iteration.  When the task parameters change, this counter is reset to zero.
		 */
		function get iteration():uint;
		
		/**
		 * This is the time at which the current iteration should be stopped, if possible.  This value can be compared to getTimer().
		 * Ignore this value if an iteration cannot be ended prematurely.
		 */
		function get iterationStopTime():int;
		
		/**
		 * This object can be used to optionally store additional state variables for resuming an asynchronous task where it previously left off.
		 * Setting this will not reset the iteration counter.
		 */
		function get asyncState():Object;
		function set asyncState(value:Object):void;
	}
}

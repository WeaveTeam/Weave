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
	 * @author adufilie
	 */
	public interface IPlotTask
	{
		// this is the off-screen buffer
		function get destination():BitmapData;
		
		// specifies the range of data to be rendered
		function get dataBounds():IBounds2D;
		
		// specifies the pixel range where the graphics should be rendered
		function get screenBounds():IBounds2D;
		
		// these are the IQualifiedKey objects identifying which records should be rendered
		function get recordKeys():Array;
		
		// This counter is incremented after each iteration.  When the task parameters change, this counter is reset to zero.
		function get iteration():uint;
		
		// can be used to optionally store additional state variables for resuming an asynchronous task where it previously left off.
		// setting this will not reset the iteration counter.
		function get asyncState():Object;
		function set asyncState(value:Object):void;
	}
}

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
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	
	/**
	 * A class implementing IPlotter defines the properties required to display shapes corresponding to record keys.
	 * The interface includes basic functions for drawing and getting bounding boxes.
	 * This interface is meant to be as lightweight and generic as possible.
	 * 
	 * @author adufilie
	 */
	public interface IPlotter extends ILinkableObject
	{
		/**
		 * This is an interface for adding callbacks that get called when any spatial properties of the plotter change.
		 * Spatial properties are those that affect the data bounds of visual elements.  Whenever these callbacks get
		 * called, data bounds values previously returned from getDataBoundsFromRecordKey() become invalid.
		 */
		function get spatialCallbacks():ICallbackCollection;
		
		/**
		 * This is the set of record keys relevant to this IPlotter.
		 * An optional filter can be applied to filter the records before the plotter generates graphics for them.
		 * @return The set of record keys that can be passed to the drawPlot() and getDataBoundsFromRecordKey() functions.
		 */
		function get filteredKeySet():IFilteredKeySet;
		
		/**
		 * This function provides a mapping from a record key to an Array of bounds objects, specified
		 * in data coordinates, that cover the bounds associated with that record key.
		 * The simplest geometric object supported is Bounds2D.  Other objects may be supported in future versions.
		 * @param recordKey The key of a data record.
		 * @return An Array of geometric objects, in data coordinates, that cover the bounds associated with the record key.
		 */
		function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array;

		/**
		 * This function will perform one iteration of an asynchronous rendering task.
		 * This function will be called multiple times across several frames until its return value is 1.0.
		 * This function may be defined with override by classes that extend AbstractPlotter.
		 * @param task An object containing the rendering parameters.
		 * @return A number between 0 and 1 indicating the progress that has been made so far in the asynchronous rendering.
		 */
		function drawPlotAsyncIteration(task:IPlotTask):Number;
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @return The data bounds associated with the background of the plotter.
		 */
		function getBackgroundDataBounds():IBounds2D;
		
		/**
		 * This function draws the background graphics for this plotter, if there are any.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void;
	}
}

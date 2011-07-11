/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package weave.api.ui
{
	import flash.display.BitmapData;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ICallbackInterface;
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
		function get keySet():IFilteredKeySet;
		
		/**
		 * This function provides a mapping from a record key to an Array of bounds objects, specified
		 * in data coordinates, that cover the bounds associated with that record key.
		 * The simplest geometric object supported is Bounds2D.  Other objects may be supported in future versions.
		 * @param recordKey The key of a data record.
		 * @return An Array of geometric objects, in data coordinates, that cover the bounds associated with the record key.
		 */
		function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array;

		
		/**
		 * Draws the graphics for a list of records onto a sprite.
		 * @param recordKeys The list of keys that identify which records should be used to generate the graphics.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void;

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

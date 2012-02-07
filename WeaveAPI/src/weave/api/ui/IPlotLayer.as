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
	import mx.core.IUIComponent;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDynamicKeyFilter;

	/**
	 * A PlotLayer is a UIComponent that draws the graphics of an IPlotter.
	 * 
	 * NOTE:
	 * This is a temporary interface just to get everything working.
	 * This interface should be redesigned to avoid dependencies on implementations such as SpatialIndex.
	 * 
	 * @author adufilie
	 */
	public interface IPlotLayer extends IUIComponent, ILinkableObject, IZoomView
	{
		/**
		 * This is the IPlotter that is used to draw graphics on the IPlotLayer.
		 */
		function get plotter():IPlotter;

		// allows spatial querying
		function get spatialIndex():ISpatialIndex;
		
		/**
		 * This key set allows you to filter the records before they are used to calculate the graphics.
		 */  
		function get subsetFilter():IDynamicKeyFilter;
		/**
		 * This will be used to filter the graphics that are drawn, but not the records that were used to calculate the graphics.
		 */
		//function get selectionFilter():IDynamicKeyFilter;


		//-------------------------------------
		
		/**
		 * @param xyDataCoordinates This is an Array of X,Y coordinate pairs.  The Array items at 0,2,4,... are X coordinates and the items at 1,3,5,... are Y coordinates.
		 * @return The list of keys This function will update the filteredKeySet to include only the keys that intersect with the polygon defined by the given coordinates.
		 */
		//function getKeysInPolygon(xyDataCoordinates:Array):Vector.<String>;
	}
}

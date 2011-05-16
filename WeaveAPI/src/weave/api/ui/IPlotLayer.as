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


		/**
		 * This will cause a given plot layer re-render itself the next frame
		 */
		function invalidateGraphics():void

		//-------------------------------------
		
		/**
		 * @param xyDataCoordinates This is an Array of X,Y coordinate pairs.  The Array items at 0,2,4,... are X coordinates and the items at 1,3,5,... are Y coordinates.
		 * @return The list of keys This function will update the filteredKeySet to include only the keys that intersect with the polygon defined by the given coordinates.
		 */
		//function getKeysInPolygon(xyDataCoordinates:Array):Vector.<String>;
	}
}

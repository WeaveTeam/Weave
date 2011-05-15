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

package org.oicweave.api.data
{
	import flash.geom.Point;
	
	import org.oicweave.api.primitives.IBounds2D;
	
	/**
	 * An interface for reprojecting columns of geometries and individual coordinates.
	 * 
	 * @author adufilie
	 */	
	public interface IProjectionManager
	{
		/**
		 * This function will return a column containing reprojected geometries.
		 * @param sourceColumn A reference to a column containing geometry data.
		 * @param destinationSRS The string corresponding to a projection destination.
		 * @return The reprojected geometry column.
		 */
		function getProjectedGeometryColumn(sourceColumn:IColumnReference, destinationSRS:String):IAttributeColumn;
		
		/**
		 * This function will check if a projection is defined for a given SRS code.
		 * @param srsCode The SRS code of the projection.
		 * @return A boolean indicating true if the projection is defined and false otherwise.
		 */
		function projectionExists(srsCode:String):Boolean;
		
		/**
		 * This function will return an IProjector object that can be used to reproject points.
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destinationSRS The SRS code of the destination projection.
		 * @return An IProjector object that reprojects from sourceSRS to destinationSRS.
		 */
		function getProjector(sourceSRS:String, destinationSRS:String):IProjector;
		
		/**
		 * This function will transform a point from the sourceSRS to the destinationSRS.
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destinationSRS The SRS code of the destination projection.
		 * @param inputAndOutput The point to transform. This is then used as the return value.
		 * @return The transformed point, inputAndOutput, or null if the transform failed.
		 */
		function transformPoint(sourceSRS:String, destinationSRS:String, inputAndOutput:Point):Point;

		/**
		 * This function will approximately transform bounds from the sourceSRS to the destinationSRS.
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destinationSRS The SRS code of the destination projection.
		 * @param inputAndOutput The bounds to transform. This is then used as the return value.
		 * @param xGridSize The x dimension of the grid used to approximate the transform.
		 * @param yGridSize The y dimension of the grid used to approximate the transform.
		 * @return The transformed bounds, inputAndOutput.
		 */
		function transformBounds(sourceSRS:String, destinationSRS:String, inputAndOutput:IBounds2D,
			xGridSize:int = 32, yGridSize:int = 32):IBounds2D

	}
}

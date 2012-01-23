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

package weave.api.data
{
	import flash.geom.Point;
	
	import weave.api.primitives.IBounds2D;
	
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

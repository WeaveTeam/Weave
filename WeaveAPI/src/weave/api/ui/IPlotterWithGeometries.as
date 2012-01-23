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
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;

	/**
	 * This interface defines a plotter whose records are geometric objects with
	 * special probing and selection. A plotter which implements this interface is 
	 * subject to polygon containment algorithms during probing and selection.
	 * 
	 * @author kmonico
	 */
	public interface IPlotterWithGeometries extends IPlotter
	{
		/**
		 * This function provides a mapping from a record key to an Array of ISimpleGeometry objects
		 * in data coordinates.
		 * 
		 * @param recordKey An IQualifiedKey for which to get its geometries.
		 * @param minImportance The minimum importance of the geometry objects.
		 * @param bounds The visible bounds.
		 * @return An Array of IGeometry objects, in data coordinates.
		 */
		function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, bounds:IBounds2D = null):Array;
		
		/**
		 * This function will get an array ISimpleGeometry objects.
		 * 
		 * @return An array of ISimpleGeometry objects which can be used for spatial querying. 
		 */		
		function getBackgroundGeometries():Array;
	}
}
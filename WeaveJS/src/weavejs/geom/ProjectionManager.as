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

package weavejs.geom
{
	/**
	 * An interface for reprojecting columns of geometries and individual coordinates.
	 * 
	 * @author adufilie
	 * @author kmonico
	 */	
	public class ProjectionManager //implements IProjectionManager
	{
		public static function getProjectionFromURN(ogc_crs_urn:String):String
		{
			var array:Array = ogc_crs_urn.split(':');
			if (array.length > 2)
				return array[array.length - 3] + ':' + array[array.length - 1];
			return ogc_crs_urn;
		}
	}
}

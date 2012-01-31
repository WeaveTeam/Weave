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
	
	/**
	 * An interface for an object that reprojects points from one specific coordinate system to another.
	 * 
	 * @author adufilie
	 */
	public interface IProjector
	{
		/**
		 * This function will reproject a point using the transformation method associated with this object.
		 * @param inputAndOutput The point to reproject, which will be modified in place.
		 * @return The transformed point, inputAndOutput, or null if the reprojection failed.
		 */
		function reproject(inputAndOutput:Point):Point;
	}
}

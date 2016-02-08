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

package weave.geometrystream;

import java.util.List;

/**
 * @author adufilie
 */
public interface IGeometryStreamDestination
{
	void writeMetadataTiles(List<StreamTile> tiles) throws Exception;
	void writeGeometryTiles(List<StreamTile> tiles) throws Exception;

	/**
	 * Data buffers are flushed and cleanup is performed.
	 * This function must be called after all desired tiles have been written.
	 */
	public void commit() throws Exception;
}

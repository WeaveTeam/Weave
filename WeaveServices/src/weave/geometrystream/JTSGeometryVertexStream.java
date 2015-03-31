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

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.Geometry;

/**
 * This is an interface to a stream of vertices from a geometry.
 * 
 * @author adufilie
 */
public class JTSGeometryVertexStream implements IGeometryVertexStream
{
	public JTSGeometryVertexStream(Geometry geom)
	{
		coords = geom.getCoordinates();
		index = -1; // start before the first coord so the first call to next() will not skip anything
	}
	
	private Coordinate[] coords;
	private int index;
	
	/**
	 * This checks if there is a vertex available from the stream.
	 * @return true if there is a next vertex available from the stream, meaning a call to next() will succeed.
	 */
	public boolean hasNext()
	{
		return index + 1 < coords.length;
	}
	
	/**
	 * This advances the internal pointer to the next vertex.
	 * Initially, the pointer points before the first vertex.
	 * This function must be called before getX() and getY() are called.
	 * @return true if advancing the vertex pointer succeeded, meaning getX() and getY() can now be called.
	 */
	public boolean next()
	{
		return ++index < coords.length;
	}
	
	/**
	 * @return The X coordinate of the current vertex.
	 */
	public double getX()
	{
		return coords[index].x;
	}

	/**
	 * @return The Y coordinate of the current vertex.
	 */
	public double getY()
	{
		return coords[index].y;
	}
}

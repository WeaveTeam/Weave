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

import com.vividsolutions.jts.geom.Geometry;

/**
 * This is an interface to a stream of geometries from a feature.
 * 
 * @author adufilie
 */
public class JTSFeatureGeometryStream implements IFeatureGeometryStream
{
	public JTSFeatureGeometryStream(Geometry featureGeom)
	{
		this.featureGeom = featureGeom;
		count = featureGeom.getNumGeometries();
		index = 0;
	}
	
	private Geometry featureGeom;
	private int count;
	private int index;
	
	/**
	 * This function checks whether getNext() will return a GeometryVertexStream or not.
	 * @return true if there is a GeometryVertexStream available via getNext().
	 */
	public boolean hasNext()
	{
		return index < count;
	}
	
	/**
	 * This function will get the next GeometryVertexStream.
	 * @return The next GeometryVertexStream, or null if there are no more.
	 */
	public IGeometryVertexStream getNext()
	{
		return new JTSGeometryVertexStream(featureGeom.getGeometryN(index++));
	}
}

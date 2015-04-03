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

import java.io.DataOutputStream;
import java.io.IOException;

/**
 * @author adufilie
 */
public class PartMarker implements IStreamObject
{
	public PartMarker(int shapeID, int firstVertexID, int chainLength, Bounds2D queryBounds)
	{
		this.shapeID = shapeID;
		this.firstVertexID = firstVertexID;
		this.chainLength = chainLength;
		this.partBounds.xMin = queryBounds.xMin;
		this.partBounds.yMin = queryBounds.yMin;
		this.partBounds.xMax = queryBounds.xMax;
		this.partBounds.yMax = queryBounds.yMax;
	}
	
	public final int shapeID, firstVertexID, chainLength;
	public final Bounds2D partBounds = new Bounds2D();
	
	public void writeStream(DataOutputStream stream) throws IOException
	{
		stream.writeInt(shapeID);
		stream.writeInt(firstVertexID);
		stream.writeInt(-2);
		stream.writeInt(firstVertexID + chainLength);
	}
	public Bounds2D getQueryBounds()
	{
		return partBounds;
	}
	public int getStreamSize()
	{
		return (Integer.SIZE/8) * 4;
	}
	public double getX()
	{
		return partBounds.getCenterX();
	}
	public double getY()
	{
		return partBounds.getCenterY();
	}
	public double getImportance()
	{
		return partBounds.getArea();
	}
}

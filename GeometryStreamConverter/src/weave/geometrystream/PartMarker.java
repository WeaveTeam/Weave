/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.geometrystream;

import java.io.DataOutputStream;
import java.io.IOException;

/**
 * @author adufilie
 */
public class PartMarker implements StreamObject
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

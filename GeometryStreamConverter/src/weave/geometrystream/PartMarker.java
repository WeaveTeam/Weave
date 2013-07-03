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
	public PartMarker(int shapeID, int vertexID, int chainLength, Bounds2D queryBounds)
	{
		this.shapeID = shapeID;
		this.vertexID = vertexID;
		this.chainLength = chainLength;
		this.partBounds.xMin = queryBounds.xMin;
		this.partBounds.yMin = queryBounds.yMin;
		this.partBounds.xMax = queryBounds.xMax;
		this.partBounds.yMax = queryBounds.yMax;
	}
	
	public final int shapeID, vertexID, chainLength;
	public final Bounds2D partBounds = new Bounds2D();
	
	public void writeStream(DataOutputStream stream) throws IOException
	{
		if (vertexID >= 0)
		{
			stream.writeInt(shapeID);
			stream.writeInt(vertexID);
		}
		stream.writeInt(shapeID);
		stream.writeInt(vertexID + chainLength + 1);
		stream.writeInt(-1);
	}
	public Bounds2D getQueryBounds()
	{
		return partBounds;
	}
	public int getStreamSize()
	{
		if (vertexID >= 0)
			return Integer.SIZE/8 * 5;
		
		return (Integer.SIZE/8 * 3);
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

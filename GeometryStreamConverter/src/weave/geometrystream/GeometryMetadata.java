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
import java.util.LinkedList;
import java.util.List;

import weave.geometrystream.StreamObject;

/**
 * @author adufilie
 */
public class GeometryMetadata implements StreamObject
{
	public GeometryMetadata(int shapeID, String shapeKey, int shapeType, String projectionWKT)
	{
		this.shapeID = shapeID;
		this.shapeKey = shapeKey;
		this.shapeType = shapeType;
		this.projectionWKT = projectionWKT;
		this.bounds = new Bounds2D();
		this.polygonMarkerIndices = new LinkedList<Integer>();
		this.includeGeometryCollectionMetadataInStream = false;
	}
	
	public boolean isPointType()
	{
		return shapeType % 10 == 1 || shapeType % 10 == 8; // 1,21,11,8,28,18
	}
	public boolean isLineType()
	{
		return shapeType % 10 == 3; // 3,23,13
	}
	public boolean isPolygonType()
	{
		return shapeType % 10 == 5; // 5,25,15
	}
	
	public int getStreamSize()
	{
		// int shapeID, String shapeKey, '\0', double xMin, double yMin, double xMax, double yMax, (int vertexID * (numPolygonMarkers + 1))
		return (Integer.SIZE/8) + shapeKey.length() + 1 + (Double.SIZE/8) * 4 + (Integer.SIZE/8) * (polygonMarkerIndices.size() + 1);
	}
	
	public void writeStream(DataOutputStream metadataStream) throws IOException
	{
		// binary format: <int shapeID, String shapeKey, '\0', double xMin, double yMin, double xMax, double yMax, int vertexID1, int vertexID2, ..., int vertexID(n-1), int VertexID(n), int -1 or -2>
		// write shapeID
		metadataStream.writeInt(shapeID);
		// write shapeKey
		metadataStream.writeBytes(shapeKey);
		metadataStream.writeByte('\0');
		// write shape bounds information
		metadataStream.writeDouble(bounds.xMin);
		metadataStream.writeDouble(bounds.yMin);
		metadataStream.writeDouble(bounds.xMax);
		metadataStream.writeDouble(bounds.yMax);
		// write polygon markers (index values used to separate polygon parts)
		for (int i : polygonMarkerIndices)
			metadataStream.writeInt(i);
		if (includeGeometryCollectionMetadataInStream)
		{
			// write the flag to signal the end of the polygon markers and indicate that the shapeType follows
			metadataStream.writeInt(-3);
			
			// write shapeType id
			metadataStream.writeInt(shapeType);
			
			//write projection
			if (projectionWKT != null)
				metadataStream.writeBytes(projectionWKT);
			metadataStream.writeByte('\0');
		}
		else
		{
			// write the flag to signal the end of the polygon markers
			metadataStream.writeInt(-1);
		}
	}

	public int shapeID;
	public String shapeKey;
	public int shapeType;
	public String projectionWKT;
	public Bounds2D bounds;
	public List<Integer> polygonMarkerIndices;
	public boolean includeGeometryCollectionMetadataInStream;

	public Bounds2D getQueryBounds()
	{
		return bounds;
	}
	public double getX()
	{
		return bounds.getCenterX();
	}
	public double getY()
	{
		return bounds.getCenterX();
	}
	public double getImportance()
	{
		return bounds.getImportance();
	}
}

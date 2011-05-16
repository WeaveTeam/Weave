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
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Stack;

import weave.geometrystream.StreamObject;

/**
 * @author adufilie
 */
public class CombinedPoint implements StreamObject
{
	private CombinedPoint()
	{
	}

	private LinkedList<VertexIdentifier> vertexIdentifiers = new LinkedList<VertexIdentifier>();
	Bounds2D queryBounds = new Bounds2D();
	public double x;
	public double y;
	public double importance = VertexChainLink.IMPORTANCE_UNKNOWN;
	
	public CombinedPoint initialize(double x, double y)
	{
		clear();
		this.x = x;
		this.y = y;
		return this;
	}
	
	public void clear()
	{
		for (VertexIdentifier vertexIdentifier : vertexIdentifiers)
			VertexIdentifier.saveUnusedInstance(vertexIdentifier);
		vertexIdentifiers.clear();
		queryBounds.reset();
	}
	
	public void addPoint(int shapeID, Bounds2D pointQueryBounds, VertexChainLink point)
	{
		if (this.x != point.x || this.y != point.y)
			throw new RuntimeException("CombinedPoint.addPoint(): coordinates of new point do not match");
		vertexIdentifiers.add(VertexIdentifier.getUnusedInstance(shapeID, point.vertexID));
		queryBounds.includeBounds(pointQueryBounds);
	}
	
	public Bounds2D getQueryBounds()
	{
		return queryBounds;
	}

	public void updateMinimumImportance(double minimumImportance)
	{
		importance = Math.max(importance, minimumImportance);
	}
	
	public int getStreamSize()
	{
		// (int shapeID, int vertexID) * vertexIdentifiers.size(), double x, double y, float importance
		return (Integer.SIZE/8 * 2) * vertexIdentifiers.size() + (Double.SIZE/8) * 2 + (Float.SIZE/8);
	}
	
	public void writeStream(DataOutputStream pointStream) throws IOException
	{
		// binary format: <int shapeID1, int vertexID1, int shapeID2, int vertexID2, ..., int shapeID(n-1), int vertexID(n-1), int shapeID(n), int negativeVertexID(n), double x, double y, float importance>
		// loop through vertex identifiers
		Iterator<VertexIdentifier> iter = vertexIdentifiers.iterator();
		VertexIdentifier vertexIdentifier;
		while (iter.hasNext())
		{
			vertexIdentifier = iter.next();
			// write shapeID
			pointStream.writeInt(vertexIdentifier.shapeID);
			// write vertexID (negative if it is the last one)
			if (!iter.hasNext())
				pointStream.writeInt(-1 - vertexIdentifier.vertexID);
			else
				pointStream.writeInt(vertexIdentifier.vertexID);
		}
		// write x,y coordinates
		pointStream.writeDouble(x);
		pointStream.writeDouble(y);
		// write importance value
		pointStream.writeFloat((float)importance);
	}
	
	private static final long serialVersionUID = -7090731893590156775L;
	
	public double getImportance()
	{
		return importance;
	}
	
	public double getX()
	{
		return x;
	}
	
	public double getY()
	{
		return y;
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#hashCode()
	 */
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		long temp;
		temp = Double.doubleToLongBits(x);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(y);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		return result;
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#equals(java.lang.Object)
	 */
	@Override
	public boolean equals(Object obj)
	{
		CombinedPoint other = (CombinedPoint) obj;
		return x == other.x && y == other.y;
	}
	
	private static Stack<CombinedPoint> unusedInstances = new Stack<CombinedPoint>();
	public static void saveUnusedInstance(CombinedPoint combinedPoint)
	{
		combinedPoint.clear();
		unusedInstances.push(combinedPoint);
	}
	public static CombinedPoint getUnusedInstance(double x, double y)
	{
		CombinedPoint result;
		if (unusedInstances.size() == 0)
			result = new CombinedPoint();
		else
			result = unusedInstances.pop();
		result.initialize(x, y);
		return result;
	}
}

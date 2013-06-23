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

import java.util.Comparator;

/**
 * @author adufilie
 */
public class VertexChainLink
{
	public void initialize(double x, double y, int vertexID)
	{
		this.x = x;
		this.y = y;
		this.vertexID = vertexID;
		this.importance = -1;
		importanceIsValid = false;
		// make this vertex adjacent to itself
		prev = this;
		next = this;
	}
	
	/**
	 * Adds a new vertex to the end of the chain.
	 */		
	public void insert(VertexChainLink newVertex)
	{
		prev.next = newVertex; // add new vertex to end of chain
		newVertex.prev = this.prev; // the current last vertex appears before the new one
		newVertex.next = this; // the new vertex wraps around to this one
		this.prev = newVertex; // this vertex wraps backwards around to the new one
	}

	/**
	 * Compares x and y values only
	 * @param other
	 * @return
	 */
	public boolean equals2D(VertexChainLink other)
	{
		return this.x == other.x && this.y == other.y;
	}
	
	/**
	 * This will invalidate the importance of neighboring vertices
	 */
	public void removeFromChain()
	{
		// promote adjacent vertices and invalidate their importance
		prev.promoteAndInvalidateImportance(importance);
		next.promoteAndInvalidateImportance(importance);
		// make next and prev adjacent to each other
		prev.next = next;
		next.prev = prev;
		// make this vertex adjacent to itself
		prev = this;
		next = this;
	}
	
	private void promoteAndInvalidateImportance(double minImportance)
	{
		importance = Math.max(importance, minImportance);
		importanceIsValid = false;
	}
	
	/**
	 * This function re-calculates the importance of the current point.
	 * It may only increase the importance, not decrease it.
	 * @return true if the point is marked with IMPORTANCE_REQUIRED.
	 */
	public boolean validateImportance()
	{
		importanceIsValid = true;
		// Removing this point may make the Part intersect itself, but that problem is unlikely
		// to be noticeable if the shape is drawn at the proper quality level.
		//TODO: Does this problem matter?  If this is to be avoided, the algorithm needs to be extended.
		
		// stop if already marked required
		if (importance == VertexChainLink.IMPORTANCE_REQUIRED)
			return true;

		// the importance of a point is the area formed by it and its two neighboring points
		
		//TODO: use distance as well as area in determining importance?
		
		// update importance
		double area = areaOfTriangle(prev, this, next);
		// importance should never decrease from previous value
		importance = Math.max(importance, area);
		return false;
	}

	/**
	 * @param a First point in a triangle.
	 * @param b Second point in a triangle.
	 * @param c Third point in a triangle.
	 * @return The area of the triangle ABC.
	 */
	private double areaOfTriangle(VertexChainLink a, VertexChainLink b, VertexChainLink c)
	{
		// http://www.softsurfer.com/Archive/algorithm_0101/algorithm_0101.htm
		// get signed area of the triangle formed by three points
		double signedArea = ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2;
		// return absolute value
		if (signedArea < 0)
			return -signedArea;
		return signedArea;
	}
	
	public String toString()
	{
		return String.format("{x: %s, y: %s, v: %s, i: %s}", x, y, vertexID, importance);
	}
	
	public double x;
	public double y;
	public int vertexID;
	public double importance;
	public boolean importanceIsValid;
	public VertexChainLink prev, next;
	
	public static final double IMPORTANCE_REQUIRED = Double.MAX_VALUE;
	public static final double IMPORTANCE_UNKNOWN = -1;

	// sort by importance, ascending
	public static final Comparator<VertexChainLink> sortByImportance = new Comparator<VertexChainLink>()
	{
		public int compare(VertexChainLink o1, VertexChainLink o2)
		{
			// ascending
			return Double.compare(o1.importance, o2.importance);
		}
	};
}

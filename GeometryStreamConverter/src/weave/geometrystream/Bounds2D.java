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

/**
 * The code in this class assumes xMin < xMax and yMin < yMax
 *
 * @author adufilie
 *
 */
public class Bounds2D
{
	public Bounds2D()
	{
		reset();
	}
	public Bounds2D(double xMin, double yMin, double xMax, double yMax)
	{
		this.xMin = xMin;
		this.yMin = yMin;
		this.xMax = xMax;
		this.yMax = yMax;
	}
	public boolean overlaps(Bounds2D other)
	{
		return this.xMin <= other.xMax && other.xMin <= this.xMax
			&& this.yMin <= other.yMax && other.yMin <= this.yMax;
	}
	public double getImportance()
	{
		// use area if it is > 0
		double width = xMax - xMin;
		double height = yMax - yMin;
		double area = width * height;
		if (area > 0)
			return area;
		// if area is 0, return length squared instead (vertical or horizontal line)
		double length = width + height; // either width or height is 0
		if (length > 0)
			return length * length;
		// if length is 0, return REQUIRED (point)
		return VertexChainLink.IMPORTANCE_REQUIRED;
	}
	public double getCenterX()
	{
		return (xMax + xMin) / 2;
	}
	public double getCenterY()
	{
		return (yMax + yMin) / 2;
	}
	public void includePoint(double x, double y)
	{
		xMin = (Double.isNaN(xMin)) ? x : Math.min(xMin, x);
		xMax = (Double.isNaN(xMax)) ? x : Math.max(xMax, x);
		yMin = (Double.isNaN(yMin)) ? y : Math.min(yMin, y);
		yMax = (Double.isNaN(yMax)) ? y : Math.max(yMax, y);
	}
	public void includeBounds(Bounds2D other)
	{
		includePoint(other.xMin, other.yMin);
		includePoint(other.xMax, other.yMax);
	}
	public void reset()
	{
		xMin = Double.NaN;
		yMin = Double.NaN;
		xMax = Double.NaN;
		yMax = Double.NaN;
	}
	public boolean isUndefined()
	{
		return Double.isNaN(xMin)
			|| Double.isNaN(yMin)
			|| Double.isNaN(xMax)
			|| Double.isNaN(yMax);
	}
	
	public String toString()
	{
		return String.format("(%s, %s, %s, %s)",xMin,yMin,xMax,yMax);
	}

	public double xMin;
	public double yMin;
	public double xMax;
	public double yMax;
}

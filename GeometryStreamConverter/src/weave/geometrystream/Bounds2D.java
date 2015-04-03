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

/**
 * The code in this class assumes xMin < xMax and yMin < yMax
 * Constructor is private because this is intended for use with ObjectPool.
 * @author adufilie
 */
public class Bounds2D
{
	public boolean overlaps(Bounds2D other)
	{
		return this.xMin <= other.xMax && other.xMin <= this.xMax
			&& this.yMin <= other.yMax && other.yMin <= this.yMax;
	}
	public double getArea()
	{
		return Math.abs((xMax - xMin) * (yMax - yMin));
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

	public double xMin = Double.NaN;
	public double yMin = Double.NaN;
	public double xMax = Double.NaN;
	public double yMax = Double.NaN;
}

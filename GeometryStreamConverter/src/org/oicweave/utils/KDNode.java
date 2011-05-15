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

package org.oicweave.utils;

/**
 * @author adufilie
 *
 * @param <T> The type of object stored in the KDNode
 */
public class KDNode<T>
{
	public KDNode(double[] key, T object, int splitDimension)
	{
		this.key = key;
		this.object = object;
		clearChildrenAndSetSplitDimension(splitDimension);
	}

	public int splitDimension;
	public double location;

	public void clearChildrenAndSetSplitDimension(int value)
	{
		left = null;
		right = null;
		splitDimension = value;
		location = key[splitDimension];
	}

	public double[] key;
	public T object;
	
	public KDNode<T> left = null;
	public KDNode<T> right = null;
}

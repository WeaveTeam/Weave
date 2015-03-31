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

package weave.utils;

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

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
import java.util.Comparator;

import weave.geometrystream.Bounds2D;

/**
 * A StreamObject is something that can be sorted in three dimensions (x, y, importance).
 * @author adufilie
 */
public interface IStreamObject
{
	// write the stream object to a DataOutputStream
	public void writeStream(DataOutputStream stream) throws IOException;
	
	// get the range of coordinates this StreamObject is relevant to.
	public Bounds2D getQueryBounds();

	// get the number of bytes this StreamObject takes up when it is written to a DataOutputStream
	public int getStreamSize();

	// get the x value associated with this StreamObject, used for sorting
	public double getX();

	// get the x value associated with this StreamObject, used for sorting
	public double getY();
	
	// get the importance value associated with this StreamObject, used for sorting
	public double getImportance();

	// sort by importance, descending
	public static final Comparator<IStreamObject> sortByImportance = new Comparator<IStreamObject>()
	{
	    public int compare(IStreamObject o1, IStreamObject o2)
	    {
	    	// descending
	    	return - Double.compare(o1.getImportance(), o2.getImportance());
	    }
	};

	// sort by x, ascending
	public static final Comparator<IStreamObject> sortByX = new Comparator<IStreamObject>()
	{
		public int compare(IStreamObject o1, IStreamObject o2)
		{
			// ascending
			return Double.compare(o1.getX(), o2.getX());
		}
	};

	// sort by y, ascending
	public static final Comparator<IStreamObject> sortByY = new Comparator<IStreamObject>()
	{
		public int compare(IStreamObject o1, IStreamObject o2)
		{
			// ascending
			return Double.compare(o1.getY(), o2.getY());
		}
	};
}

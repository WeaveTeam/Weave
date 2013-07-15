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

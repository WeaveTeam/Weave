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
import java.util.Arrays;

/**
 * Keeps track of a set of StreamObjects along with their pointBounds and queryBounds.
 * The pointBounds contains the coordinates of all the StreamObjects.
 * The queryBounds contains the bounds of all the queryBounds associated with the streamObjects.
 * @author adufilie
 */
public class StreamTile
{
	/**
	 * This does not make a copy of the StreamObject[] array, so the specified section of
	 * the array should not be modified after the constructor is called.
	 * @param combinedPoints An array of StreamObjects.
	 * @param startIndex The index of the first StreamObject to be included in this tile.
	 * @param endIndex The index after the last StreamObject to be included in this tile.
	 */
	public StreamTile(StreamObject[] streamObjects, int startIndex, int endIndex)
	{
		this.streamObjects = streamObjects;
		this.startIndex = startIndex;
		this.endIndex = endIndex;

		// sort specified points by importance
		Arrays.sort(streamObjects, startIndex, endIndex, StreamObject.sortByImportance);
		// save min,max importance values
		if (startIndex < endIndex)
		{
			maxImportance = streamObjects[startIndex].getImportance();
			minImportance = streamObjects[endIndex - 1].getImportance();
		}
		// update both bounds objects to include all the specified CombinedPoints.
		StreamObject obj;
		for (int i = startIndex; i < endIndex; i++)
		{
			obj = streamObjects[i];
			pointBounds.includePoint(obj.getX(), obj.getY());
			queryBounds.includeBounds(obj.getQueryBounds());
		}
	}

	public void writeStream(DataOutputStream stream, int tileID) throws IOException
	{
		// binary format: <int negativeTileID, binary stream object beginning with positive int, ...>
		stream.writeInt(-1 - tileID);
		for (int i = startIndex; i < endIndex; i++)
			streamObjects[i].writeStream(stream);
	}
	
	public String toString() // for debugging
	{
		int bytes = 0;
		for (int i = startIndex; i < endIndex; i++)
			bytes += streamObjects[i].getStreamSize();
		return String.format("ShapeStreamTile(%s StreamObjects, %s bytes, %s, %s)", endIndex - startIndex, bytes, pointBounds, queryBounds);
	}
	
	private StreamObject[] streamObjects;
	private int startIndex, endIndex;

	public double minImportance = 0, maxImportance = 0;
	public final Bounds2D pointBounds = new Bounds2D();
	public final Bounds2D queryBounds = new Bounds2D();
}

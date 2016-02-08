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
	public StreamTile(IStreamObject[] streamObjects, int startIndex, int endIndex)
	{
		this.streamObjects = streamObjects;
		this.startIndex = startIndex;
		this.endIndex = endIndex;

		// sort specified points by importance
		Arrays.sort(streamObjects, startIndex, endIndex, IStreamObject.sortByImportance);
		// save min,max importance values
		if (startIndex < endIndex)
		{
			maxImportance = streamObjects[startIndex].getImportance();
			minImportance = streamObjects[endIndex - 1].getImportance();
		}
		// update both bounds objects to include all the specified CombinedPoints.
		IStreamObject obj;
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
	
	private IStreamObject[] streamObjects;
	private int startIndex, endIndex;

	public double minImportance = 0, maxImportance = 0;
	public final Bounds2D pointBounds = new Bounds2D();
	public final Bounds2D queryBounds = new Bounds2D();
}

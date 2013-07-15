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

import java.util.Arrays;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import weave.geometrystream.GeometryMetadata;

/**
 * @author adufilie
 */
public class GeometryStreamUtils
{
	public static int getShapeTypeFromGeometryType(String geometryType)
	{
		if (geometryType.equals("Point"))
			return 1;//ShapeType.POINT;
		if (geometryType.equals("MultiPoint"))
			return 8;//ShapeType.MULTIPOINT;
		if (geometryType.equals("LineString") || geometryType.equals("MultiLineString"))
			return 3;//ShapeType.ARC;
		if (geometryType.equals("Polygon") || geometryType.equals("MultiPolygon"))
			return 5;//ShapeType.POLYGON;

		//if (geometryType.equals("GeometryCollection"))
		return -1;//ShapeType.UNDEFINED;
	}

	/**
	 * This will group them into StreamTile objects.
	 * The streamObjectsList will be modified.
	 * @param streamObjectsList This is the list to modify and group.
	 * @param tileSize The desired approximate tile size, in bytes.
	 * @return A list of StreamTile objects which contain the items originally in streamObjectsList.
	 */
	public static List<StreamTile> groupStreamObjectsIntoTiles(LinkedList<IStreamObject> streamObjectsList, int tileSize)
	{
		// remove stream objects with undefined queryBounds
		Iterator<IStreamObject> iter = streamObjectsList.iterator();
		while (iter.hasNext())
			if (iter.next().getQueryBounds().isUndefined())
				iter.remove();
		
		IStreamObject[] streamObjects = new IStreamObject[streamObjectsList.size()];
		streamObjectsList.toArray(streamObjects);
		LinkedList<StreamTile> tiles = new LinkedList<StreamTile>();

		// return empty tile list if there are no StreamObjects.
		if (streamObjects.length == 0)
			return tiles;
		
		// sort StreamObjects descending by importance
		Arrays.sort(streamObjects, 0, streamObjects.length, IStreamObject.sortByImportance);
		// iterate over StreamObjects and generate tiles
		int thisLevelStartIndex = 0;
		int thisLevelEndIndex = 0;
		int thisLevelTileCount = 1;
		while (thisLevelEndIndex < streamObjects.length)
		{
			// include points until we reach the size goal for this level
			int thisLevelTotalSize = 0;
			while (thisLevelTotalSize < tileSize * thisLevelTileCount && thisLevelEndIndex < streamObjects.length)
				thisLevelTotalSize += streamObjects[thisLevelEndIndex++].getStreamSize();
			// if we are at the end of the StreamObject list, keep dividing thisLevelTileCount by 4
			// as long as the average tile size stays below the desired tileSize
			while (thisLevelTotalSize < tileSize * thisLevelTileCount / 4 && thisLevelTileCount >= 4)
				thisLevelTileCount /= 4;
			// split the points for this level into tiles
			splitStreamObjectsIntoTiles(tiles, streamObjects, thisLevelStartIndex, thisLevelEndIndex, thisLevelTileCount, thisLevelTotalSize);
			// advance startIndex to next group
			thisLevelStartIndex = thisLevelEndIndex;
			// next level has 4 times as many tiles
			thisLevelTileCount *= 4;
		}

		return tiles;
	}
	
	private static void splitStreamObjectsIntoTiles(List<StreamTile> outputTileList, IStreamObject[] streamObjects, int startIndex, int endIndex, int tileCount, int totalStreamSize)
	{
		// do nothing if range is empty
		if (startIndex == endIndex)
			return;
		
		// if only one tile, use full provided index range
		if (tileCount == 1)
		{
			// if the stream objects in these tiles are Shape objects, include the shape type in the stream.
			IStreamObject firstStreamObject = streamObjects[startIndex];
			if (firstStreamObject instanceof GeometryMetadata)
				((GeometryMetadata) firstStreamObject).includeGeometryCollectionMetadataInStream = true;
			
			outputTileList.add(new StreamTile(streamObjects, startIndex, endIndex));
			return;
		}
		
		// sort entire range by X
		Arrays.sort(streamObjects, startIndex, endIndex, IStreamObject.sortByX);
		
		// find midpoint based on stream size
		int middleIndex = startIndex;
		int firstHalfStreamSize = 0;
		while (middleIndex < endIndex && firstHalfStreamSize < totalStreamSize/2)
			firstHalfStreamSize += streamObjects[middleIndex++].getStreamSize();
		int secondHalfStreamSize = totalStreamSize - firstHalfStreamSize;

		// sort each half individually by Y
		Arrays.sort(streamObjects, startIndex, middleIndex, IStreamObject.sortByY);
		Arrays.sort(streamObjects, middleIndex, endIndex, IStreamObject.sortByY);

		// find firstQuarterIndex based on stream size
		int firstQuarterIndex = startIndex;
		int firstQuarterStreamSize = 0;
		while (firstQuarterIndex < middleIndex && firstQuarterStreamSize < firstHalfStreamSize/2)
			firstQuarterStreamSize += streamObjects[firstQuarterIndex++].getStreamSize();
		int secondQuarterStreamSize = firstHalfStreamSize - firstQuarterStreamSize;
		
		// find thirdQuarterIndex based on stream size
		int thirdQuarterIndex = middleIndex;
		int thirdQuarterStreamSize = 0;
		while (thirdQuarterIndex < endIndex && thirdQuarterStreamSize < secondHalfStreamSize/2)
			thirdQuarterStreamSize += streamObjects[thirdQuarterIndex++].getStreamSize();
		int fourthQuarterStreamSize = secondHalfStreamSize - thirdQuarterStreamSize;
		
		// call recursively for each quarter
		tileCount /= 4;
		splitStreamObjectsIntoTiles(outputTileList, streamObjects, startIndex, firstQuarterIndex, tileCount, firstQuarterStreamSize);
		splitStreamObjectsIntoTiles(outputTileList, streamObjects, firstQuarterIndex, middleIndex, tileCount, secondQuarterStreamSize);
		splitStreamObjectsIntoTiles(outputTileList, streamObjects, middleIndex, thirdQuarterIndex, tileCount, thirdQuarterStreamSize);
		splitStreamObjectsIntoTiles(outputTileList, streamObjects, thirdQuarterIndex, endIndex, tileCount, fourthQuarterStreamSize);
	}
}

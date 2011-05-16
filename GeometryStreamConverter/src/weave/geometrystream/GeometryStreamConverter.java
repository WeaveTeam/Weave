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
import java.util.LinkedList;
import java.util.List;
import java.util.Vector;

import weave.utils.SerialIDGenerator;

/**
 * This class converts features from ShapefileDataStore to objects that implement the StreamObject interface.
 * 
 * @author adufilie
 */
public class GeometryStreamConverter
{
	public static boolean debugFlush = false;
	public static boolean debugDBF = false;
	public static boolean debugTime = true;
	public static boolean debugCounts = false;
	
	public GeometryStreamConverter(GeometryStreamDestination destination)
	{
		this.destination = destination;
	}

	/**
	 * The desired size, in bytes, of each metadata and geometry tile that gets generated.
	 * Actual size of some tiles may be a few bytes larger than this value.  Some tiles may be smaller.
	 */
	public int tileSize = 32 * 1024; // default 32k
	
	/**
	 * When the size of the geometry stream tile buffer becomes larger than this value, flushGeometryTiles() will be called.
	 */
	public int geometryTileFlushInterval = 10 * 1024 * 1024; // default 10 megabytes
	
	protected GeometryStreamDestination destination;
	protected SerialIDGenerator shapeIDGenerator = new SerialIDGenerator();
	protected LinkedList<StreamObject> metadataList = new LinkedList<StreamObject>();
	protected VertexMap vertexMap = new VertexMap();
	
	/**
	 * These are reused for the life of this object to minimize Java garbage collection activity.
	 */
	protected Vector<VertexChainLink> reusableVertexChainLinks = new Vector<VertexChainLink>();

	/**
	 * @param feature Contains geometries to convert.
	 * @param keyAttributes The names of attributes to be concatenated to generate a record key for this feature.
	 * @throws Exception
	 */
	public void convertFeature(FeatureGeometryStream geomStream, int shapeType, String shapeKey, String projectionWKT) throws Exception
	{

		// save shape metadata for feature
		GeometryMetadata geometryMetadata = new GeometryMetadata(shapeIDGenerator.getNext(), shapeKey, shapeType, projectionWKT);
		metadataList.add(geometryMetadata);

		long startTime = System.currentTimeMillis();
		
		// save geometry data for feature
		int firstVertexID = 0;
		while (geomStream.hasNext())
		{
			GeometryVertexStream vertexStream = geomStream.getNext();
			while (vertexStream.hasNext())
			{
				// copy vertices for this geometry part

				// add polygon marker before the next part
				if (firstVertexID > 0)
					geometryMetadata.polygonMarkerIndices.add(firstVertexID++);
				// loop through coordinates, converting them to VertexChainLink objects
				double x;
				double y;
				double firstX = Double.NaN;
				double firstY = Double.NaN;
				double prevX = Double.NaN;
				double prevY = Double.NaN;
				VertexChainLink vertex = null;
				int chainLength = 0;
				while (vertexStream.next())
				{
					x = vertexStream.getX();
					y = vertexStream.getY();
					// don't add invalid points
					if (x <= -Double.MAX_VALUE || x >= Double.MAX_VALUE ||
						y <= -Double.MAX_VALUE || y >= Double.MAX_VALUE)
					{
						continue;
					}
					// If this is the first vertex in the chain, save the coordinates.  Otherwise, perform additional checks.
					if (vertex == null)
					{
						firstX = x;
						firstY = y;
					}
					else
					{
						// don't add consecutive duplicate points
						if (x == prevX && y == prevY)
							continue;
						// stop adding points when the current coord is equal to the first coord
						if (x == firstX && y == firstY)
							break;
					}
					
					// add new point if we are at the end of outputPoints
					if (reusableVertexChainLinks.size() == chainLength)
						reusableVertexChainLinks.add(new VertexChainLink());
					
					// save coord in next vertex object
					vertex = reusableVertexChainLinks.get(chainLength);
					vertex.initialize(x, y, firstVertexID + chainLength++);
					// insert vertex in chain
					reusableVertexChainLinks.get(0).insert(vertex);
					
					prevX = x;
					prevY = y;
				}
				// ARC: end points of a part are required points
				if (geometryMetadata.isLineType() && chainLength > 0)
				{
					reusableVertexChainLinks.get(0).importance = VertexChainLink.IMPORTANCE_REQUIRED;
					reusableVertexChainLinks.get(chainLength - 1).importance = VertexChainLink.IMPORTANCE_REQUIRED;
				}
				
				// assign importance values to vertices and save them
				processVertexChain(geometryMetadata, chainLength);
				
				// done copying points for this part, advance firstVertexID to after the current part
				firstVertexID += chainLength;
			}
		}
		if (debugCounts)
		{
			long endTime = System.currentTimeMillis(); 
			System.out.println(String.format(
					"%s took %sms for %s points",
					shapeKey,
					(endTime - startTime),
					(firstVertexID-1)
				));
		}
		if (vertexMap.getTotalStreamSize() >= geometryTileFlushInterval)
			flushGeometryTiles();
	}

	/**
	 * Sorts the current vertexChain by importance value, removes least important points first.
	 * @param geometryMetadata The metadata for the current geometry.
	 * @param startingChainLength The number of points in the chain.  Can be derived from the point chain, but the code is faster if this is already known.
	 */
	protected void processVertexChain(GeometryMetadata geometryMetadata, int startingChainLength)
	{
		if (startingChainLength == 0)
			return;
		
		VertexChainLink firstVertex = reusableVertexChainLinks.get(0);
		VertexChainLink vertex = null;

		// include all vertices from chain in part bounds
		Bounds2D partBounds = new Bounds2D();
		for (int i = 0; i < startingChainLength; i++)
		{
			vertex = reusableVertexChainLinks.get(i);
			partBounds.includePoint(vertex.x, vertex.y);
		}
		// update geometry bounds to include part bounds
		geometryMetadata.bounds.includeBounds(partBounds);
		// get maximum possible importance of vertices in this part
		double maxImportance = partBounds.getImportance();

		boolean isPolygon = geometryMetadata.isPolygonType();
		boolean isLine = geometryMetadata.isLineType();
		if (isPolygon || isLine) // only calculate importance for polygons and lines
		{
			// create an Array that can hold all the points for sorting
			VertexChainLink[] sortArray = new VertexChainLink[startingChainLength];
			
			// begin removing vertices from chain
			int minSize = (isPolygon ? 3 : 2);
			int currentChainLength = startingChainLength;
			while (startingChainLength > minSize)
			{
				// sort vertices by importance
				sortVertexChain(firstVertex, sortArray);

				// in sorted order, extract each point as long as its
				// surrounding points have not been invalidated
				for (int index = 0; index < startingChainLength && currentChainLength > minSize; index++)
				{
					vertex = sortArray[index];
					// skip points whose importance needs to be updated
					if (!vertex.importanceIsValid)
						continue;
					// set firstVertex to next one to make sure next loop iteration will work
					firstVertex = vertex.next;
					// extract this vertex, invalidating adjacent vertices
					vertexMap.addPoint(geometryMetadata.shapeID, partBounds, vertex);
					vertex.removeFromChain();
					currentChainLength--;
				}
				// prepare for next loop iteration
				startingChainLength = currentChainLength;
			}
		}
		
		// remaining points are required
		// extract remaining points, setting importance value
		for (int i = 0; i < startingChainLength; i++)
		{
			vertex = firstVertex.next;
			vertex.importance = maxImportance;
			vertexMap.addPoint(geometryMetadata.shapeID, partBounds, vertex);
			vertex.removeFromChain();
		}
	}
	
	/**
	 * Calculates importance values for all points in a chain and then sorts them by importance.
	 * @param firstVertex The first point in a chain of points.
	 * @param outputSortArray An array to store the points in sorted order.
	 * @return The number of points in the chain that were sorted.
	 */
	protected int sortVertexChain(VertexChainLink firstVertex, VertexChainLink[] outputSortArray)
	{
		VertexChainLink vertex = firstVertex;
		int vertexCount = 0;
		do {
			vertex.validateImportance();
			outputSortArray[vertexCount++] = vertex;
			vertex = vertex.next;
		} while (vertex != firstVertex);
		Arrays.sort(outputSortArray, 0, vertexCount, VertexChainLink.sortByImportance);
		return vertexCount;
	}

	/**
	 * This function is used to output the current metadata stream buffer to the GeometryStreamDestination and free up memory.
	 * @throws Exception
	 */
	public void flushMetadataTiles() throws Exception
	{
		long startTime = System.currentTimeMillis();
		
		List<StreamTile> tiles = GeometryStreamUtils.groupStreamObjectsIntoTiles(metadataList, tileSize);
		destination.writeMetadataTiles(tiles);
		metadataList.clear();

		long elapsed = System.currentTimeMillis() - startTime;
		if (debugFlush)
			System.out.println(String.format(
					"wrote %s metadata tiles in %sms (%s tiles per second)",
					tiles.size(),
					elapsed,
					(int)(1000.0 * tiles.size() / elapsed)
				));
	}
	
	/**
	 * This function is used to output the current geometry stream buffer to the GeometryStreamDestination and free up memory.
	 * @throws Exception
	 */
	public void flushGeometryTiles() throws Exception
	{
		long startTime = System.currentTimeMillis();
		
		List<StreamObject> streamObjects = vertexMap.getStreamObjects();
		List<StreamTile> tiles = GeometryStreamUtils.groupStreamObjectsIntoTiles(streamObjects, tileSize);
		destination.writeGeometryTiles(tiles);
		vertexMap.clear();
		
		long elapsed = System.currentTimeMillis() - startTime;
		if (debugFlush)
			System.out.println(String.format(
					"wrote %s geometry tiles in %sms (%s tiles per second)",
					tiles.size(),
					elapsed,
					(int)(1000.0 * tiles.size() / elapsed)
			));
	}

	/**
	 * Data buffers are flushed and cleanup is performed.
	 * This function must be called after all desired shapes have been converted.
	 */
	public void flushAndCommitAll() throws Exception
	{
		flushMetadataTiles();
		flushGeometryTiles();
		destination.commit();
	}
}

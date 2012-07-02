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

package weave.data
{
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import org.openscales.proj4as.Proj4as;
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjProjection;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IProjector;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.primitives.Bounds2D;
	
	/**
	 * An interface for reprojecting columns of geometries and individual coordinates.
	 * 
	 * @author adufilie
	 * @author kmonico
	 */	
	public class ProjectionManager implements IProjectionManager
	{
		public function ProjectionManager()
		{
			if (!projectionsInitialized)
				initializeProjections();
		}
		
		[Embed(source="/weave/resources/ProjDatabase.dat", mimeType="application/octet-stream")]
		private static const ProjDatabase:Class;
		private static var projectionsInitialized:Boolean = false;

		/**
		 * This function decompresses the projection database and loads the definitions into ProjProjection.defs.
		 */
		private static function initializeProjections():void
		{
			ProjProjection.defs['EPSG:26986'] = "+title=NAD83 / Massachusetts Mainland +proj=lcc +lat_1=42.68333333333333 +lat_2=41.71666666666667 +lat_0=41 +lon_0=-71.5 +x_0=200000 +y_0=750000 +ellps=GRS80 +datum=NAD83 +units=m +no_defs";
			ProjProjection.defs["EPSG:3638"] = "+title=NAD83(NSRS2007) / Ohio South +proj=lcc +lat_1=40.03333333333333 +lat_2=38.73333333333333 +lat_0=38 +lon_0=-82.5 +x_0=600000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs";
			ProjProjection.defs['VANDG'] = "+title=Van Der Grinten +proj=vandg +x_0=0 +y_0=0 +lon_0=0";
			
			var ba:ByteArray = (new ProjDatabase()) as ByteArray;
			ba.uncompress();
			var defs:Object = ba.readObject();
			for (var key:String in defs)
				ProjProjection.defs[key] = defs[key];
			
			projectionsInitialized = true;
		}


		/**
		 * This is a multi-dimensional lookup:   unprojectedColumn -> Object, destinationSRS -> ProxyColumn
		 * Example: _reprojectedColumnCache[column][destinationSRS] is a ProxyColumn containing geometries reprojected to the given SRS.
		 */		
		private const _reprojectedColumnCache:Dictionary = new Dictionary(true); // weak links to be gc-friendly
		
		/**
		 * This function will return the projected column if a reprojection should be performed or the original column if there is no projection.
		 * @param column The column containing the geometry information.
		 * @param destinationProjStr The string corresponding to a projection destination.
		 * @return The projected column or the original column.
		 */
		public function getProjectedGeometryColumn(columnReference:IColumnReference, destinationProjectionSRS:String):IAttributeColumn
		{
			var unprojectedColumn:IAttributeColumn = WeaveAPI.AttributeColumnCache.getColumn(columnReference);
			if (unprojectedColumn == null)
				return null;
				
			// if there is no projection specified, return the original column
			if (destinationProjectionSRS == null || destinationProjectionSRS == '')
				return unprojectedColumn;
			
			// check the cache
			var srsCache:Object = _reprojectedColumnCache[unprojectedColumn] as Object;
			if (srsCache == null)
			{
				srsCache = new Object(); // destinationSRS -> ProxyColumn
				_reprojectedColumnCache[unprojectedColumn] = srsCache;
			}
			var proxyColumn:ProxyColumn = srsCache[destinationProjectionSRS] as ProxyColumn;

			// if reprojected column is cached, return it
			if (proxyColumn)
				return proxyColumn;

			// otherwise, create a proxy that will provide the reprojected shapes and save it in the cache
			proxyColumn = newDisposableChild(this, ProxyColumn);
			srsCache[destinationProjectionSRS] = proxyColumn;
			
			// create a WorkerThread that will reproject the geometries
			new WorkerThread(this, unprojectedColumn, proxyColumn, destinationProjectionSRS);
			
			return proxyColumn;
		}
		
		/**
		 * This function will check if a projection is defined for a given SRS code.
		 * @param srsCode The SRS code of the projection.
		 * @return A boolean indicating true if the projection is defined and false otherwise.
		 */
		public function projectionExists(srsCode:String):Boolean
		{
			if (srsCode && ProjProjection.defs[srsCode.toUpperCase()])
				return true;
			else
				return false;			
		}
		
		/**
		 * This function will return an IProjector object that can be used to reproject points.
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destinationSRS The SRS code of the destination projection.
		 * @return An IProjector object that reprojects from sourceSRS to destinationSRS.
		 */
		public function getProjector(sourceSRS:String, destinationSRS:String):IProjector
		{
			var lookup:String = sourceSRS + ';' + destinationSRS;
			var projector:IProjector = _projectorCache[lookup] as IProjector;
			if (!projector)
			{
				var source:ProjProjection = getProjection(sourceSRS);
				var dest:ProjProjection = getProjection(destinationSRS);
				projector = new Projector(source, dest);
				_projectorCache[lookup] = projector;
			}
			return projector;
		}

		/**
		 * This function will transform a point from the sourceSRS to the destinationSRS.
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destinationSRS The SRS code of the destination projection.
		 * @param inputAndOutput The point to transform. This is then used as the return value.
		 * @return The transformed point, inputAndOutput, or null if the transform failed.
		 */
		public function transformPoint(sourceSRS:String, destinationSRS:String, inputAndOutput:Point):Point
		{
			var sourceProj:ProjProjection = getProjection(sourceSRS);
			var destinationProj:ProjProjection = getProjection(destinationSRS);
			
			_tempProjPoint.x = inputAndOutput.x;
			_tempProjPoint.y = inputAndOutput.y;
			_tempProjPoint.z = NaN; // this is important in case the projection reads the z value.
			
			if (Proj4as.transform(sourceProj, destinationProj, _tempProjPoint))
			{
				inputAndOutput.x = _tempProjPoint.x;
				inputAndOutput.y = _tempProjPoint.y;
				return inputAndOutput;
			}
			
			inputAndOutput.x = NaN;
			inputAndOutput.y = NaN;
			return null;
		}
		
		private const _tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		
		/**
		 * This function will transform bounds from the sourceSRS to the destinationSRS. The resulting
		 * bounds are an approximation.
		 * 
		 * @param sourceSRS The SRS code of the source projection.
		 * @param destinationSRS The SRS code of the destination projection.
		 * @param inputAndOutput The bounds to transform. This is then used as the return value.
		 * @param xGridSize The number of points in the grid in the x direction.
		 * @param yGridSize The number of points in the grid in the y direction.
		 * @return The transformed bounds, inputAndOutput.
		 */
		public function transformBounds(sourceSRS:String, destinationSRS:String, inputAndOutput:IBounds2D, 
			xGridSize:int = 32, yGridSize:int = 32):IBounds2D
		{
			//// NOTE: this function is optimized for speed 
			var bounds:Bounds2D = inputAndOutput as Bounds2D;
			var xn:int = xGridSize;
			var yn:int = yGridSize; // same as above
			var w:Number = bounds.getWidth();
			var h:Number = bounds.getHeight();
			var xMin:Number = bounds.xMin;
			var xMax:Number = bounds.xMax;
			var yMin:Number = bounds.yMin;
			var yMax:Number = bounds.yMax;
			var projector:IProjector = getProjector(sourceSRS, destinationSRS); // fast projection

			// NOTE: We can't just reproject the coordinates around the edges because the edges may include
			// invalid coordinates and then we would miss the valid coordinates in the middle of the bounds.
			
			// reproject points along the edges and zig zag inside
			// o--o--o--o--o
			// |  |  |  |  |
			// o--o-- --o--o
			// |  |  |  |  |
			// o-- --o-- --o
			// |  |  |  |  |
			// o--o-- --o--o
			// |  |  |  |  |
			// o--o--o--o--o
			// most of the work is through projecting a point, and this distribution tries to minimize
			// the work without sacrificing accuracy
			_tempBounds.reset();
			var oddX:Boolean = true;
			for (var x:int = 0; x <= xn; ++x)
			{
				oddX = !oddX;
				var oddY:Boolean = true;
				for (var y:int = 0; y <= yn; ++y)
				{
					oddY = !oddY;

					if (x == 0 || y == 0 || x == xn || y == yn 
						|| (oddX && oddY) || (!oddX && !oddY))
					{
						_tempPoint.x = xMin + x * w / xn;
						_tempPoint.y = yMin + y * h / yn;
						projector.reproject(_tempPoint);
						if (isFinite(_tempPoint.x) && isFinite(_tempPoint.y))
							_tempBounds.includePoint(_tempPoint);
					}
				}
			}
			
			inputAndOutput.copyFrom(_tempBounds);
			return inputAndOutput;
		}
		
		/**
		 * getProjection
		 * @param srsCode The SRS Code of a projection.
		 * @return A cached ProjProjection object for the specified SRS Code.
		 */
		public function getProjection(srsCode:String):ProjProjection
		{
			if (!srsCode)
				return null;
			
			srsCode = srsCode.toUpperCase();
			
			if (_srsToProjMap.hasOwnProperty(srsCode))
				return _srsToProjMap[srsCode];
			
			if (projectionExists(srsCode))
				return _srsToProjMap[srsCode] = new ProjProjection(srsCode);
			
			return null;
		}
		
		/**
		 * This maps a pair of SRS codes separated by a semicolon to a Projector object.
		 */
		private const _projectorCache:Object = {};

		/**
		 * This maps an SRS Code to a cached ProjProjection object for that code.
		 */
		private const _srsToProjMap:Object = {};
		
		/**
		 * This is a temporary object used for single point transformations.
		 */
		private const _tempProjPoint:ProjPoint = new ProjPoint();
		
		/**
		 * This is a temporary object used only in transformBounds.
		 */
		private const _tempPoint:Point = new Point();

	}
}

import flash.geom.Point;

import org.openscales.proj4as.Proj4as;
import org.openscales.proj4as.ProjPoint;
import org.openscales.proj4as.ProjProjection;

import weave.api.WeaveAPI;
import weave.api.data.AttributeColumnMetadata;
import weave.api.data.DataTypes;
import weave.api.data.IAttributeColumn;
import weave.api.data.IColumnWrapper;
import weave.api.data.IProjector;
import weave.api.data.IQualifiedKey;
import weave.data.AttributeColumns.GeometryColumn;
import weave.data.AttributeColumns.ProxyColumn;
import weave.data.AttributeColumns.StreamedGeometryColumn;
import weave.data.ProjectionManager;
import weave.primitives.BLGNode;
import weave.primitives.GeneralizedGeometry;
import weave.utils.BLGTreeUtils;
import weave.utils.ColumnUtils;
	
internal class WorkerThread
{
	public function WorkerThread(projectionManager:ProjectionManager, unprojectedColumn:IAttributeColumn, proxyColumn:ProxyColumn, destinationProjectionSRS:String)
	{
		this.projectionManager = projectionManager;
		this.unprojectedColumn = unprojectedColumn;
		this.proxyColumn = proxyColumn;
		this.destinationProjSRS = destinationProjectionSRS;

		// start reprojecting now and each time the unprojected column changes
		unprojectedColumn.addImmediateCallback(
			this,
			function():void
			{
				WeaveAPI.StageUtils.startTask(unprojectedColumn, iterate, WeaveAPI.TASK_PRIORITY_PARSING);
			},
			true
		);
	}
	
	// values passed to the constructor -- these will not change.
	private var projectionManager:ProjectionManager;
	private var unprojectedColumn:IAttributeColumn;
	private var proxyColumn:ProxyColumn;
	private var destinationProjSRS:String;
	
	// these values may change as the geometries are processed.
	private var prevTriggerCounter:uint = 0; // the ID of the current task, prevents old tasks from continuing
	private var keys:Array; // the keys in the unprojectedColumn
	private var values:Array; // the values in the unprojectedColumn
	private var numGeoms:int; // the total number of geometries to process
	private var keyIndex:int; // the index of the IQualifiedKey in the keys Array that needs to be processed
	private var coordsVectorIndex:int; // the index of the Array in coordsVector that should be passed to GeneralizedGeometry.setCoordinates()
	private var keysVector:Vector.<IQualifiedKey>; // vector to pass to GeometryColumn.setGeometries()
	private var geomVector:Vector.<GeneralizedGeometry>; // vector to pass to GeometryColumn.setGeometries()
	private const coordsVector:Vector.<Array> = new Vector.<Array>(); // each Array will be passed to setCoordinates() on the corresponding GeneralizedGeometry 
	private var sourceProj:ProjProjection; // parameter for Proj4as.transform()
	private var destinationProj:ProjProjection; // parameter for Proj4as.transform()

	// reusable temporary object
	private static const _tempProjPoint:ProjPoint = new ProjPoint();
	
	/**
	 * This function will reproject the geometries in a column.
	 * @return A number between 0 and 1 indicating the progress.
	 */
	private function iterate():Number
	{
		// reset if something changed
		if (prevTriggerCounter != unprojectedColumn.triggerCounter)
		{
			prevTriggerCounter = unprojectedColumn.triggerCounter;
			
			// if the source and destination projection are the same, we don't need to reproject.
			// if we don't know the projection of the original column, we can't reproject.
			// if there is no destination projection, don't reproject.
			var sourceProjSRS:String = unprojectedColumn.getMetadata(AttributeColumnMetadata.PROJECTION);
			if (sourceProjSRS == destinationProjSRS ||
				!projectionManager.projectionExists(sourceProjSRS) ||
				!projectionManager.projectionExists(destinationProjSRS))
			{
				proxyColumn.setMetadata(null);
				proxyColumn.setInternalColumn(unprojectedColumn);
				return 1; // done
			}
			
			// we need to reproject
			
			// if the internal column is the original column, create a new internal column because we don't want to overwrite the original
			if (proxyColumn.getInternalColumn() == null || proxyColumn.getInternalColumn() == unprojectedColumn)
			{
				proxyColumn.setInternalColumn(new GeometryColumn());
			}
	
			// set metadata on proxy column
			//TODO: this metadata may not be sufficient... IAttributeColumn may need a way to list available metadata property names
			// or provide another column to get metadata from
			var metadata:XML = <attribute
					title={ ColumnUtils.getTitle(unprojectedColumn) }
					keyType={ ColumnUtils.getKeyType(unprojectedColumn) }
					dataType={ DataTypes.GEOMETRY }
					projection={ destinationProjSRS }
				/>;
			proxyColumn.setMetadata(metadata);
	
			// try to find an internal StreamedGeometryColumn
			var internalColumn:IAttributeColumn = unprojectedColumn;
			while (!(internalColumn is StreamedGeometryColumn) && internalColumn is IColumnWrapper)
				internalColumn = (internalColumn as IColumnWrapper).getInternalColumn();
			var streamedGeomColumn:StreamedGeometryColumn = internalColumn as StreamedGeometryColumn;
			if (streamedGeomColumn)
			{
				// Request the full unprojected detail because we don't know how much unprojected
				// detail we need to display the appropriate amount of reprojected detail. 
				streamedGeomColumn.requestGeometryDetail(streamedGeomColumn.collectiveBounds, 0);
				// if still downloading the tiles, do not reproject
				if (streamedGeomColumn.isStillDownloading())
					return 1; // done
			}
	
			// initialize variables before calling processGeometries()
			keys = unprojectedColumn.keys; // all keys
			values = []; // all values
			numGeoms = 0;
			for (var i:int = 0; i < keys.length; i++)
			{
				var value:Array = unprojectedColumn.getValueFromKey(keys[i]) as Array;
				numGeoms += value.length;
				values.push(value);
			}
			keyIndex = 0;
			coordsVectorIndex = 0;
			keysVector = new Vector.<IQualifiedKey>();
			geomVector = new Vector.<GeneralizedGeometry>();
			coordsVector.length = 0;
			sourceProj = projectionManager.getProjection(sourceProjSRS);
			destinationProj = projectionManager.getProjection(destinationProjSRS);
		}
		
		// begin iteration
		if (keyIndex < keys.length)
		{
			// step 1: generate GeneralizedGeometry objects and project coordinates
			var key:IQualifiedKey = keys[keyIndex] as IQualifiedKey;
			var geomArray:Array = values[keyIndex] as Array;
			for (var geometryIndex:int = 0; geomArray && geometryIndex < geomArray.length; ++geometryIndex)
			{
				var oldGeometry:GeneralizedGeometry = geomArray[geometryIndex] as GeneralizedGeometry;
				var geomParts:Vector.<Vector.<BLGNode>> = oldGeometry.getSimplifiedGeometry(); // no parameters = full list of vertices
				var geomIsPolygon:Boolean = oldGeometry.geomType == GeneralizedGeometry.GEOM_TYPE_POLYGON;

				var newCoords:Array = [];
				var newGeometry:GeneralizedGeometry = new GeneralizedGeometry(oldGeometry.geomType);
				
				// fill newCoords array with reprojected coordinates
				for (var iPart:int = 0; iPart < geomParts.length; ++iPart)
				{
					var part:Vector.<BLGNode> = geomParts[iPart];
					for (var iNode:int = 0; iNode < part.length; ++iNode)
					{
						var currentNode:BLGNode = part[iNode];
						
						_tempProjPoint.x = currentNode.x;
						_tempProjPoint.y = currentNode.y;
						_tempProjPoint.z = NaN; // this is important in case the projection reads the z value.
						if (Proj4as.transform(sourceProj, destinationProj, _tempProjPoint) == null)
							continue;
						
						var x:Number = _tempProjPoint.x;
						var y:Number = _tempProjPoint.y;
						// sometimes the reprojection may map a point to NaN.
						// if this occurs, we ignore the reprojected point because NaN is reserved as a marker for end of the part
						if (isNaN(x) || isNaN(y))
							continue;
						
						//if (!isFinite(_tempProjPoint.x) || !isFinite(_tempProjPoint.y))
						//	trace("point mapped to infinity");
						
						// save reproj coords
						newCoords.push(x, y);
					}
					
					// append part marker
					newCoords.push(NaN, NaN);
				}
				// indices in all vectors must match up
				keysVector.push(key);
				geomVector.push(newGeometry);
				// save coordinates for later processing
				coordsVector.push(newCoords);
			}
			keyIndex++;
		}
		else if (coordsVectorIndex < coordsVector.length)
		{
			// step 2: generate BLGTrees
			newGeometry = geomVector[coordsVectorIndex];
			newGeometry.setCoordinates(coordsVector[coordsVectorIndex], BLGTreeUtils.METHOD_SAMPLE);
			coordsVectorIndex++;
		}
		
		var progress:Number = (coordsVector.length + coordsVectorIndex) / (numGeoms + numGeoms);
		if (progress == 1 || isNaN(progress)) // (0/0) is NaN
		{
			// after all geometries have been reprojected, update the reprojected column
			var reprojectedColumn:GeometryColumn = proxyColumn.getInternalColumn() as GeometryColumn;
			reprojectedColumn.setGeometries(keysVector, geomVector);
			return 1;
		}
		//trace('(',keyIndex,'+',coordsVectorIndex,') / (',keys.length,'+',coordsVector.length,') =',StandardLib.roundSignificant(progress, 2));
		return progress;
	}
}

internal class Projector implements IProjector
{
	public function Projector(source:ProjProjection, dest:ProjProjection)
	{
		this.source = source;
		this.dest = dest;
	}
	
	private var source:ProjProjection;
	private var dest:ProjProjection;
	private var tempProjPoint:ProjPoint = new ProjPoint();
	
	public function reproject(inputAndOutput:Point):Point
	{
		if (source == dest || !source || !dest)
			return inputAndOutput;
		
		tempProjPoint.x = inputAndOutput.x;
		tempProjPoint.y = inputAndOutput.y;
		tempProjPoint.z = NaN; // this is important in case the projection reads the z value.
		if (Proj4as.transform(source, dest, tempProjPoint))
		{
			inputAndOutput.x = tempProjPoint.x;
			inputAndOutput.y = tempProjPoint.y;
			return inputAndOutput;
		}

		inputAndOutput.x = NaN;
		inputAndOutput.y = NaN;
		return null;
	}
}


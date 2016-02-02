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

package weavejs.geom
{
	import org.vanrijkom.shp.ShpHeader;
	import org.vanrijkom.shp.ShpPoint;
	import org.vanrijkom.shp.ShpPolygon;
	import org.vanrijkom.shp.ShpPolyline;
	import org.vanrijkom.shp.ShpRecord;
	import org.vanrijkom.shp.ShpTools;
	
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.geom.GeneralizedGeometry;
	import weavejs.geom.GeometryType;
	import weavejs.util.JS;
	import weavejs.util.JSByteArray;
	
	
	/**
	 * The callbacks for this object get called when all queued decoding completes.
	 * 
	 * @author adufilie
	 * @author awilkins
	 */
	public class ShpFileReader implements ILinkableObject
	{
		private var shp: ShpHeader;
		
		private var records:Array;
		private var irecord:int = 0;
		public var geoms:Array = [];
		
		private var _processingIsDone:Boolean = false;
		public function get geomsReady():Boolean { return _processingIsDone; }
		
		public function ShpFileReader(shpData:JSByteArray)
		{
			shp	= new ShpHeader(shpData);
			records = ShpTools.readRecords(shpData);
			// high priority because not much can be done without data
			WeaveAPI.Scheduler.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete);
		}
		
		private function iterate(stopTime:int):Number
		{
			for (; irecord < records.length; irecord++)
			{
				if (JS.now() > stopTime)
					return irecord / records.length;
	
				var iring:int
				var ipoint:int;
				var point:ShpPoint;
				var ring:Array;
				
				//trace( irecord, records.length );
				var geom:GeneralizedGeometry = new GeneralizedGeometry();
				var points:Array = [];
				var record:ShpRecord = records[irecord] as ShpRecord;
	
				if( record.shape is ShpPolygon )
				{
					geom.geomType = GeometryType.POLYGON;
					var poly:ShpPolygon = record.shape as ShpPolygon;
					for(iring = 0; iring < poly.rings.length; iring++ )
					{
						// add part marker if this is not the first part
						if (iring > 0)
							points.push(NaN, NaN);
						ring = poly.rings[iring] as Array;
						for(ipoint = 0; ipoint < ring.length; ipoint++ )
						{
							point = ring[ipoint] as ShpPoint;
							points.push( point.x, point.y );
						}
					}
				}
				if( record.shape is ShpPolyline )
					geom.geomType = GeometryType.LINE;
				if( record.shape is ShpPoint )
				{
					geom.geomType = GeometryType.POINT;
					point = record.shape as ShpPoint;
					points.push( point.x, point.y );
				}
				if (points)
					geom.setCoordinates( points, BLGTreeUtils.METHOD_SAMPLE );
				geoms.push(geom);
			}
			return 1;
		}
		
		private function asyncComplete():void
		{
			_processingIsDone = true;
			Weave.getCallbacks(this).triggerCallbacks();
		}
	}
}
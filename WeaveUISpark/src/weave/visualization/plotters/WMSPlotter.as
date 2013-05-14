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

package weave.visualization.plotters
{
	import com.modestmaps.mapproviders.BlueMarbleMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.mapproviders.OpenStreetMapProvider;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.TriangleCulling;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import org.openscales.proj4as.ProjConstants;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObjectWithBusyStatus;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IProjector;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.services.IWMSService;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.primitives.Bounds2D;
	import weave.services.wms.CustomWMS;
	import weave.services.wms.ModestMapsWMS;
	import weave.services.wms.OnEarthProvider;
	import weave.services.wms.OpenMapQuestAerialProvider;
	import weave.services.wms.OpenMapQuestProvider;
	import weave.services.wms.StamenProvider;
	import weave.services.wms.WMSProviders;
	import weave.services.wms.WMSTile;
	import weave.utils.Dictionary2D;

	/**
	 * WMSPlotter
	 *  
	 * @author adufilie
	 * @author kmonico
	 * @author skolman
	 */
	public class WMSPlotter extends AbstractPlotter implements ILinkableObjectWithBusyStatus, IDisposableObject
	{
		// TODO: move the image reprojection code elsewhere
		
		public function WMSPlotter()
		{
			_textField.autoSize = "left";			
			_textField.textColor = 0xFFFFFF;
			_textField.thickness = 2;
			_textField.background = true;
			_textField.backgroundColor = 0x000000;
			_textField.alpha = 0.2;
			
			//setting default WMS Map to Blue Marble
			setProvider(WMSProviders.BLUE_MARBLE_MAP);
		}

		// the service and its parameters
		private function get _service():IWMSService
		{
			return service.internalObject as IWMSService;
		}
		
		public function get providerName():String
		{
			if(service.internalObject == null)
				return null;
			var provider:* = (service.internalObject as IWMSService).getProvider();
			
			if(provider is String)
			{
				return provider as String;
			}else
			{
				if(provider is BlueMarbleMapProvider)
					return WMSProviders.BLUE_MARBLE_MAP;
				else if(provider is OnEarthProvider)
					return WMSProviders.NASA;
				else if(provider is OpenStreetMapProvider)
					return WMSProviders.OPEN_STREET_MAP;
				else if(provider is OpenMapQuestProvider)
					return WMSProviders.MAPQUEST;
				else if(provider is OpenMapQuestAerialProvider)
					return WMSProviders.MAPQUEST_AERIAL;
				else if(provider is StamenProvider)
				{
					var stamenProvider:StamenProvider = provider as StamenProvider;
					if(stamenProvider.style == StamenProvider.STYLE_TERRAIN)
						return WMSProviders.STAMEN_TERRAIN;
					if(stamenProvider.style == StamenProvider.STYLE_TONER)
						return WMSProviders.STAMEN_TONER;
					if(stamenProvider.style == StamenProvider.STYLE_WATERCOLOR)
						return WMSProviders.STAMEN_WATERCOLOR;
				}
				else if(provider is CustomWMS)
					return WMSProviders.CUSTOM_MAP;
			}
			
			return null;
		}
		
		public const service:LinkableDynamicObject = registerSpatialProperty(new LinkableDynamicObject(IWMSService));
		
		public const preferLowerQuality:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
//		public const serviceName:LinkableString = registerSpatialProperty(new LinkableString(WMSProviders.BLUE_MARBLE_MAP, verifyServiceName), setProvider);
		public const srs:LinkableString = newSpatialProperty(LinkableString); // needed for linking MapTool settings
		public const styles:LinkableString = newLinkableChild(this, LinkableString, setStyle); // needed for changing seasons
		public const displayMissingImage:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		// reusable objects
		private const _tempMatrix:Matrix = new Matrix(); 
		private const _tempDataBounds:IBounds2D = new Bounds2D();
		private const _tempScreenBounds:IBounds2D = new Bounds2D();
		private const _tempBackgroundDataBounds:IBounds2D = new Bounds2D();
		private const _clipRectangle:Rectangle = new Rectangle();
		
		// used to show a missing image
		[Embed(source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:Bitmap = Bitmap(new _missingImageClass());
		private static const _missingImageColorTransform:ColorTransform = new ColorTransform(1, 1, 1, 0.25);
		
		// reprojecting bitmaps 
		public const gridSpacing:LinkableNumber = registerSpatialProperty(new LinkableNumber(12)); // number of pixels between grid points
		private const _tempBounds:IBounds2D = new Bounds2D();
		private const _tempImageBounds:IBounds2D = new Bounds2D(); // bounds of the image
		private const _latLonBounds:IBounds2D = new Bounds2D(-180 + ProjConstants.EPSLN, -90 + ProjConstants.EPSLN, 180 - ProjConstants.EPSLN, 90 - ProjConstants.EPSLN);
		private const _allowedTileReprojBounds:IBounds2D = new Bounds2D(); // allowed bounds for point to point reprojections
		private const _normalizedGridBounds:IBounds2D = new Bounds2D();
		private const _tempReprojPoint:Point = new Point(); // reusable object for reprojections
		private const projManager:IProjectionManager = WeaveAPI.ProjectionManager; // reprojecting tiles
		private const _tileSRSToShapeCache:Dictionary2D = new Dictionary2D(true, true); // use WeakReferences to be GC friendly
		
		private function getDestinationSRS():String
		{
			if (projManager.projectionExists(srs.value))
				return srs.value;
			return _service.getProjectionSRS();
		}
		
		// reusable objects in getShape()
		private const vertices:Vector.<Number> = new Vector.<Number>();
		private const indices:Vector.<int> = new Vector.<int>();
		private const uvtData:Vector.<Number> = new Vector.<Number>();
		private function getShape(tile:WMSTile):ProjectedShape
		{
			// check if this tile has a cached shape
			var cachedValue:ProjectedShape = _tileSRSToShapeCache.get(tile, getDestinationSRS());
			if (cachedValue != null)
				return cachedValue;
			
			// we need to create the cached shape
			var reprojectedDataBounds:IBounds2D = new Bounds2D();
			vertices.length = 0;
			indices.length = 0;
			uvtData.length = 0;
						
			// get projector for optimized reprojection
			var serviceSRS:String = _service.getProjectionSRS();
			var projector:IProjector = projManager.getProjector(serviceSRS, srs.value);
			
			// Make lower-left corner of image 0,0 normalized coordinates by making this height negative.
			// To eliminate the seams between images, adjust grid bounds so edge
			// coordinates 0 and 1 will get projected to slightly outside tile.bounds.
			var overlap:Number = 0; // in pixels
			_normalizedGridBounds.setCenteredRectangle(
				.5,
				.5,
				(tile.imageWidth - overlap) / (tile.imageWidth),
				- (tile.imageHeight - overlap) / (tile.imageHeight)
			);

			var fences:int = Math.max(tile.imageWidth, tile.imageHeight) / gridSpacing.value; // number of spaces in the grid x or y direction
			var fencePosts:int = fences + 1; // number of vertices in the grid
			for (var iy:int = 0; iy < fencePosts; ++iy)
			{
				for (var ix:int = 0; ix < fencePosts; ++ix)
				{
					var xNorm:Number = ix / fences;
					var yNorm:Number = iy / fences;

					// percent bounds of where we are in the image space
					_tempReprojPoint.x = xNorm;
					_tempReprojPoint.y = yNorm;
					
					// project normalized grid coords to tile data coords
					_normalizedGridBounds.projectPointTo(_tempReprojPoint, tile.bounds);
					
					// reproject the point before pushing it as a vertex
					_allowedTileReprojBounds.constrainPoint(_tempReprojPoint);
					projector.reproject(_tempReprojPoint);

					reprojectedDataBounds.includePoint(_tempReprojPoint);
					vertices.push(_tempReprojPoint.x, _tempReprojPoint.y);

					// Flash lines up UVT coordinate values 0 and 1 to the center of the edge pixels of an image,
					// meaning half a pixel will be lost on all edges.  This code adjusts the normalized values so
					// the edge pixels are not cut in half by converting our definition of normalized coordinates
					// into flash player's definition.
					var offset:Number = 0.5 + overlap;
					uvtData.push(
						(xNorm * tile.imageWidth - offset) / (tile.imageWidth - offset * 2),
						(yNorm * tile.imageHeight - offset) / (tile.imageHeight - offset * 2)
					);
					
					if (iy == 0 || ix == 0) 
						continue; 
					
					// save indices for two triangles -- we are currently at fence post D in this diagram:
					// A---B
					// | / |
					// C---D
					var a:int = (iy - 1) * fencePosts + (ix - 1);
					var b:int = (iy - 1) * fencePosts + ix;
					var c:int = iy * fencePosts + (ix - 1);
					var d:int = iy * fencePosts + ix;
					indices.push(a,b,c);
					indices.push(c,b,d);
				}
			}
			
			// draw the triangles and end the fill
			var newShape:Shape = new Shape();
			//newShape.graphics.lineStyle(1, 0xFFFFFF, 0.5, false, LineScaleMode.NONE);
			//newShape.graphics.lineStyle(1, 0, 1, true, LineScaleMode.NONE);
			newShape.graphics.beginBitmapFill(tile.bitmapData, null, false, true); // it's important to disable the repeat option
			newShape.graphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NEGATIVE);
			newShape.graphics.endFill();
			
			// save the shape and bounds into the token object and put in cache
			var projShape:ProjectedShape = new ProjectedShape();
			projShape.shape = newShape;
			reprojectedDataBounds.makeSizePositive();
			projShape.bounds = reprojectedDataBounds;

			_tileSRSToShapeCache.set(tile, getDestinationSRS(), projShape);

			return projShape;
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// if there is no service to use, we can't draw anything
			if (_service == null)
				return;

			var serviceSRS:String = _service.getProjectionSRS();			
			var mapProjExists:Boolean = projManager.projectionExists(srs.value);
			var areProjectionsDifferent:Boolean = serviceSRS != srs.value;
			if (!areProjectionsDifferent || !mapProjExists)
			{
				drawUnProjectedTiles(dataBounds, screenBounds, destination);
				return;
			}
			
			//// THERE IS A PROJECTION
			
			getBackgroundDataBounds(_tempBackgroundDataBounds);

			_tempDataBounds.copyFrom(dataBounds);
			_tempScreenBounds.copyFrom(screenBounds);

			// before we do anything, we must get the dataBounds in the same coordinates as the service
			if (areProjectionsDifferent && mapProjExists) 
			{
				// make sure _tempDataBounds is within the valid range
				_tempBackgroundDataBounds.constrainBounds(_tempDataBounds, false);
				_tempDataBounds.centeredResize(_tempDataBounds.getWidth() - ProjConstants.EPSLN, _tempDataBounds.getHeight() - ProjConstants.EPSLN);
				
				// calculate screen bounds that corresponds to _tempDataBounds
				_tempScreenBounds.copyFrom(_tempDataBounds);
				dataBounds.projectCoordsTo(_tempScreenBounds, screenBounds);
			
				// transform the bounds--this hurts performance!
				projManager.transformBounds(srs.value, serviceSRS, _tempDataBounds);
			}

			// expand the data bounds so some surrounding tiles are downloaded to improve panning
			var allTiles:Array = _service.requestImages(_tempDataBounds, _tempScreenBounds, preferLowerQuality.value);
			
			dataBounds.transformMatrix(screenBounds, _tempMatrix, true);

			// draw each tile's reprojected shape
			for (var i:int = 0; i < allTiles.length; i++)
			{
				var tile:WMSTile = allTiles[i];
				if (tile.bitmapData == null)
				{
					if (displayMissingImage.value == false)
						continue;
					tile.bitmapData = _missingImage.bitmapData;
				}

				// projShape.bounds coordinates are reprojected data coords of the tile
				var projShape:ProjectedShape = getShape(tile);
				if (!projShape.bounds.overlaps(dataBounds))
					continue; // don't draw off-screen bitmaps
				
				var colorTransform:ColorTransform = (tile.bitmapData == _missingImage.bitmapData ? _missingImageColorTransform : null);
				destination.draw(projShape.shape, _tempMatrix, colorTransform, null, null, preferLowerQuality.value && !colorTransform);				
			}
			drawCreditText(destination);
		}

		/**
		 * This function will draw tiles which do not need to be reprojected.
		 */
		private function drawUnProjectedTiles(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (_service == null)
				return;

			var allTiles:Array = _service.requestImages(dataBounds, screenBounds, preferLowerQuality.value);
				
			for (var i:int = 0; i < allTiles.length; i++)
			{
				var tile:WMSTile = allTiles[i];
				// above we requested some tiles outside the dataBounds... we don't want to draw them
				if (!tile.bounds.overlaps(dataBounds, false))
					continue;
				
				// if there is no bitmap data, decide whether to continue or display missing image
				if (tile.bitmapData == null)
				{
					if (displayMissingImage.value == false)
						continue;
					
					tile.bitmapData = _missingImage.bitmapData;
				}
				
				var imageBounds:IBounds2D = tile.bounds;
				var imageBitmap:BitmapData = tile.bitmapData;
				
				// get screen coords from image data coords
				_tempBounds.copyFrom(imageBounds); // data
				dataBounds.projectCoordsTo(_tempBounds, screenBounds); // data to screen
				_tempBounds.makeSizePositive(); // positive screen direction

				// when scaling, we need to use the ceiling of the values to cover the seam lines
				_tempMatrix.identity();
				_tempMatrix.scale(
					Math.ceil(_tempBounds.getWidth()) / imageBitmap.width,
					Math.ceil(_tempBounds.getHeight()) / imageBitmap.height
				);
				_tempMatrix.translate(
					Math.round(_tempBounds.getXMin()),
					Math.round(_tempBounds.getYMin())
				);

				// calculate clip rectangle for nasa service because tiles go outside the lat/long bounds
				_service.getAllowedBounds(_tempBounds); // data
				dataBounds.projectCoordsTo(_tempBounds, screenBounds); // data to screen
				_tempBounds.getRectangle(_clipRectangle); // get screen rect
				_clipRectangle.x = Math.floor(_clipRectangle.x);
				_clipRectangle.y = Math.floor(_clipRectangle.y);
				_clipRectangle.width = Math.floor(_clipRectangle.width - 0.5);
				_clipRectangle.height = Math.floor(_clipRectangle.height - 0.5);
				
				var colorTransform:ColorTransform = (imageBitmap == _missingImage.bitmapData ? _missingImageColorTransform : null);
				destination.draw(imageBitmap, _tempMatrix, colorTransform, null, _clipRectangle, preferLowerQuality.value && !colorTransform);				
			}
			drawCreditText(destination);
		}
		
		private const _textField:TextField = new TextField(); // reusable object
		private function drawCreditText(destination:BitmapData):void
		{
			var _providerCredit:String = _service.getCreditInfo();
			if (_providerCredit)
			{
				_textField.text = _providerCredit;
				_tempMatrix.identity();
				_tempMatrix.translate(0, destination.height - _textField.height);
				destination.draw(_textField, _tempMatrix);
			}
		}

		/**
		 * Set the provider for the plotter.
		 */
		public function setProvider(provider:String):void
		{
			if(!verifyServiceName(provider))
				return;
			
			if (provider == WMSProviders.NASA)
			{
				service.requestLocalObject(OnEarthProvider,false);
			}
			else if(provider == WMSProviders.CUSTOM_MAP)
			{
				service.requestLocalObject(CustomWMS,false);
			}
			else
			{
				service.requestLocalObject(ModestMapsWMS,false);
				_service.setProvider(provider);
			}
			
			// determine maximum bounds for reprojecting images
			_allowedTileReprojBounds.copyFrom(_latLonBounds);
			projManager.transformBounds("EPSG:4326", WMSProviders.getSRS(provider), _allowedTileReprojBounds);
			spatialCallbacks.triggerCallbacks();
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
			if (_service != null)
			{
				// determine bounds of plotter
				_service.getAllowedBounds(output);
				
				var serviceSRS:String = _service.getProjectionSRS();
				if (serviceSRS != srs.value
					&& projManager.projectionExists(srs.value)
					&& projManager.projectionExists(serviceSRS))
				{
					projManager.transformBounds(_service.getProjectionSRS(), srs.value, output);
				}
			}
		}
		
		public function dispose():void
		{
			if (_service != null)
				_service.cancelPendingRequests(); // cancel everything to prevent any callbacks from running
			WeaveAPI.SessionManager.disposeObjects(_service);
		}

		/**
		 * This function will set the style of the image requests for NASA WMS.
		 */
		public function setStyle():void
		{
			var nasaService:OnEarthProvider = _service as OnEarthProvider;
			var style:String = styles.value;
			
			if (nasaService == null)
				return;
			
			nasaService.changeStyleToMonth(style);
		}
		
		private function verifyServiceName(s:String):Boolean
		{
			if (s == null || s == '')
				return false;
			
			return WMSProviders.providers.indexOf(s) >= 0;
		}
		
		public function isBusy():Boolean
		{
			return false;
		}
		[Deprecated(replacement="service")] public function set serviceName(value:String):void { setProvider(value); }
	}
}

import flash.display.Shape;

import weave.api.primitives.IBounds2D;

// an internal object used for reprojecting shapes
internal class ProjectedShape
{
	public var shape:Shape;
	public var bounds:IBounds2D;
	public var imageWidth:int;
	public var imageHeight:int;	
}
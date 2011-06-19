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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Rectangle;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ICallbackInterface;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotter;
	import weave.core.CallbackCollection;
	import weave.data.KeySets.FilteredKeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.ObjectPool;
	
	/**
	 * This is a base implementation for an IPlotter.
	 * 
	 * @author adufilie
	 */
	public class AbstractPlotter implements IPlotter, IDisposableObject
	{
		/**
		 * @param columnToGetKeysFrom The column that the IKeySet object uses to get keys from.
		 */
		public function AbstractPlotter()
		{
			spatialCallbacks.addImmediateCallback(this, returnPooledObjects);
			
			// add callbacks to the spatial properties that were created before spatialCallbackCollection was created.
			while (pendingSpatialProperties != null && pendingSpatialProperties.length > 0)
				registerLinkableChild(spatialCallbacks, pendingSpatialProperties.shift());
		}
		
		/**
		 * This is the list of Bounds2D objects that were returned by getReusableBounds().
		 * These objects will be returned to the ObjectPool when spatialCallbacks run.
		 */
		private var pooledObjects:Array = [];
		
		/**
		 * This function gets called as the first spatial callback.
		 * All Bounds2D objects that were returned by getReusableBounds() will return to the ObjectPool.
		 */
		private function returnPooledObjects():void
		{
			for each (var object:Object in pooledObjects)
				ObjectPool.returnObject(object);
			pooledObjects = [];
		}
		
		/**
		 * This function gets a Bounds2D object that can only be used until the spatial callbacks run.
		 * When the spatial callbacks run, these objects will be reclaimed to be used again later.
		 * It is recommended to use this function only for implementing the getDataBoundsFromRecordKey()
		 * and getBackgroundDataBounds() functions.
		 * @param xMin Value to set for Bounds2D.xMin
		 * @param yMin Value to set for Bounds2D.yMin
		 * @param xMax Value to set for Bounds2D.xMax
		 * @param yMax Value to set for Bounds2D.yMax
		 * @return A Bounds2D object that can be used in getDataBoundsFromRecordKey() and getBackgroundDataBounds().
		 */
		protected function getReusableBounds(xMin:Number = NaN, yMin:Number = NaN, xMax:Number = NaN, yMax:Number = NaN):Bounds2D
		{
			var bounds:Bounds2D = ObjectPool.borrowObject(Bounds2D);
			bounds.setBounds(xMin, yMin, xMax, yMax);
			pooledObjects.push(bounds);
			return bounds;
		}

		/**
		 * This is a list of spatial properties that we haven't added callbacks to yet.
		 */
		private var pendingSpatialProperties:Array;
		
		/**
		 * This function creates a new registered linkable child of the plotter whose callbacks will also trigger the spatial callbacks.
		 * @return A new instance of the specified class that is registered as a spatial property.
		 */
		protected function newSpatialProperty(linkableChildClass:Class, callback:Function = null):*
		{
			var child:ILinkableObject = newLinkableChild(this, linkableChildClass, callback);
			_registerSpatialChild(child);
			return child;
		}
		
		/**
		 * This function registers a linkable child of the plotter whose callbacks will also trigger the spatial callbacks.
		 * @param child An object to register as a spatial property.
		 * @return The child object.
		 */
		protected function registerSpatialProperty(child:ILinkableObject, callback:Function = null):*
		{
			registerLinkableChild(this, child, callback);
			_registerSpatialChild(child);
			return child;
		}
		
		private function _registerSpatialChild(child:ILinkableObject):void
		{
			if (spatialCallbacks)
			{
				registerLinkableChild(spatialCallbacks, child);
			}
			else
			{
				if (pendingSpatialProperties == null)
					pendingSpatialProperties = []
				pendingSpatialProperties.push(child);
			}
		}
		
		/**
		 * This function will cause the spatialCallbacks and plotter callbacks to trigger when the given sessioned properties run their callbacks.
		 * @param firstProperty A sessioned object that is a spatial property of the plotter.
		 * @param moreProperties More sessioned objects that are spatial properties of the plotter.
		 */
		protected function registerSpatialProperties(firstProperty:ILinkableObject, ...moreProperties):void
		{
			(moreProperties as Array).unshift(firstProperty);
			for each (firstProperty in moreProperties)
				registerSpatialProperty(firstProperty);
		}

		/**
		 * This function creates a new registered linkable child of the plotter.
		 */
		protected function newNonSpatialProperty(linkableChildClass:Class, callback:Function = null, useGroupedCallback:Boolean = false):*//, callbackParameters:Array = null):*
		{
			return newLinkableChild(this, linkableChildClass, callback, useGroupedCallback);//, callbackParameters);
		}
		
		/**
		 * This function registers a linkable child of the plotter.
		 * @param child A sessioned object that is a non-spatial property of the plotter.
		 */
		protected function registerNonSpatialProperty(child:ILinkableObject, callback:Function = null):*
		{
			return registerLinkableChild(this, child, callback);
		}
		
		/**
		 * This function will cause the spatialCallbacks and plotter callbacks to trigger when the given sessioned properties run their callbacks.
		 * @param firstProperty A sessioned object that is a spatial property of the plotter.
		 * @param moreProperties More sessioned objects that are spatial properties of the plotter.
		 */
		protected function registerNonSpatialProperties(firstProperty:ILinkableObject, ...moreProperties):void
		{
			(moreProperties as Array).unshift(firstProperty);
			for each (firstProperty in moreProperties)
				registerNonSpatialProperty(firstProperty);
		}

		/**
		 * This function gets called when the SessionManager disposes of this sessioned object.
		 */
		public function dispose():void
		{
			returnPooledObjects();
		}
		
		protected const _spatialCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);

		/**
		 * This is an interface for adding callbacks that get called when any spatial properties of the plotter change.
		 * Spatial properties are those that affect the data bounds of visual elements.
		 */
		public function get spatialCallbacks():ICallbackInterface
		{
			return _spatialCallbacks;
		}

		/**
		 * This function can be used by classes that extend AbstractPlotter to control the results of the get keySet() function.
		 * Since all IAttributeColumns implement IKeySet, a column can be set as the source of an AbstractPlotter's keys.
		 * @param source An object that implements IKeySet (Note: IAttributeColumn implements this)
		 */
		protected function setKeySource(source:IKeySet):void
		{
			_filteredKeySet.setBaseKeySet(source);
		}
		
		/** 
		 * This variable is returned by get keySet().
		 */
		protected const _filteredKeySet:FilteredKeySet = newSpatialProperty(FilteredKeySet);
		
		/**
		 * @return An IKeySet interface to the record keys that can be passed to the drawRecord() and getDataBoundsFromRecordKey() functions.
		 */
		public function get keySet():IFilteredKeySet
		{
			return _filteredKeySet;
		}
		
		/**
		 * This function must be implemented by classes that extend AbstractPlotter.
		 * 
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 * @return An Array of Bounds2D objects that make up the bounds for the record.
		 */
		public /* abstract */ function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			return [];
		}
		
		protected static const recordsPerDraw:int = 200; // for use with the template drawPlot code
		
		/**
		 * This function must be defined with override by classes that extend AbstractPlotter.
		 * 
		 * Draws the graphics for a list of records onto a sprite.
		 * @param recordKeys The list of keys that identify which records should be used to generate the graphics.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// BEGIN template code for defining a drawPlot() function.
			//---------------------------------------------------------
			
			var graphics:Graphics = tempShape.graphics;
			var count:int = 0;
			graphics.clear();
			screenBounds.getRectangle(clipRectangle);
			clipRectangle.width++; // avoid clipping lines
			clipRectangle.height++; // avoid clipping lines
			for (var i:int = 0; i < recordKeys.length; i++)
			{
				var recordKey:IQualifiedKey = recordKeys[i] as IQualifiedKey;

				// project data coordinates to screen coordinates and draw graphics onto tempShape
				addRecordGraphicsToTempShape(recordKey, dataBounds, screenBounds, tempShape);
				
				// If the recordsPerDraw count has been reached, flush the tempShape "buffer" onto the destination BitmapData.
				if (++count > AbstractPlotter.recordsPerDraw)
				{
					destination.draw(tempShape, null, null, null, (clipDrawing == true) ? clipRectangle : null);
					graphics.clear();
					count = 0;
				}
			}

			// flush the tempShape buffer
			if (count > 0)
				destination.draw(tempShape, null, null, null, (clipDrawing == true) ? clipRectangle : null);
			
			//---------------------------------------------------------
			// END template code
		}
		protected const clipRectangle:Rectangle = new Rectangle();
		protected var clipDrawing:Boolean = true;
		protected const tempShape:Shape = new Shape(); // reusable temporary object
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			// to be implemented by an extending class
		}
		
		/**
		 * This function draws the background graphics for this plotter, if applicable.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		public /* abstract */ function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
		}

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @return A Bounds2D object specifying the background data bounds.
		 */
		public /* abstract */ function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds();
		}
	}
}

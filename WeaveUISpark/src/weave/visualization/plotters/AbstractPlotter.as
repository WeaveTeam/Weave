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
	import flash.display.Shape;
	import flash.geom.Rectangle;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
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
	public class AbstractPlotter implements IPlotter
	{
		/**
		 * @param columnToGetKeysFrom The column that the IKeySet object uses to get keys from.
		 */
		public function AbstractPlotter()
		{
//			var self:Object = this;
//			spatialCallbacks.addImmediateCallback(this, function():void{ debugTrace(self, 'spatialCallbacks', spatialCallbacks); });
//			getCallbackCollection(keySet).addImmediateCallback(this, function():void{ debugTrace(self,'keys',keySet.keys.length); });
		}
		
		/**
		 * This function creates a new registered linkable child of the plotter whose callbacks will also trigger the spatial callbacks.
		 * @return A new instance of the specified class that is registered as a spatial property.
		 */
		protected function newSpatialProperty(linkableChildClass:Class, callback:Function = null):*
		{
			var child:ILinkableObject = newLinkableChild(this, linkableChildClass, callback);
			
			var thisCC:ICallbackCollection = getCallbackCollection(this);
			var childCC:ICallbackCollection = getCallbackCollection(child);
			// instead of triggering parent callbacks, trigger spatialCallbacks which will in turn trigger parent callbacks.
			childCC.removeCallback(thisCC.triggerCallbacks);
			registerLinkableChild(spatialCallbacks, child);
			
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

			var thisCC:ICallbackCollection = getCallbackCollection(this);
			var childCC:ICallbackCollection = getCallbackCollection(child);
			// instead of triggering parent callbacks, trigger spatialCallbacks which will in turn trigger parent callbacks.
			childCC.removeCallback(thisCC.triggerCallbacks);
			registerLinkableChild(spatialCallbacks, child);
			
			return child;
		}
		
		/**
		 * This variable should not be set manually.  It cannot be made constant because we cannot guarantee that it will be initialized
		 * before other properties are initialized, which means it may be null when someone wants to call registerSpatialProperty().
		 */		
		private var _spatialCallbacks:ICallbackCollection = null;

		/**
		 * This is an interface for adding callbacks that get called when any spatial properties of the plotter change.
		 * Spatial properties are those that affect the data bounds of visual elements.
		 */
		public function get spatialCallbacks():ICallbackCollection
		{
			if (_spatialCallbacks == null)
				_spatialCallbacks = newLinkableChild(this, CallbackCollection);
			return _spatialCallbacks;
		}

		/**
		 * This will set up the keySet so it provides keys in sorted order based on the values in a list of columns.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param descendingFlags An Array of Boolean values to denote whether the corresponding columns should be used to sort descending or not.
		 */
		protected function setColumnKeySources(columns:Array, descendingFlags:Array = null):void
		{
			_filteredKeySet.setColumnKeySources(columns, descendingFlags);
		}
		
		/**
		 * This function sets the base IKeySet that is being filtered.
		 * @param newBaseKeySet A new IKeySet to use as the base for this FilteredKeySet.
		 */
		protected function setSingleKeySource(keySet:IKeySet):void
		{
			_filteredKeySet.setSingleKeySource(keySet);
		}
		
		/** 
		 * This variable is returned by get keySet().
		 */
		protected const _filteredKeySet:FilteredKeySet = newSpatialProperty(FilteredKeySet);
		
		/**
		 * @return An IKeySet interface to the record keys that can be passed to the drawRecord() and getDataBoundsFromRecordKey() functions.
		 */
		public function get filteredKeySet():IFilteredKeySet
		{
			return _filteredKeySet;
		}
		
		/**
		 * This function must be implemented by classes that extend AbstractPlotter.
		 * When you implement this function, you may use initBoundsArray() for convenience.
		 * 
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 * @return An Array of Bounds2D objects that make up the bounds for the record.
		 */
		public /* abstract */ function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			initBoundsArray(output, 0);
		}
		
		/**
		 * variables for template code
		 */		
		protected const clipRectangle:Rectangle = new Rectangle();
		protected var clipDrawing:Boolean = false;
		protected const tempShape:Shape = new Shape(); // reusable temporary object
		
		/**
		 * This function will perform one iteration of an asynchronous rendering task.
		 * This function will be called multiple times across several frames until its return value is 1.0.
		 * This function may be defined with override by classes that extend AbstractPlotter.
		 * @param task An object containing the rendering parameters.
		 * @return A number between 0 and 1 indicating the progress that has been made so far in the asynchronous rendering.
		 */
		public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			// this template will draw one record per iteration
			if (task.iteration < task.recordKeys.length)
			{
				//------------------------
				// draw one record
				var key:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
				tempShape.graphics.clear();
				addRecordGraphicsToTempShape(key, task.dataBounds, task.screenBounds, tempShape);
				if (clipDrawing)
				{
					// get clipRectangle
					task.screenBounds.getRectangle(clipRectangle);
					// increase width and height by 1 to avoid clipping rectangle borders drawn with vector graphics.
					clipRectangle.width++;
					clipRectangle.height++;
				}
				task.buffer.draw(tempShape, null, null, null, clipDrawing ? clipRectangle : null);
				//------------------------
				
				// report progress
				return task.iteration / task.recordKeys.length;
			}
			
			// report progress
			return 1; // avoids division by zero in case task.recordKeys.length == 0
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		protected /* abstract */ function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
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
		public /* abstract */ function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
		}
		
		/**
		 * This is a convenience function for use inside getDataBoundsFromRecordKey().
		 * @param output An output Array, which may already contain any number of IBounds2D objects.
		 * @param desiredLength The desired number of output IBounds2D objects to appear in the output Array.
		 * @return The first IBounds2D item in the Array, or null if desiredLength is zero.
		 */
		protected function initBoundsArray(output:Array, desiredLength:int = 1):IBounds2D
		{
			while (output.length < desiredLength)
				output.push(ObjectPool.borrowObject(Bounds2D));
			while (output.length > desiredLength)
				ObjectPool.returnObject(output.pop());
			for each (var bounds:IBounds2D in output)
				bounds.reset();
			return output[0] as IBounds2D;
		}
	}
}

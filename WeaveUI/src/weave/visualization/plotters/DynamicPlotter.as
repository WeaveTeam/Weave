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
	import flash.geom.Rectangle;
	
	import weave.Weave;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ICallbackInterface;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.api.unlinkSessionState;
	import weave.core.CallbackCollection;
	import weave.core.LinkableDynamicObject;
	import weave.core.SessionManager;
	import weave.data.KeySets.FilteredKeySet;
	import weave.primitives.Bounds2D;

	/**
	 * This is a wrapper for another IPlotter.
	 * 
	 * @author adufilie
	 */
	public class DynamicPlotter extends LinkableDynamicObject implements IPlotter
	{
		public function DynamicPlotter()
		{
			super(IPlotter);
			addImmediateCallback(this, handleInternalObjectChange);
			_spatialCallbacks.addImmediateCallback(this, handleSpatialCallbacks);
		}

		private var _internalPlotter:IPlotter = null; // The previous internal plotter
		
		/**
		 * This function gets called when the internal plotter changes.
		 */
		private function handleInternalObjectChange():void
		{
			// if a new plotter has been created, we need to link up the spatial callbacks and key column.
			var newPlotter:IPlotter = internalObject as IPlotter;
			if (_internalPlotter == newPlotter)
				return;

			if (_internalPlotter != null) // clean up links to old plotter
			{
				// if _prevPlotter is not null, it means it is no longer the internal plotter, so unlink from it
				_internalPlotter.spatialCallbacks.removeCallback(_spatialCallbacks.triggerCallbacks);
				// base key set should no longer be set to the key set of the old plotter
				_filteredKeySet.setBaseKeySet(null);
				// unlink the filters
				unlinkSessionState(_filteredKeySet.keyFilter, _internalPlotter.keySet.keyFilter);
			}

			_internalPlotter = newPlotter; // save pointer to new plotter
			
			if (_internalPlotter != null) // create links to new plotter
			{
				// if newPlotter is not null, it means a new one has been created (old one was already disposed of)
				_internalPlotter.spatialCallbacks.addImmediateCallback(this, _spatialCallbacks.triggerCallbacks, null, false, true); // trigger last
				// the base set of keys is going to be the internal plotter's keys
				_filteredKeySet.setBaseKeySet(_internalPlotter.keySet);
				// link the filters so the internal plotter filters its keys before generating graphics
				// give the internal plotter priority over the key filter if it has one, otherwise give the dynamic plotter priority
				if (_internalPlotter.keySet.keyFilter.internalObject != null)
					linkSessionState(_internalPlotter.keySet.keyFilter, _filteredKeySet.keyFilter);
				else
					linkSessionState(_filteredKeySet.keyFilter, _internalPlotter.keySet.keyFilter);
			}
			
			// when internal plotter was added or removed, run spatial callbacks
			_spatialCallbacks.triggerCallbacks();
		}
		
		/**
		 * This is the set of keys relevant to this IPlotter.
		 * @return The record keys that can be passed to the drawRecord() and getDataBoundsFromRecordKey() functions.
		 */
		public function get keySet():IFilteredKeySet
		{
			return _filteredKeySet;
		}

		private const _filteredKeySet:FilteredKeySet = newDisposableChild(this, FilteredKeySet); // to be returned by get keySet() when there is no internal plotter

		/**
		 * This CallbackCollection is defined in this class so any callbacks
		 * added to it will be transferred to any new plotter created internally.
		 */
		private const _spatialCallbacks:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		
		/**
		 * This is an interface for adding callbacks that get called when any spatial properties of the plotter change.
		 * Spatial properties are those that affect the data bounds of visual elements.
		 * Whenever these callbacks get called, data bounds values returned from getDataBoundsFromRecordKey() become invalid.
		 */
		public function get spatialCallbacks():ICallbackCollection
		{
			return _spatialCallbacks;
		}
		
		/**
		 * This function gets called when spatial callbacks trigger.
		 */		
		private function handleSpatialCallbacks():void
		{
			currentBackgroundDataBounds = null;
		}

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param recordKey The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			if (internalObject is IPlotter)
				return (internalObject as IPlotter).getDataBoundsFromRecordKey(recordKey);
			else
				return [];
		}
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey):Array
		{
			if (internalObject is IPlotterWithGeometries)
				return (internalObject as IPlotterWithGeometries).getGeometriesFromRecordKey(recordKey);
			else
				return [];
		}
		
		/**
		 * Draws the graphics for a record onto a sprite.
		 * @param recordKey The key of a data record.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (internalObject is IPlotter)
				(internalObject as IPlotter).drawPlot(recordKeys, dataBounds, screenBounds, destination);
		}
		
		/**
		 * This function draws the background graphics for this plotter, if applicable.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// test code
			if (Weave.properties.debugScreenBounds.value)
			{
				screenBounds.getRectangle(tempRect);
				destination.fillRect(tempRect, 0xCC000000 | (Math.random() * 0xFFFFFF));
				tempRect.inflate(-1, -1);
				destination.fillRect(tempRect, 0x00000000);
			}
			// end test code
			
			if (internalObject is IPlotter)
				(internalObject as IPlotter).drawBackground(dataBounds, screenBounds, destination);
		}

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		public function getBackgroundDataBounds():IBounds2D
		{
			if (internalObject is IPlotter)
			{
				if (currentBackgroundDataBounds == null)
					currentBackgroundDataBounds = (internalObject as IPlotter).getBackgroundDataBounds();
				return currentBackgroundDataBounds;
			}
			else
				return undefinedBounds; // if no internal plotter, return an undefined data bounds
		}
		
		private var currentBackgroundDataBounds:IBounds2D = null;
		private const undefinedBounds:IBounds2D = new Bounds2D();
		
		private const tempRect:Rectangle = new Rectangle();
	}
}

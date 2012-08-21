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

package weave.visualization.layers
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.primitives.Bounds2D;
	import weave.primitives.ZoomBounds;

	/**
	 * Callbacks are triggered when the rendering task completes, or the plotter becomes busy during rendering.
	 * Busy status should be checked when callbacks trigger.
	 * 
	 * @author adufilie
	 */
	public class PlotTask implements IPlotTask, ILinkableObject, IDisposableObject
	{
		public function PlotTask(zoomBounds:ZoomBounds, plotter:IPlotter, keyFilter:IDynamicKeyFilter)
		{
			_plotter = plotter;
			_keyFilter = keyFilter;
			_zoomBounds = zoomBounds;
			
			getCallbackCollection(_keyFilter).addImmediateCallback(this, asyncStart);
			getCallbackCollection(_plotter).addImmediateCallback(this, asyncStart);
		}
		
		public function dispose():void
		{
			_zoomBounds = null;
			_plotter = null;
			disposeObjects(_bitmap.bitmapData);
		}
		
		private var _bitmap:Bitmap = new Bitmap();
		private var _plotter:IPlotter = null;
		private var _keyFilter:IDynamicKeyFilter = null;
		private var _zoomBounds:ZoomBounds;
		private var _tempDataBounds:Bounds2D = new Bounds2D();
		private var _tempScreenBounds:Bounds2D = new Bounds2D();
		private var _iteration:uint = 0;
		private var _recordKeys:Array;
		private var _asyncState:Object;
		private var _pendingRecordKeys:Array;
		private var _iPendingRecordKey:uint;
		
		/*
		
		todo:
		add a way to disable the task
		
		*/
		
		private function asyncStart():void
		{
			_iteration = 0;
			WeaveAPI.StageUtils.startTask(this, asyncIterate, WeaveAPI.TASK_PRIORITY_RENDERING, asyncComplete);
		}
		
		private function asyncIterate():Number
		{
			// if the plotter is busy, stop immediately
			if (WeaveAPI.SessionManager.linkableObjectIsBusy(_plotter))
				return 1;

			// if keys change, restart
			if (detectLinkableObjectChange(this, _plotter, _keyFilter))
			{
				_iPendingRecordKey = 0;
				_pendingRecordKeys = _plotter.keySet.keys;
				_recordKeys = [];
			}
			
			// if keys aren't ready yet, prepare keys
			if (_pendingRecordKeys)
			{
				if (_iPendingRecordKey < _pendingRecordKeys.length)
				{
					// next key iteration - add key if included in filter
					var key:IQualifiedKey = _pendingRecordKeys[_iPendingRecordKey] as IQualifiedKey;
					if (_keyFilter.getInternalKeyFilter().containsKey(key))
						_recordKeys.push(key);
					
					// prepare for next iteration
					_iPendingRecordKey++;
					
					// not done yet
					return 0;
				}
				// done with keys
				_pendingRecordKeys = null;
			}
			
			// next draw iteration
			var progress:Number = _plotter.drawPlotAsyncIteration(this);
			
			// prepare for next iteration
			_iteration++;
			
			return progress;
		}
		
		private function asyncComplete():void
		{
			// if the plotter is busy, the graphics aren't ready, so don't trigger callbacks
			if (!WeaveAPI.SessionManager.linkableObjectIsBusy(_plotter))
				getCallbackCollection(this).triggerCallbacks();
		}
		
		
		/***************************
		 **  IPlotTask interface  **
		 ***************************/
		
		// this is the off-screen buffer
		public function get destination():BitmapData
		{
			return _bitmap.bitmapData;
		}
		
		// specifies the range of data to be rendered
		public function get dataBounds():IBounds2D
		{
			_zoomBounds.getDataBounds(_tempDataBounds);
			return _tempDataBounds;
		}
		
		// specifies the pixel range where the graphics should be rendered
		public function get screenBounds():IBounds2D
		{
			_zoomBounds.getScreenBounds(_tempScreenBounds);
			return _tempScreenBounds;
		}
		
		// these are the IQualifiedKey objects identifying which records should be rendered
		public function get recordKeys():Array
		{
			return _recordKeys;
		}
		
		// This counter is incremented after each iteration.  When the task parameters change, this counter is reset to zero.
		public function get iteration():uint
		{
			if (detectLinkableObjectChange(this, _zoomBounds, _plotter))
				_iteration = 0;
			
			return _iteration;
		}
		
		// can be used to optionally store additional state variables for resuming an asynchronous task where it previously left off.
		// setting this will not reset the iteration counter.
		public function get asyncState():Object
		{
			return _asyncState;
		}
		public function set asyncState(value:Object):void
		{
			_asyncState = value;
		}
	}
}

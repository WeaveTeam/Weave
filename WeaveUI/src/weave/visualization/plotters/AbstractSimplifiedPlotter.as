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
	import flash.utils.getQualifiedClassName;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.core.ClassUtils;
	import weave.core.SessionManager;
	import weave.primitives.Bounds2D;
	
	/**
	 * The purpose of this class is to simplify the session state of an IPlotter object.
	 * For example, a Histogram or a Bar Chart can be created by simplifying a RectanglePlotter,
	 * hiding the hard-coded part of the session state and making only a few sessioned properties public.
	 * 
	 * @author adufilie
	 */
	public class AbstractSimplifiedPlotter extends AbstractPlotter
	{
		/**
		 * The constructor will set the protected internalPlotter variable to a new instance of the specified class.
		 * @param internalPlotterClass This parameter is required.  This shouold be a class that implements IPlotter.
		 */
		public function AbstractSimplifiedPlotter(internalPlotterClass:Class)
		{
			super();
			init(internalPlotterClass);
		}
		
		/**
		 * This will initialize the internal plotter and link it with the AbstractSimplifiedPlotter.
		 */
		private function init(plotterClass:Class):void
		{
			var plotterClassName:String = getQualifiedClassName(plotterClass);
			if (!ClassUtils.classImplements(plotterClassName, _IPlotterQName))
				throw new Error("AbstractSimplifiedPlotter: Class does not implement IPlotter: " + plotterClassName);
			
			_internalPlotter = newLinkableChild(this, plotterClass); // create the internal plotter
			_internalPlotter.spatialCallbacks.addImmediateCallback(this, spatialCallbacks.triggerCallbacks);
			// the base key set is the key set of the internal plotter
			_filteredKeySet.setBaseKeySet(_internalPlotter.keySet);
			// link the filters so the internal plotter filters its keys before generating graphics
			linkSessionState(_filteredKeySet.keyFilter, _internalPlotter.keySet.keyFilter);
		}

		/**
		 * This is the internal plotter that is being simplified by a class that extends AbstractSimplifiedPlotter.
		 */
		protected function get internalPlotter():IPlotter
		{
			return _internalPlotter;
		}
		private var _internalPlotter:IPlotter; // private variable for the get internalPlotter() function.

		private static const _IPlotterQName:String = getQualifiedClassName(IPlotter); // qualified class name of IPlotter

		/**
		 * Draws the graphics onto BitmapData.
		 */
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			internalPlotter.drawPlot(recordKeys, dataBounds, screenBounds, destination);
		}

		/**
		 * The data bounds for a glyph has width and height equal to zero.
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @return An Array of Bounds2D objects that specify the data bounds of the record.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			return internalPlotter.getDataBoundsFromRecordKey(recordKey);
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @return A Bounds2D object specifying the background data bounds.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			return internalPlotter.getBackgroundDataBounds();
		}
	}
}


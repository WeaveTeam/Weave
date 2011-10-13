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
	
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotter;
	import weave.api.unlinkSessionState;
	import weave.core.LinkableHashMap;
	import weave.primitives.Bounds2D;
	
	/**
	 * A CompoundPlotter combines multiple plotters into one.
	 * For example, a BarChartPlotter and a CircleGlyphPlotter can be combined in a
	 * compound plotter that generates, given a record key, a bar with a circle on top.
	 * 
	 * CompoundPlotter is only recommended when there is a one-to-one mapping of record keys to graphics objects.
	 * A histogram is not recommended to be included in a CompoundPlotter because multiple record keys map to the same graphics object.
	 * 
	 * @author adufilie
	 */
	public class CompoundPlotter extends AbstractPlotter
	{
		/**
		 * The constructor will set the protected internalPlotter variable to a new instance of the specified class.
		 * @param internalPlotterClass This parameter is required.  This shouold be a class that implements IPlotter.
		 */
		public function CompoundPlotter()
		{
			super();
			plotters.childListCallbacks.addImmediateCallback(this, handlePlottersListChange);
		}
		
		/**
		 * This is an ordered list of plotters to combine.
		 */
		public const plotters:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IPlotter));
		
		private function handlePlottersListChange():void
		{
			var oldPlotter:IPlotter = plotters.childListCallbacks.lastObjectRemoved as IPlotter;
			if (oldPlotter)
			{
				unlinkSessionState(keySet.keyFilter, oldPlotter.keySet.keyFilter);
				oldPlotter.spatialCallbacks.removeCallback(spatialCallbacks.triggerCallbacks);
			}
			var newPlotter:IPlotter = plotters.childListCallbacks.lastObjectAdded as IPlotter;
			if (newPlotter)
			{
				//TODO: allow multiple key sets to be linked (using a union of key sets)
				
				linkSessionState(keySet.keyFilter, newPlotter.keySet.keyFilter);
				newPlotter.spatialCallbacks.addImmediateCallback(this, spatialCallbacks.triggerCallbacks, null, false, true); // trigger last
			}
			// temporary solution -- just use the first plotter as the key source
			var _plotters:Array = plotters.getObjects(IPlotter);
			if (_plotters.length > 0)
				setKeySource((_plotters[0] as IPlotter).keySet);
			else
				setKeySource(null);
		}
		
		/**
		 * Draws the graphics onto BitmapData.
		 */
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var _plotters:Array = plotters.getObjects();
			for (var keyIndex:int = 0; keyIndex < recordKeys.length; keyIndex++)
			{
				var singleRecord:Array = [recordKeys[keyIndex]];
				// the graphics for a record is the combined graphics of all the individual plotters
				for (var plotterIndex:int = 0; plotterIndex < _plotters.length; plotterIndex++)
				{
					var _plotter:IPlotter = _plotters[plotterIndex] as IPlotter;
					_plotter.drawPlot(singleRecord, dataBounds, screenBounds, destination);
				}
			}
		}

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			// include all the dataBounds from all the individual plotters
			var results:Array = [];
			for each (var plotter:IPlotter in plotters.getObjects())
				for each (var bounds:IBounds2D in plotter.getDataBoundsFromRecordKey(recordKey));
					results.push(bounds);
			return results;
		}

		private const tempBounds:IBounds2D = new Bounds2D();
	}
}


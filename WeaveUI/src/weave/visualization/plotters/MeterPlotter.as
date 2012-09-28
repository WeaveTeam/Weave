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
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IColumnStatistics;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;
	
	/**
	 * This abstract class contains functionality common to any "meter tool" such as the thermometer and the gauge.
	 * This functionality includes the ability to select which input drives the single value shown by the tool plotter.
	 * 
	 * @author Curran Kelleher
	 */
	public class MeterPlotter extends AbstractPlotter
	{
		//These constants are possible values of inputMode.
		public const PROBE_MODE:Number = 0;
		public const COLUMN_AVERAGE_MODE:Number = 1;
		
		//the sessioned number controlling the input mode
		private const inputMode:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		//the column whose value drives this meter 
		public const meterColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		protected const meterColumnStats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(meterColumn);
		
//		private var mode:Number = PROBE_MODE;
		public function MeterPlotter()
		{
			//this line causes only the currently probed records to be drawn.			
			setSingleKeySource(Weave.defaultProbeKeySet);
		}
	}
}



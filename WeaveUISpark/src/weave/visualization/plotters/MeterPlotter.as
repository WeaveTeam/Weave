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

package weave.visualization.plotters
{
	import weave.Weave;
	import weave.api.data.IColumnStatistics;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ISelectableAttributes;
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
		protected const meterColumnStats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(meterColumn));
		
//		private var mode:Number = PROBE_MODE;
		public function MeterPlotter()
		{
			//this line causes only the currently probed records to be drawn.			
			setSingleKeySource(Weave.defaultProbeKeySet);
		}
	}
}



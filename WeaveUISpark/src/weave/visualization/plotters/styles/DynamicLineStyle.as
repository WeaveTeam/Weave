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

package weave.visualization.plotters.styles
{
	import flash.display.Graphics;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.ui.ILineStyle;
	import weave.core.LinkableDynamicObject;

	/**
	 * DynamicLineStyle
	 * 
	 * @author adufilie
	 */
	[ExcludeClass] public class DynamicLineStyle extends LinkableDynamicObject implements ILineStyle
	{
		public function DynamicLineStyle(defaultLineStyleClass:Class = null)
		{
			super(ILineStyle);
			if (defaultLineStyleClass != null)
				requestLocalObject(defaultLineStyleClass, false);
		}

		/**
		 * This will set the line style on the specified Graphics object using the properties saved in this class.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 */
		public function beginLineStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			if (internalObject is ILineStyle)
				(internalObject as ILineStyle).beginLineStyle(recordKey, target);
			else
				target.lineStyle(0, 0, 0); // no line
		}
	}
}

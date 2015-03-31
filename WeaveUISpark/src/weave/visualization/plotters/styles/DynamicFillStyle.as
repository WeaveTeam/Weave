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
	import weave.api.ui.IFillStyle;
	import weave.core.LinkableDynamicObject;

	/**
	 * DynamicFillStyle
	 * 
	 * @author adufilie
	 */
	[ExcludeClass] public class DynamicFillStyle extends LinkableDynamicObject implements IFillStyle
	{
		public function DynamicFillStyle(defaultFillStyleClass:Class = null)
		{
			super(IFillStyle);
			if (defaultFillStyleClass != null)
				requestLocalObject(defaultFillStyleClass, false);
		}

		/**
		 * This function sets the fill on a Graphics object using the saved fill properties.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 */
		public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):Boolean
		{
			if (internalObject is IFillStyle)
			{
				return (internalObject as IFillStyle).beginFillStyle(recordKey, target);
			}
			else
			{
				target.endFill();
				return false;
			}
		}
	}
}

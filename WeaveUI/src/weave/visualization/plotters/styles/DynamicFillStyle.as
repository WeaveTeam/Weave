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
	public class DynamicFillStyle extends LinkableDynamicObject implements IFillStyle
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
		public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			if (internalObject is IFillStyle)
				(internalObject as IFillStyle).beginFillStyle(recordKey, target);
			else
				target.endFill();
		}
	}
}

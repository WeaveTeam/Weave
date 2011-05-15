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

package org.oicweave.visualization.plotters.styles
{
	import flash.display.Graphics;
	
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.ui.ILineStyle;
	import org.oicweave.core.LinkableDynamicObject;

	/**
	 * DynamicLineStyle
	 * 
	 * @author adufilie
	 */
	public class DynamicLineStyle extends LinkableDynamicObject implements ILineStyle
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

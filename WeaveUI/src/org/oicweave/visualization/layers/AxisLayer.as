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

package org.oicweave.visualization.layers
{
	import flash.display.Bitmap;
	import flash.display.PixelSnapping;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	import mx.utils.NameUtil;
	
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.SessionManager;
	import org.oicweave.api.core.ILinkableObject;
	import org.oicweave.data.KeySets.FilteredKeySet;
	import org.oicweave.api.data.IDynamicKeyFilter;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.utils.DebugUtils;
	import org.oicweave.utils.PlotterUtils;
	import org.oicweave.utils.SpatialIndex;
	import org.oicweave.visualization.plotters.AxisPlotter;
	import org.oicweave.visualization.plotters.DynamicPlotter;
	import org.oicweave.api.ui.IPlotter;
	import org.oicweave.visualization.plotters.SimpleAxisPlotter;
	
	/**
	 * 
	 *  Axislayer
	 * 
	 * 
	 * @author skolman
	 */
	public class AxisLayer extends PlotLayer
	{
		public function AxisLayer()
		{
			_plotter = getDynamicPlotter().requestLocalObject(SimpleAxisPlotter, true);
		}
		
		private var _plotter:SimpleAxisPlotter = null;
		
		public function get axisPlotter():SimpleAxisPlotter
		{
			return _plotter;
		}
		
		
	}
}

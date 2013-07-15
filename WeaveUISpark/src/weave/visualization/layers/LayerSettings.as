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
	import weave.Weave;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.KeySets.DynamicKeyFilter;
	import weave.primitives.ZoomBounds;
	
	/**
	 * Settings for a single plot layer.
	 * 
	 * @author adufilie
	 */
	public class LayerSettings implements ILinkableObject
	{
		public function LayerSettings()
		{
//			subsetFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			selectionFilter.globalName = Weave.DEFAULT_SELECTION_KEYSET;
			probeFilter.globalName = Weave.DEFAULT_PROBE_KEYSET;
		}
		
		/**
		 * When this is false, nothing will be drawn.
		 */		
		public const visible:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * When this is false, selection and probing are disabled.
		 */		
		public const selectable:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * Sets the minimum scale at which the layer should be rendered. Scale is defined by pixels per data unit.
		 */
		public const minVisibleScale:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, verifyVisibleScaleValue));
		
		/**
		 * Sets the maximum scale at which the layer should be rendered. Scale is defined by pixels per data unit.
		 */
		public const maxVisibleScale:LinkableNumber = registerLinkableChild(this, new LinkableNumber(Infinity, verifyVisibleScaleValue));
		
		public function isZoomBoundsWithinVisibleScale(zoomBounds:ZoomBounds):Boolean
		{
			var min:Number = StandardLib.roundSignificant(minVisibleScale.value);
			var max:Number = StandardLib.roundSignificant(maxVisibleScale.value);
			var xScale:Number = StandardLib.roundSignificant(zoomBounds.getXScale());
			var yScale:Number = StandardLib.roundSignificant(zoomBounds.getYScale());
			return min <= xScale && xScale <= max
				&& min <= yScale && yScale <= max;
		}
		
		/**
		 * @private
		 */		
		private function verifyVisibleScaleValue(value:Number):Boolean
		{
			return value >= 0;
		}
		
		// temporary solution
		// TODO: use VisToolGroup
//		public const subsetFilter:IDynamicKeyFilter = newDisposableChild(this, DynamicKeyFilter);
		public const selectionFilter:IDynamicKeyFilter = newDisposableChild(this, DynamicKeyFilter);
		public const probeFilter:IDynamicKeyFilter = newDisposableChild(this, DynamicKeyFilter);
		
		// hacks
		public var hack_includeMissingRecordBounds:Boolean = false; // hack to include records with undefined bounds
		public var hack_useTextBitmapFilters:Boolean = false; // hack to use text bitmap filters (for labels, legends)
		
		// backwards compatibility
		[Deprecated] public function set useTextBitmapFilters(value:Boolean):void { hack_useTextBitmapFilters = value; }
		[Deprecated] public function set layerIsSelectable(value:Boolean):void { selectable.value = value; }
		[Deprecated] public function set layerIsVisible(value:Boolean):void { visible.value = value; }
	}
}

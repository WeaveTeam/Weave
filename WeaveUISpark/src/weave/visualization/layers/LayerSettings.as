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
//			subsetFilter.targetPath = [Weave.DEFAULT_SUBSET_KEYFILTER];
			selectionFilter.targetPath = [Weave.DEFAULT_SELECTION_KEYSET];
			probeFilter.targetPath = [Weave.DEFAULT_PROBE_KEYSET];
		}
		
		/**
		 * When this is false, nothing will be drawn.
		 */		
		public const visible:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * Alpha value (opacity) for rendering the layer.
		 */
		public const alpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, isFinite));
		
		/**
		 * When this is false, selection and probing are disabled.
		 */		
		public const selectable:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * Specifies whether selection/probe should be rendered anyway, even if selectable is set to false.
		 */
		public const alwaysRenderSelection:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
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

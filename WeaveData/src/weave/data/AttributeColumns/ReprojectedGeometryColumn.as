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

package weave.data.AttributeColumns
{
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.ui.IObjectWithDescription;
	import weave.core.CallbackCollection;
	import weave.core.LinkableString;
	import weave.core.LinkableWatcher;
	import weave.utils.ColumnUtils;

	/**
	 * This column provides reprojected geometries for an internal geometry column.
	 * 
	 * @author adufilie
	 */
	public class ReprojectedGeometryColumn extends ExtendedDynamicColumn implements IObjectWithDescription
	{
		public function ReprojectedGeometryColumn()
		{
			super();
			// force the internal column to always be a ReferencedColumn
			addImmediateCallback(this, updateReprojectedColumn);
		}
		
		public function getDescription():String
		{
			var title:String = internalDynamicColumn.getMetadata(ColumnMetadata.TITLE);
			var srcproj:String = internalDynamicColumn.getMetadata(ColumnMetadata.PROJECTION);
			var destproj:String = this.getMetadata(ColumnMetadata.PROJECTION);
			if (destproj && srcproj != destproj)
				return lang('{0} ({1} -> {2})', title, srcproj || '?', destproj);
			else if (srcproj)
				return lang('{0} ({1})', title, srcproj);
			return title;
		}
		
		/**
		 * These callbacks are triggered when the list of keys or bounding boxes change.
		 */		
		public const boundingBoxCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);
		private const boundingBoxCallbacksTriggerWatcher:LinkableWatcher = newLinkableChild(boundingBoxCallbacks, LinkableWatcher);
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.PROJECTION)
			{
				var srs:String = projectionSRS.value;
				if (srs)
					return srs;
			}
			
			return super.getMetadata(propertyName);
		}
		
		override public function getInternalColumn():IAttributeColumn
		{
			return reprojectedColumnWatcher.target as IAttributeColumn;
		}
		
		/**
		 * This is the SRS code of the destination projection when reprojecting geometries from the internal column.
		 */		
		public const projectionSRS:LinkableString = newLinkableChild(this, LinkableString);
		
		/**
		 * This function updates the private _reprojectedColumn variable.
		 */		
		private function updateReprojectedColumn():void
		{
			var column:IAttributeColumn = ColumnUtils.hack_findNonWrapperColumn(super.getInternalColumn());
			var newColumn:IAttributeColumn = WeaveAPI.ProjectionManager.getProjectedGeometryColumn(column, projectionSRS.value);
			
			reprojectedColumnWatcher.target = _reprojectedColumn = newColumn;
		}
		
		private var _reprojectedColumn:IAttributeColumn;
		private const reprojectedColumnWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, handleReprojectedColumnChange);
		
		private function handleReprojectedColumnChange(cleanup:Boolean = false):void
		{
			// if _unprojectedColumn is not null, it means there is no reprojection to do.
			var _unprojectedColumn:StreamedGeometryColumn = ColumnUtils.hack_findNonWrapperColumn(_reprojectedColumn) as StreamedGeometryColumn;
			
			// get the callback target that should trigger boundingBoxCallbacks
			var newTarget:ILinkableObject = _unprojectedColumn ? _unprojectedColumn.boundingBoxCallbacks : _reprojectedColumn;
			
			boundingBoxCallbacksTriggerWatcher.target = newTarget;
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_reprojectedColumn)
				return _reprojectedColumn.getValueFromKey(key, dataType);
			
			return super.getValueFromKey(key, dataType);
		}
	}
}

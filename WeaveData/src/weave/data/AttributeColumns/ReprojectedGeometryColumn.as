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

package weave.data.AttributeColumns
{
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.core.weave_internal;
	import weave.api.data.AttributeColumnMetadata;

	use namespace weave_internal;
	
	/**
	 * This column provides reprojected geometries for an internal geometry column.
	 * 
	 * @author adufilie
	 */
	public class ReprojectedGeometryColumn extends ExtendedDynamicColumn
	{
		public function ReprojectedGeometryColumn()
		{
			// force the internal column to always be a ReferencedColumn
			internalDynamicColumn.requestLocalObject(ReferencedColumn, true);
			addImmediateCallback(this, updateReprojectedColumn);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == AttributeColumnMetadata.PROJECTION)
			{
				var srs:String = projectionSRS.value;
				if (srs != null && srs != '')
					return srs;
			}
			
			return super.getMetadata(propertyName);
		}
		
		override public function get internalColumn():IAttributeColumn
		{
			return _reprojectedColumn;
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
			var ref:IColumnReference = (super.internalColumn as ReferencedColumn).internalColumnReference;
			var newColumn:IAttributeColumn = WeaveAPI.ProjectionManager.getProjectedGeometryColumn(ref, projectionSRS.value);
			
			// if the column didn't change, do nothing
			if (_reprojectedColumn == newColumn)
				return;
			
			if (_reprojectedColumn)
				_reprojectedColumn.removeCallback(triggerCallbacks);
			
			_reprojectedColumn = newColumn;
			
			if (_reprojectedColumn)
				_reprojectedColumn.addImmediateCallback(this, triggerCallbacks, null, false, true); // parent-child relationship
		}
		
		private var _reprojectedColumn:IAttributeColumn = null;
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_reprojectedColumn)
				return _reprojectedColumn.getValueFromKey(key, dataType);
			
			return super.getValueFromKey(key, dataType);
		}
	}
}

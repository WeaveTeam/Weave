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

package weavejs.data.source
{
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IColumnReference;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.util.StandardLib;
	
	internal class GeoJSONDataSourceNode implements IWeaveTreeNode, IColumnReference
	{
		private var idFields:Array;
		private var source:IDataSource;
		private var metadata:Object;
		private var children:Array;
		
		public function GeoJSONDataSourceNode(source:IDataSource, metadata:Object, children:Array = null, idFields:Array = null)
		{
			this.source = source;
			this.metadata = metadata || {};
			this.children = children;
			this.idFields = idFields;
		}
		public function equals(other:IWeaveTreeNode):Boolean
		{
			var that:GeoJSONDataSourceNode = other as GeoJSONDataSourceNode;
			if (that && this.source == that.source && StandardLib.compare(this.idFields, that.idFields) == 0)
			{
				if (idFields && idFields.length)
				{
					// check only specified fields
					for each (var field:String in idFields)
					if (this.metadata[field] != that.metadata[field])
						return false;
					return true;
				}
				// check all fields
				return StandardLib.compare(this.metadata, that.metadata) == 0;
			}
			return false;
		}
		public function getLabel():String
		{
			return metadata[ColumnMetadata.TITLE];
		}
		public function isBranch():Boolean
		{
			return children != null;
		}
		public function hasChildBranches():Boolean
		{
			return false;
		}
		public function getChildren():Array
		{
			return children;
		}
		
		public function getDataSource():IDataSource
		{
			return source;
		}
		public function getColumnMetadata():Object
		{
			return children ? null : metadata;
		}
	}
}

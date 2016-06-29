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

package weavejs.data.column
{
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnWrapper;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableWatcher;
	import weavejs.util.ArrayUtils;

	/**
	 * This class is a proxy (a wrapper) for another attribute column.
	 * 
	 * @author adufilie
	 */
	public class ProxyColumn extends AbstractAttributeColumn implements IColumnWrapper
	{
		public function ProxyColumn(metadata:Object = null)
		{
			super(metadata);
		}
		
		private const watcher:LinkableWatcher = Weave.linkableChild(this, new LinkableWatcher(IAttributeColumn));
		
		/**
		 * @return the keys associated with this column.
		 */
		override public function get keys():Array
		{
			var column:IAttributeColumn = watcher.target as IAttributeColumn;
			return column ? column.keys : [];
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			var column:IAttributeColumn = watcher.target as IAttributeColumn;
			return column ? column.containsKey(key) : false;
		}

		/**
		 * This function updates the proxy metadata.
		 * @param metadata New metadata for the proxy.
		 */
		override public function setMetadata(metadata:Object):void
		{
			_metadata = copyValues(metadata);
			triggerCallbacks();
		}

		/**
		 * The metadata specified by ProxyColumn will override the metadata of the internal column.
		 * First, this function checks thet ProxyColumn metadata.
		 * If the value is null, it checks the metadata of the internal column.
		 * @param propertyName The name of a metadata property to get.
		 * @return The metadata value of the ProxyColumn or the internal column, ProxyColumn metadata takes precendence.
		 */
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName === ColumnMetadata.TITLE && _overrideTitle)
				return _overrideTitle;
			
			var column:IAttributeColumn = watcher.target as IAttributeColumn;
			var overrideValue:String = super.getMetadata(propertyName);
			if (overrideValue == null && column != null)
				return column.getMetadata(propertyName);
			return overrideValue;
		}
		
		public function getProxyMetadata():Object
		{
			return copyValues(_metadata);
		}
		
		override public function getMetadataPropertyNames():Array
		{
			var column:IAttributeColumn = watcher.target as IAttributeColumn;
			if (column)
				return ArrayUtils.union(super.getMetadataPropertyNames(), column.getMetadataPropertyNames());
			return super.getMetadataPropertyNames();
		}
		
		/**
		 * internalAttributeColumn
		 * This is the IAttributeColumn object contained in this ProxyColumn.
		 */
		public function getInternalColumn():IAttributeColumn
		{
			return watcher.target as IAttributeColumn;
		}
		public function setInternalColumn(newColumn:IAttributeColumn):void
		{
			_overrideTitle = null;
			watcher.target = newColumn;
		}
		
		/**
		 * The functions below serve as wrappers for matching function calls on the internalAttributeColumn.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var column:IAttributeColumn = watcher.target as IAttributeColumn;
			if (column)
				return column.getValueFromKey(key, dataType);
			return undefined;
		}

		override public function dispose():void
		{
			super.dispose();
			_metadata = null;
		}
		
		private var _overrideTitle:String;
		
		/**
		 * Call this function when the ProxyColumn should indicate that the requested data is unavailable.
		 * @param message The message to display in the title of the ProxyColumn.
		 */
		public function dataUnavailable(message:String = null):void
		{
			delayCallbacks();
			setInternalColumn(null);
			if (message)
			{
				_overrideTitle = message;
			}
			else
			{
				var title:String = getMetadata(ColumnMetadata.TITLE);
				if (title)
					_overrideTitle = Weave.lang('(Data unavailable: {0})', title);
				else
					_overrideTitle = Weave.lang(DATA_UNAVAILABLE);
			}
			triggerCallbacks();
			resumeCallbacks();
		}
		
		private static const DATA_UNAVAILABLE:String = '(Data unavailable)';
	}
}

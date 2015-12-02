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

package weavejs.data.columns
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnWrapper;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.SessionManager;
	import weavejs.utils.ArrayUtils;

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
		
		/**
		 * @return the keys associated with this column.
		 */
		override public function get keys():Array
		{
			var column:IAttributeColumn = internalNonProxyColumn;
			return column ? column.keys : [];
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _internalColumn && _internalColumn.containsKey(key);
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
			
			var overrideValue:String = super.getMetadata(propertyName);
			if (overrideValue == null && _internalColumn != null)
				return _internalColumn.getMetadata(propertyName);
			return overrideValue;
		}
		
		public function getProxyMetadata():Object
		{
			return copyValues(_metadata);
		}
		
		override public function getMetadataPropertyNames():Array
		{
			if (_internalColumn)
				return ArrayUtils.union(super.getMetadataPropertyNames(), _internalColumn.getMetadataPropertyNames());
			return super.getMetadataPropertyNames();
		}
		
		/**
		 * internalNonProxyColumn
		 * As long as internalAttributeColumn is a ProxyColumn, this function will
		 * keep traversing internalAttributeColumn until it reaches an IAttributeColumn that
		 * is not a ProxyColumn.
		 * @return An attribute column that is not a ProxyColumn, or null.
		 */
		public function get internalNonProxyColumn():IAttributeColumn
		{
			var column:IAttributeColumn = _internalColumn;
			while (column is ProxyColumn)
				column = (column as ProxyColumn)._internalColumn;
			return column;
		}
		
		/**
		 * internalAttributeColumn
		 * This is the IAttributeColumn object contained in this ProxyColumn.
		 */
		private var _internalColumn:IAttributeColumn = null;
		public function getInternalColumn():IAttributeColumn
		{
			return _internalColumn;
		}
		public function setInternalColumn(newColumn:IAttributeColumn):void
		{
			_overrideTitle = null;
			
			if (newColumn == this)
			{
				trace("WARNING! Attempted to set ProxyColumn.internalAttributeColumn to self: " + this);
				return;
			}
			
			if (_internalColumn == newColumn)
				return;

			// clean up ties to previous column
			if (_internalColumn != null)
				(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _internalColumn);

			// save pointer to new column
			_internalColumn = newColumn;
			
			// initialize for new column
			if (_internalColumn != null)
				Weave.linkableChild(this, _internalColumn);

			triggerCallbacks();
		}
		
		/**
		 * The functions below serve as wrappers for matching function calls on the internalAttributeColumn.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_internalColumn)
				return _internalColumn.getValueFromKey(key, dataType);
			return undefined;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			_metadata = null;
			setInternalColumn(null); // this will remove the callback that was added to the internal column
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
					_overrideTitle = DATA_UNAVAILABLE;
			}
			triggerCallbacks();
			resumeCallbacks();
		}
		
		public static const DATA_UNAVAILABLE:String = Weave.lang('(Data unavailable)');
	}
}

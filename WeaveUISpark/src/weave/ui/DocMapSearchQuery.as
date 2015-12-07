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

package weave.ui
{
	import flash.display.BitmapData;
	
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	
	import weave.Weave;
	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkablePromise;
	import weave.core.LinkableString;
	import weave.core.LinkableWatcher;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.DataSources.DocumentMapDataSource;
	import weave.data.KeySets.FilteredKeySet;
	import weave.data.KeySets.KeySet;
	import weave.utils.WeavePromise;
	
	public class DocMapSearchQuery implements ILinkableObject
	{
		public function DocMapSearchQuery()
		{
			promise.depend(queryString, collectionName, dataSourceName, searchResult);
			filteredKeys.setSingleKeySource(_keys);
			filteredKeys.keyFilter.targetPath = [Weave.DEFAULT_SUBSET_KEYFILTER];
		}
		
		private const searchResult:ProxyColumn = newLinkableChild(this, ProxyColumn);
		private const promise:LinkablePromise = registerLinkableChild(this, new LinkablePromise(makePromise, describePromise), handlePromise);
		private function makePromise():WeavePromise
		{
			var ds:DocumentMapDataSource = getDataSource();
			if (ds)
			{
				var meta:Object = ds.getColumnMetadata(collectionName.value, DocumentMapDataSource.TABLE_DOC_SEARCH, queryString.value);
				searchResult.setInternalColumn(WeaveAPI.AttributeColumnCache.getColumn(ds, meta));
			}
			return null;
		}
		private function describePromise():String
		{
			return lang("Performing query: {0}", queryString.value);
		}
		private function handlePromise():void
		{
			_keys.replaceKeys(searchResult.keys);
			if (promise.error)
			{
				var e:* = promise.error;
				while (e is Fault && (e as Fault).content is FaultEvent)
					e = (e as Fault).content;
				reportError(e);
			}
		}
		
		public function getLabel():String
		{
			return queryString.value;
		}
		
		public const queryString:LinkableString = newLinkableChild(this, LinkableString);
		public const x:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const y:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const dataSourceName:LinkableString = newLinkableChild(this, LinkableString);
		public const collectionName:LinkableString = newLinkableChild(this, LinkableString);
		public const showAsList:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const thumbnailSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(64));
		public const height:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const width:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const filteredKeys:FilteredKeySet = newLinkableChild(this, FilteredKeySet);
		
		private const _dataSourceWatcher:LinkableWatcher = registerLinkableChild(this, new LinkableWatcher(DocumentMapDataSource));
		private const _imageColumn:ImageColumn = newLinkableChild(this, ImageColumn);
		private const _titleColumn:ReferencedColumn = newLinkableChild(this, ReferencedColumn);
		private const _urlColumn:ReferencedColumn = newLinkableChild(this, ReferencedColumn);
		private const _modtimeColumn:ReferencedColumn = newLinkableChild(this, ReferencedColumn);
		private const _keys:KeySet = newLinkableChild(this, KeySet);

		public function getDataSource():DocumentMapDataSource
		{
			validate();
			return _dataSourceWatcher.target as DocumentMapDataSource;
		}
		
		private function validate():void
		{
			if (detectLinkableObjectChange(validate, dataSourceName, collectionName, _dataSourceWatcher))
			{
				_dataSourceWatcher.targetPath = [dataSourceName.value];
				var ds:DocumentMapDataSource = getDataSource();
				
				var imgRef:ReferencedColumn = _imageColumn.requestLocalObject(ReferencedColumn, true);
				imgRef.setColumnReference(ds, ds && ds.getColumnMetadata(collectionName.value, DocumentMapDataSource.TABLE_DOC_FILES, DocumentMapDataSource.COLUMN_DOC_THUMBNAIL));
				_urlColumn.setColumnReference(ds, ds && ds.getColumnMetadata(collectionName.value, DocumentMapDataSource.TABLE_DOC_FILES, DocumentMapDataSource.COLUMN_DOC_URL));
				
				_titleColumn.setColumnReference(ds, ds && ds.getColumnMetadata(collectionName.value, DocumentMapDataSource.TABLE_DOC_METADATA, DocumentMapDataSource.COLUMN_DOC_TITLE));
				_modtimeColumn.setColumnReference(ds, ds && ds.getColumnMetadata(collectionName.value, DocumentMapDataSource.TABLE_DOC_METADATA, DocumentMapDataSource.COLUMN_DOC_MODIFIED_TIME));
			}
		}
		
		public function getImage(key:IQualifiedKey):BitmapData
		{
			validate();
			return _imageColumn.getValueFromKey(key, BitmapData);
		}
		
		public function getTitle(key:IQualifiedKey):String
		{
			validate();
			return _titleColumn.getValueFromKey(key, String);
		}
		
		public function getUrl(key:IQualifiedKey):String
		{
			validate();
			return _urlColumn.getValueFromKey(key, String);
		}
		
		public function getModTime(key:IQualifiedKey):Date
		{
			validate();
			return _modtimeColumn.getValueFromKey(key, Date);
		}
	}
}

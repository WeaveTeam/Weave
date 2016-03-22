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

package weavejs.data.hierarchy
{
    import weavejs.api.core.ILinkableObject;
    import weavejs.api.data.ColumnMetadata;
    import weavejs.api.data.IWeaveTreeNode;
    import weavejs.net.EntityCache;
    import weavejs.util.JS;
    import weavejs.util.StandardLib;

    public class EntityNodeSearch implements ILinkableObject
    {
		private var _includeAllDescendants:Boolean = true;
		private var _searchField:String = ColumnMetadata.TITLE; // the field to search
		private var _searchString:String = ''; // the search string containing ?* wildcards
		private var _searchRegExp:RegExp = null; // used for local comparisons
		
		private var _entityCacheSearchResults:Object = new JS.WeakMap(); // EntityCache -> SearchResults
		private var _xmlNodeLookup:Object = new JS.WeakMap(); // XMLEntityNode -> true
		
		/**
		 * Set this to true to include all descendants of matching nodes
		 * whether or not the descendants also matched the search.
		 */
		public function get includeAllDescendants():Boolean
		{
			return _includeAllDescendants;
		}
		public function set includeAllDescendants(value:Boolean):void
		{
			if (_includeAllDescendants != value)
			{
				_includeAllDescendants = value;
				Weave.getCallbacks(this).triggerCallbacks();
			}
		}
		
		/**
		 * The public metadata field used for searching.
		 * @default "title"
		 */
		public function get searchField():String
		{
			return _searchField;
		}
		public function set searchField(value:String):void
		{
			value = value || '';
			if (_searchField != value)
			{
				_searchField = value;
				_xmlNodeLookup = new JS.WeakMap();
				Weave.getCallbacks(this).triggerCallbacks();
			}
		}
		
		/**
		 * The search string, which may contain '*' and '?' wildcards.
		 */
		public function get searchString():String
		{
			return _searchString;
		}
		public function set searchString(value:String):void
		{
			if (!value || StandardLib.replace(value, '?', '', '*', '') == '')
				value = '';
			if (_searchString != value)
			{
				_searchString = value;
				_searchRegExp = strToRegExp(value);
				_xmlNodeLookup = new JS.WeakMap();
				Weave.getCallbacks(this).triggerCallbacks();
			}
		}
		
		/**
		 * Use this as the nodeFilter in a WeaveTree.
		 * @param node The node to test.
		 * @see weave.ui.WeaveTree#nodeFilter
		 */
		public function nodeFilter(node:IWeaveTreeNode):Boolean
		{
			if (!_searchField || !_searchString)
				return true;
			
			var lookup:uint;
			
			var en:EntityNode = node as EntityNode;
			if (en)
			{
				var cache:EntityCache = en.getEntityCache();
				var results:SearchResults = _entityCacheSearchResults.get(cache);
				if (!results)
					_entityCacheSearchResults.set(cache, results = new SearchResults());
				
				// invoke remote search if params changed
				if (results.searchField != _searchField || results.searchString != _searchString)
					results.remoteSearch(this, cache);
				
				// if cache updated, rebuild idLookup
				if (Weave.detectChange(results, cache))
				{
					_xmlNodeLookup = new JS.WeakMap();
					results.rebuildLookup(cache);
				}
				
				// The idLookup determines whether or not we want to include this EntityNode.
				lookup = results.idLookup[en.id];
				return !!(lookup & SearchResults.LOOKUP_MATCH_OR_ANCESTOR)
					|| (_includeAllDescendants && (lookup & SearchResults.LOOKUP_DESCENDANT));
			}
			
			// see if the title matches
			if (_searchField == ColumnMetadata.TITLE && _searchRegExp.test(node.getLabel()))
				return true;

			// see if there are any matching descendants
			if (!node.isBranch())
				return false;
			var children:Array = node.getChildren();
			if (children && children.filter(arrayFilter).length)
				return true;
			return false;
		}
		
		private function arrayFilter(node:IWeaveTreeNode, i:int, a:Array):Boolean
		{
			return nodeFilter(node);
		}
		
		/**
		 * Surrounds a string with '*' and replaces ' ' with '*'
		 */
		public static function replaceSpacesWithWildcards(searchString:String):String
		{
			return StandardLib.replace('*' + searchString + '*', ' ', '*');
		}
		
		/**
		 * Generates a RegExp that matches a search string using '?' and '*' wildcards.
		 */
		public static function strToRegExp(searchString:String, flags:String = "i"):RegExp
		{
			var resultStr:String;
			//excape metacharacters other than "*" and "?"
			resultStr = searchString.replace(/[\^\$\\\.\+\(\)\[\]\{\}\|]/g, "\\$&");
			//replace strToSrch "?" with reg exp equivalent "."
			resultStr = resultStr.replace(/[\?]/g, ".");
			//replace strToSrch "*" with reg exp equivalent ".*?"
			resultStr = resultStr.replace(/[\*]/g, ".*?");
			return new RegExp("^" + resultStr + "$", flags);
		}
    }
}

import weavejs.api.net.beans.Entity;
import weavejs.data.hierarchy.EntityNodeSearch;
import weavejs.net.EntityCache;
import weavejs.util.StandardLib;

internal class SearchResults
{
	/**
	 * Usage: if (idLookup[id] & LOOKUP_MATCH_OR_ANCESTOR) ...
	 */
	public static const LOOKUP_MATCH_OR_ANCESTOR:uint = 1;
	/**
	 * Usage: if (idLookup[id] & LOOKUP_DESCENDANT) ...
	 */
	public static const LOOKUP_DESCENDANT:uint = 2;
	/**
	 * Usage: if (idLookup[id] & LOOKUP_VISITED) ...
	 */
	public static const LOOKUP_VISITED:uint = 4;
	
	/**
	 * The value of searchField from the last time remoteSearch() was called
	 */
	public var searchField:String;
	/**
	 * The value of searchString from the last time remoteSearch() was called
	 */
	public var searchString:String;
	/**
	 * Entity IDs which matched the search.
	 */
	public var ids:Array = [];
	/**
	 * entity id -> nonzero if it should be included in the tree
	 */
	public var idLookup:Object = {};
	
	/**
	 * Invokes RPC for search.
	 */
	public function remoteSearch(ens:EntityNodeSearch, cache:EntityCache):void
	{
		searchField = ens.searchField;
		searchString = ens.searchString;
		ids = [];
		idLookup = {};
		var query:Object = {};
		query[searchField] = searchString;
		cache.getService().findEntityIds(query, [searchField]).then(handleSearchResults.bind(this, ens, cache));
	}

	private function handleSearchResults(ens:EntityNodeSearch, cache:EntityCache, newIds:Array):void
	{
		// ignore outdated results
		if (searchField != ens.searchField || searchString != ens.searchString)
			return;
		
		if (Weave.wasDisposed(ens) || Weave.wasDisposed(cache))
			return;
		
		if (StandardLib.compare(ids, newIds))
		{
			ids = newIds;
			rebuildLookup(cache);
			Weave.getCallbacks(ens).triggerCallbacks();
		}
	}

	/**
	 * Rebuilds the idLookup object.
	 */
	public function rebuildLookup(cache:EntityCache):void
	{
		idLookup = {};
		_tempCache = cache;
		ids.forEach(includeAncestors);
		ids.forEach(includeDescendants);
		_tempCache = null;
		
		// as long as there is at least one id in the lookup, include the root node.
		for (var id:* in idLookup)
		{
			idLookup[EntityCache.ROOT_ID] = LOOKUP_MATCH_OR_ANCESTOR;
			break;
		}
	}
	private var _tempCache:EntityCache; // temporary variable used by includeAncestors() and includeDescendants()
	private function includeAncestors(id:int, i:*, a:*):void
	{
		if (idLookup[id] & LOOKUP_MATCH_OR_ANCESTOR)
			return;
		idLookup[id] |= LOOKUP_MATCH_OR_ANCESTOR;
		var entity:Entity = _tempCache.getEntity(id);
		if (entity.parentIds)
			entity.parentIds.forEach(includeAncestors);
	}
	private function includeDescendants(id:int, i:*, a:*):void
	{
		if (idLookup[id] & LOOKUP_DESCENDANT)
			return;
		idLookup[id] |= LOOKUP_DESCENDANT;
		var entity:Entity = _tempCache.getEntity(id);
		if (entity.childIds)
			entity.childIds.forEach(includeDescendants);
	}
}

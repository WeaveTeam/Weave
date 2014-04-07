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
package weave.data.hierarchy
{
    import flash.utils.Dictionary;
    
    import mx.rpc.events.ResultEvent;
    
    import weave.api.core.ILinkableObject;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.detectLinkableObjectChange;
    import weave.api.getCallbackCollection;
    import weave.compiler.StandardLib;
    import weave.services.EntityCache;
    import weave.services.addAsyncResponder;

    public class EntityNodeSearch implements ILinkableObject
    {
		private var _entityCacheSearchResults:Dictionary = new Dictionary(true); // EntityCache -> SearchResults
		private var _searchField:String = ColumnMetadata.TITLE; // the field to search
		private var _searchString:String = ''; // the search string containing ?* wildcards
		private var _searchRegExp:RegExp = null; // used for local comparisons
		private var _cachedNodeMatches:Dictionary = new Dictionary(true); // node -> true
		private var _includeAllDescendants:Boolean = true;
		
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
				getCallbackCollection(this).triggerCallbacks();
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
				_cachedNodeMatches = new Dictionary(true);
				getCallbackCollection(this).triggerCallbacks();
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
				_cachedNodeMatches = new Dictionary(true);
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * Use this as the nodeFilter in a WeaveTree.
		 * @param node The node to test.
		 * @see weave.ui.WeaveTree#nodeFilter
		 */
		public function nodeFilter(node:IWeaveTreeNode):Boolean
		{
			if (!_searchField || !_searchString || _cachedNodeMatches[node])
				return true;
			
			var en:EntityNode = node as EntityNode;
			var xen:XMLEntityNode = node as XMLEntityNode;
			if (en)
			{
				var cache:EntityCache = en.getEntityCache();
				var results:SearchResults = _entityCacheSearchResults[cache];
				if (!results)
					_entityCacheSearchResults[cache] = results = new SearchResults();
				
				// invoke remote search if params changed
				if (results.searchField != _searchField || results.searchString != _searchString)
					results.remoteSearch(this, cache);
				
				// if cache updated, rebuild idLookup
				if (detectLinkableObjectChange(results, cache))
					results.rebuildLookup(cache);
				
				// The idLookup determines whether or not we want to include this EntityNode.
				var lookup:uint = results.idLookup[en.id];
				if (_includeAllDescendants)
					return !!lookup;
				else
					return !!(lookup & SearchResults.LOOKUP_MATCH_OR_ANCESTOR);
			}
			else if (xen)
			{
				// does the field match the search string?
				if (_searchRegExp.test(xen.xml.attribute(_searchField)))
				{
					_cachedNodeMatches[node] = true;
					return true;
				}
			}
			
			// if not an EntityNode and doesn't match search string, we still want to include the node if there are any matching descendants
			if (!node.isBranch())
				return false;
			var children:Array = node.getChildren();
			if (children && children.filter(arrayFilter).length)
			{
				_cachedNodeMatches[node] = true;
				return true;
			}
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

import flash.utils.Dictionary;

import mx.rpc.events.ResultEvent;

import weave.api.getCallbackCollection;
import weave.api.objectWasDisposed;
import weave.api.services.beans.Entity;
import weave.compiler.StandardLib;
import weave.data.hierarchy.EntityNodeSearch;
import weave.services.EntityCache;
import weave.services.addAsyncResponder;

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
		addAsyncResponder(cache.getService().findEntityIds(query, [searchField]), handleSearchResults, null, [ens, cache]);
	}

	private function handleSearchResults(event:ResultEvent, ens0_cache1:Array):void
	{
		var ens:EntityNodeSearch = ens0_cache1[0];
		var cache:EntityCache = ens0_cache1[1];
		
		if (objectWasDisposed(ens) || objectWasDisposed(cache))
			return;
		
		// ignore outdated results
		if (searchField != ens.searchField || searchString != ens.searchString)
			return;
		
		var newIds:Array = event.result as Array;
		if (StandardLib.arrayCompare(ids, newIds))
		{
			ids = newIds;
			rebuildLookup(cache);
			getCallbackCollection(ens).triggerCallbacks();
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

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
		private var _includeAllDescendants:Boolean = true;
		private var _searchField:String = ColumnMetadata.TITLE; // the field to search
		private var _searchString:String = ''; // the search string containing ?* wildcards
		private var _searchRegExp:RegExp = null; // used for local comparisons
		
		private var _entityCacheSearchResults:Dictionary = new Dictionary(true); // EntityCache -> SearchResults
		private var _xmlNodeLookup:Dictionary = new Dictionary(true); // XMLEntityNode -> true
		
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
				_xmlNodeLookup = new Dictionary(true);
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
				_xmlNodeLookup = new Dictionary(true);
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
			if (!_searchField || !_searchString)
				return true;
			
			var lookup:uint;
			
			var en:EntityNode = node as EntityNode;
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
				{
					_xmlNodeLookup = new Dictionary(true);
					results.rebuildLookup(cache);
				}
				
				// The idLookup determines whether or not we want to include this EntityNode.
				lookup = results.idLookup[en.id];
				return !!(lookup & SearchResults.LOOKUP_MATCH_OR_ANCESTOR)
					|| (_includeAllDescendants && (lookup & SearchResults.LOOKUP_DESCENDANT));
			}
			
			var xen:XMLEntityNode = node as XMLEntityNode;
			if (xen)
			{
				if (detectLinkableObjectChange(this, xen.getDataSource()))
					_xmlNodeLookup = new Dictionary(true);
				
				lookup = _xmlNodeLookup[xen];
				if (lookup)
					return !!(lookup & SearchResults.LOOKUP_MATCH_OR_ANCESTOR)
						|| (_includeAllDescendants && (lookup & SearchResults.LOOKUP_DESCENDANT));
			
				if (_searchRegExp.test(xen.xml.attribute(_searchField)))
				{
					_xmlNodeLookup[xen] |= SearchResults.LOOKUP_MATCH_OR_ANCESTOR;
					_cacheXMLDescendants(xen);
					return true;
				}
			}
			
			// see if the title matches
			if (!xen && _searchField == ColumnMetadata.TITLE && _searchRegExp.test(node.getLabel()))
				return true;

			// see if there are any matching descendants
			if (!node.isBranch())
			{
				if (xen)
					_xmlNodeLookup[xen] |= SearchResults.LOOKUP_VISITED;
				return false;
			}
			var children:Array = xen ? xen.getChildrenExt() : node.getChildren();
			if (children && children.filter(arrayFilter).length)
			{
				if (xen)
					_xmlNodeLookup[xen] |= SearchResults.LOOKUP_MATCH_OR_ANCESTOR;
				return true;
			}
			if (xen)
				_xmlNodeLookup[xen] |= SearchResults.LOOKUP_VISITED;
			return false;
		}
		
		private function _cacheXMLDescendants(xen:XMLEntityNode):void
		{
			_xmlNodeLookup[xen] |= SearchResults.LOOKUP_DESCENDANT;
			for each (var child:IWeaveTreeNode in xen.getChildrenExt())
			{
				var xc:XMLEntityNode = child as XMLEntityNode;
				if (xc)
				{
					nodeFilter(xc);
					_cacheXMLDescendants(xc);
				}
			}
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
		if (StandardLib.compare(ids, newIds))
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

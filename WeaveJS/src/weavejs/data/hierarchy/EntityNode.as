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
    import weavejs.api.data.EntityType;
    import weavejs.api.data.IColumnReference;
    import weavejs.api.data.IDataSource;
    import weavejs.api.data.IWeaveTreeNode;
    import weavejs.api.data.IWeaveTreeNodeWithEditableChildren;
    import weavejs.api.data.IWeaveTreeNodeWithPathFinding;
    import weavejs.api.net.beans.Entity;
    import weavejs.api.net.beans.EntityHierarchyInfo;
    import weavejs.net.EntityCache;
    import weavejs.data.source.WeaveDataSource;
    import weavejs.util.DebugUtils;
    import weavejs.util.JS;

	[RemoteClass]
    public class EntityNode implements IWeaveTreeNodeWithEditableChildren, IWeaveTreeNodeWithPathFinding, IColumnReference
    {
		/**
		 * Dual lookup: (EntityCache -> int) and (int -> EntityCache)
		 */
		private static var $map_cacheLookup:Object;
		private static var $cacheSerial:int = 0;
		
		public static var debug:Boolean = false;
		
		/**
		 * @param entityCache The entityCache which the Entity belongs to.
		 * @param rootFilterEntityType To be used by root node only.
		 * @param nodeFilterFunction Used for filtering children.
		 */
		public function EntityNode(entityCache:EntityCache = null, rootFilterEntityType:String = null, overrideLabel:String = null)
		{
			setEntityCache(entityCache);
			this._rootFilterEntityType = rootFilterEntityType;
			this._overrideLabel = overrideLabel;
		}
		
		private var _rootFilterEntityType:String = null;
		/**
		 * @private
		 */
		public var _overrideLabel:String = null;
		
		/**
		 * This primitive value is used in place of a pointer to an EntityCache object
		 * so that this object may be serialized & copied by the Flex framework without losing this information.
		 * @private
		 */
		public var _cacheId:int = 0;
		
		/**
		 * The entity ID.
		 */
		public var id:int = -1;
		
		/**
		 * Sets the EntityCache associated with this node.
		 */
		public function setEntityCache(entityCache:EntityCache):void
		{
			if (!$map_cacheLookup)
				$map_cacheLookup = new JS.Map();
			var cid:int = $map_cacheLookup.get(entityCache);
			if (entityCache && !cid)
			{
				cid = ++$cacheSerial;
				$map_cacheLookup.set(cid, entityCache);
				$map_cacheLookup.set(entityCache, cid);
			}
			if (cid != _cacheId)
			{
				_cacheId = cid;
				for each (var child:EntityNode in _childNodeCache)
					child.setEntityCache(entityCache);
			}
		}
		
		/**
		 * Gets the EntityCache associated with this node.
		 */
		public function getEntityCache():EntityCache
		{
			return $map_cacheLookup ? $map_cacheLookup.get(_cacheId) : null;
		}
		
		/**
		 * Gets the Entity associated with this node.
		 */
		public function getEntity():Entity
		{
			return getEntityCache().getEntity(id);
		}
		
		// the node can re-use the same children array
		private const _childNodes:Array = [];
		
		// We cache child nodes to avoid creating unnecessary objects.
		// Each node must have its own child cache (not static) because we can't have the same node in two places in a Tree.
		private const _childNodeCache:Object = {}; // id -> EntityNode
		
		/**
		 * @inheritDoc
		 */
		public function equals(other:IWeaveTreeNode):Boolean
		{
			if (other == this)
				return true;
			var node:EntityNode = other as EntityNode;
			return !!node
				&& this._cacheId == node._cacheId
				&& this.id == node.id;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDataSource():IDataSource
		{
			var cache:EntityCache = getEntityCache();
			var owner:ILinkableObject = cache;
			while (owner)
			{
				owner = Weave.getOwner(owner);
				if (owner is IDataSource)
					return owner as IDataSource;
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getColumnMetadata():Object
		{
			var meta:Object = {};
			var entity:Entity = getEntity();
			if (entity.getEntityType() != EntityType.COLUMN)
				return null; // not a column
			for (var key:String in entity.publicMetadata)
				meta[key] = entity.publicMetadata[key];
			meta[WeaveDataSource.ENTITY_ID] = id;
			return meta;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getLabel():String
		{
			if (_overrideLabel)
				return _overrideLabel;
			
			var title:String;
			var entity:Entity;
			var entityType:String;
			var cache:EntityCache = getEntityCache();
			var branchInfo:EntityHierarchyInfo = cache.getBranchInfo(id);
			if (branchInfo)
			{
				// avoid calling getEntity()
				entityType = branchInfo.entityType || 'entity';
				title = branchInfo.title || Weave.lang("Untitled {0}#{1}", entityType, branchInfo.id);
				
				if (entityType == EntityType.TABLE)
					title = Weave.lang("{0} ({1})", title, branchInfo.numChildren);
			}
			else
			{
				entity = getEntity();
				
				title = entity.publicMetadata[ColumnMetadata.TITLE];
				if (!title)
				{
					var name:String = entity.publicMetadata['name'];
					if (name)
						title = '[name: ' + name + ']';
				}
				
				if (!title || debug)
					entityType = entity.getEntityType() || 'entity';
				
				if (!title && !entity.initialized)
				{
					if (_rootFilterEntityType)
					{
						var ds:IDataSource = getDataSource();
						if (ds)
							title = Weave.getRoot(ds).getName(ds) || title;
					}
					else
						title = '...';
				}
			}
			
			if (cache.entityIsCached(id))
			{
				if (!entity)
					entity = cache.getEntity(id);
				if (entity.getEntityType() != EntityType.COLUMN && entity.parentIds.length > 1)
					title += Weave.lang(" ; Warning: Multiple parents ({0})", entity.parentIds);
			}
			
			var idStr:String;
			if (!title || debug)
				idStr = Weave.lang("{0}#{1}", entityType, id);
			
			if (!title)
				title = idStr;
			
			if (debug)
			{
				var children:Array = getChildren();
				if (entityType != EntityType.COLUMN && children)
					idStr += '; ' + children.length + ' children';
				title = Weave.lang('({0}) {1} {2}', idStr, DebugUtils.debugId(this), title);
			}
			
			return title;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isBranch():Boolean
		{
			// root is a branch
			if (_rootFilterEntityType)
				return true;
			
			var cache:EntityCache = getEntityCache();
			
			var info:EntityHierarchyInfo = cache.getBranchInfo(id);
			if (info)
				return info.entityType != EntityType.COLUMN;
			
			var entity:Entity = cache.getEntity(id);
			
			// treat entities that haven't downloaded yet as leaf nodes
			// columns are leaf nodes
			return entity.initialized
				&& entity.getEntityType() != EntityType.COLUMN
		}

		/**
		 * @inheritDoc
		 */
		public function hasChildBranches():Boolean
		{
			if (_rootFilterEntityType)
				return true;
			
			var cache:EntityCache = getEntityCache();
			
			var info:EntityHierarchyInfo = cache.getBranchInfo(id);
			// tables and columns do not have child branches
			if (info && (info.entityType == EntityType.TABLE || info.entityType == EntityType.COLUMN))
				return false;
			
			return cache.getEntity(id).hasChildBranches;
		}
		
		private function getCachedChildNode(childId:int):EntityNode
		{
			var child:EntityNode = _childNodeCache[childId] as EntityNode;
			if (!child)
			{
				child = new EntityNode(getEntityCache());
				child.id = childId;
				_childNodeCache[childId] = child;
			}
			if (child.id != childId)
			{
				JS.error("BUG: EntityNode id has changed since it was first cached");
				child.id = childId;
			}
			return child;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getChildren():Array
		{
			var cache:EntityCache = getEntityCache();
			
			var childIds:Array;
			if (_rootFilterEntityType)
			{
				childIds = cache.getIdsByType(_rootFilterEntityType);
			}
			else
			{
				var entity:Entity = cache.getEntity(id);
				if (entity.getEntityType() == EntityType.COLUMN)
					return null; // leaf node
				childIds = entity.childIds;
			}
			
			if (!childIds)
			{
				_childNodes.length = 0;
				return isBranch() ? _childNodes : null;
			}
			
			_childNodes.length = childIds.length;
			for (var i:int = 0; i < childIds.length; i++)
				_childNodes[i] = getCachedChildNode(childIds[i]);
			
			return _childNodes;
		}
		
		/**
		 * @inheritDoc
		 */
		public function addChildAt(child:IWeaveTreeNode, index:int):Boolean
		{
			var childNode:EntityNode = child as EntityNode;
			if (childNode)
			{
				// does not support adding children from a different EntityCache
				if (getEntityCache() != childNode.getEntityCache())
					return false;
				getEntityCache().add_child(this.id, childNode.id, index);
				return true;
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeChild(child:IWeaveTreeNode):Boolean
		{
			var childNode:EntityNode = child as EntityNode;
			if (childNode)
			{
				// does not support removing children from a different EntityCache
				if (getEntityCache() != childNode.getEntityCache())
					return false;
				childNode.getEntityCache().remove_child(this.id, childNode.id);
				return true;
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function findPathToNode(descendant:IWeaveTreeNode):Array
		{
			var node:EntityNode = descendant as EntityNode;
			if (!node || this._cacheId != node._cacheId)
				return null;
			
			var cache:EntityCache = getEntityCache();
			if (_rootFilterEntityType == EntityType.TABLE)
			{
				// root table node only has two levels - table, column
				// return path of EntityNode objects
				for each (var id:int in node.getEntity().parentIds)
				{
					if (cache.getEntity(id).getEntityType() == EntityType.TABLE)
					{
						var tableNode:EntityNode = this.getCachedChildNode(id);
						return [this, tableNode, tableNode.getCachedChildNode(node.id)];
					}
				}
				return null;
			}
			
			// get path of Entity objects
			var path:Array = cache.getEntityPath(this.getEntity(), node.getEntity());
			// get path of EntityNode objects
			if (path)
			{
				for (var i:int = 0; i < path.length; i++)
				{
					if (i == 0)
						node = this;
					else
						node = node.getCachedChildNode((path[i] as Entity).id);
					path[i] = node;
				}
			}
			return path;
		}
    }
}

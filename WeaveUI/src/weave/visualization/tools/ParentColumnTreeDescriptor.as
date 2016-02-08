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

package weave.visualization.tools
{
    import flash.utils.Dictionary;
    
    import mx.collections.ArrayCollection;
    import mx.collections.ICollectionView;
    import mx.controls.treeClasses.ITreeDataDescriptor;
    
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IKeySet;
    import weave.api.data.IQualifiedKey;
    import weave.compiler.StandardLib;
    import weave.data.KeySets.SortedKeySet;


    public class ParentColumnTreeDescriptor implements ITreeDataDescriptor
    {
        private var cachedTreeInfo:Dictionary = null;
        private var rootNodes:ArrayCollection = null;

		/**
		 * NOTE: record sorting in this function depends on WeaveAPI.StatisticsCache.getColumnStatistics(sortColumn)
		 * @param parentColumn
		 * @param allKeys Note: This function modifies the keys in place
		 * @param sortColumn 
		 */
        public function updateCache(parentColumn:IAttributeColumn, allKeys:IKeySet, sortColumn:IAttributeColumn):void
        {
            cachedTreeInfo = new Dictionary();

            rootNodes = new ArrayCollection([]);
			
		 	// NOTE: this sort depends on WeaveAPI.StatisticsCache
            var orderedKeys:Array = SortedKeySet.generateSortCopyFunction([sortColumn])(allKeys.keys);

            for (var index:String in orderedKeys)
            {
                var key:IQualifiedKey = orderedKeys[index] as IQualifiedKey;
                var localName:String = parentColumn.getValueFromKey(key, String);
                var keyType:String = key.keyType;
                var parent_key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(keyType, localName);

                if (!allKeys.containsKey(parent_key))
                {
                    rootNodes.list.addItem(key);
                }
                else
                {
                    if (!cachedTreeInfo[parent_key]) 
                        cachedTreeInfo[parent_key] = new ArrayCollection([]);

                    cachedTreeInfo[parent_key].list.addItem(key);
                }
            }
        }

        public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean
        {
            return false;
        }

        public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean
        {
            return false;
        }

        public function getChildrenRecursive(parent:IQualifiedKey):ArrayCollection
        {
            var queue:Array = [];
            var output:Array = [];

            queue.push(parent);

            while (queue.length > 0)
            {
                var node:Object = queue.pop();

                output.push(node);

                var children:ArrayCollection = getChildren(node) as ArrayCollection;

                if (children) for (var idx:int = 0; idx < children.length; idx++)
                {
                    queue.push(children.getItemAt(idx));
                }
            }
            return new ArrayCollection(output);
        }

        public function getChildren(node:Object, model:Object = null):ICollectionView
        {
            var qkey:IQualifiedKey = node as IQualifiedKey;
            
            if (qkey == null) return rootNodes;
            else return cachedTreeInfo[qkey];
        }
        public function hasChildren(node:Object, model:Object = null):Boolean
        {
            return isBranch(node, model);
        }
        public function getData(node:Object, model:Object = null):Object
        {
            return node;
        }
        public function isBranch(node:Object, model:Object = null):Boolean
        {
            return (getChildren(node, model) != null);
        }
    }
}

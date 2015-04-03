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

package weave.graphs
{
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.graphs.IGraphNode;
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;
	
	/**
	 * A node of a graph.
	 * 
	 * @author kmonico
	 */
	public class GraphNode implements IGraphNode
	{
		public function GraphNode()
		{
		}
		
		
		public function get position():Point
		{
			return _position;
		}
		public function setPosition(x:Number, y:Number):void
		{
			_position.x = x;
			_position.y = y;
		}
		
		public function get id():String { return _id; }
		public function set id(val:String):void { _id = val; }
		
		public function get key():IQualifiedKey { return _key; }
		public function set key(q:IQualifiedKey):void { _key = q; }
		public function get bounds():IBounds2D { return _bounds; }
		public function get label():String { return _label; }
		
		public function get nextPosition():Point
		{
			return _nextPosition;
		}
		public function setNextPosition(x:Number, y:Number):void
		{
			_nextPosition.x = x;
			_nextPosition.y = y;
		}
		
		private var _key:IQualifiedKey; // needed for fast lookups or something
		private var _id:String;
		private var _value:Object;
		private var _label:String;
		private const _isDrawn:Boolean = false;
		private const _position:Point = new Point();
		private const _bounds:IBounds2D = new Bounds2D();
		private const _nextPosition:Point = new Point();

		private const _connectedNodes:Vector.<IGraphNode> = new Vector.<IGraphNode>();
		
		public function addConnection(node:IGraphNode):void
		{
			if (_connectedNodes.indexOf(node, 0) < 0)
				_connectedNodes.push(node);
		}
		
		public function removeConnection(node:IGraphNode):void
		{
			var idx:int = _connectedNodes.indexOf(node, 0);
			if (idx < 0)
				return;
			_connectedNodes.splice(idx, 1);
		}
		
		public function get connections():Vector.<IGraphNode>
		{
			return _connectedNodes;
		}
		
		public function hasConnection(otherNode:IGraphNode):Boolean
		{
			for each (var node:IGraphNode in _connectedNodes)
			{
				if (otherNode == node)
					return true;
			}
			return false;
		}
	}
}
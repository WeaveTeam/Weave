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
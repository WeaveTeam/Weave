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
	import flash.net.URLLoader;
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.graphs.IGraphAlgorithm;
	import weave.api.graphs.IGraphNode;
	import weave.api.primitives.IBounds2D;
	import weave.api.reportError;
	import weave.core.CallbackCollection;
	import weave.primitives.Bounds2D;
	import weave.services.WeaveRServlet;
	import weave.services.beans.RResult;
	import weave.utils.ComputationalGeometryUtils;
	import mx.utils.ObjectUtil;
	import weave.services.addAsyncResponder;

	/**
	 * An abstract class with a callback collection which implements IGraphAlgorithm.
	 * 
	 * @author kmonico
	 */	
	public class AbstractGraphAlgorithm extends CallbackCollection implements IGraphAlgorithm
	{
		public function AbstractGraphAlgorithm()
		{
		}

		protected function callRServe(script:String, outputParams:Array, bounds:IBounds2D):void
		{
			debugTrace("Calling R:" + script);
			reportError("Calling R:" + script);
			if (outputParams.length != 2)
				throw new Error("Invalid output parameters provided to R.");

			var token:RToken = new RToken(bounds, ++_rId);
			var asyncToken:AsyncToken = rService.runScript([],[], [], outputParams, script, "", true, true,false);
			addAsyncResponder(asyncToken, handleLayoutResult, handleLayoutFault, token);
		}

		public function setupData(nodesColumn:IAttributeColumn, edgeSources:IAttributeColumn, edgeTargets:IAttributeColumn):void
		{
			trace('setupData');
			if (!nodesColumn || !edgeSources || !edgeTargets)
				return;

			_keys = nodesColumn.keys;
			_keyToNode = new Dictionary();
			_edges.length = 0;

			var idToNodeKey:Dictionary = new Dictionary();
			var i:int;
			var nodes:Array = [];
			
			// setup the nodes map
			{ // force garbage collection
				var nodesKeys:Array = nodesColumn.keys;
				
				_nodeKeyType = nodesKeys.length > 0 ? (nodesKeys[0] as IQualifiedKey).keyType : null;
				
				_numNodes = nodesKeys.length;
				for (i = 0; i < nodesKeys.length; ++i)
				{
					var key:IQualifiedKey = nodesKeys[i];
					var newNode:IGraphNode = new GraphNode();
					newNode.id = nodesColumn.getValueFromKey(key, String);
					newNode.key = key;
					_keyToNode[key] = newNode;
					idToNodeKey[newNode.id] = key;
					nodes[newNode.id] = newNode;
				}
				nodesKeys = null;
			}
			
			// setup the edges array
			{ // force garbage collection
				var edgesKeys:Array = edgeSources.keys;
				for (i = 0; i < edgesKeys.length; ++i)
				{
					var edgeKey:IQualifiedKey = edgesKeys[i];
					var idSource:String = edgeSources.getValueFromKey(edgeKey, String);
					var idTarget:String = edgeTargets.getValueFromKey(edgeKey, String);
					var newEdge:GraphEdge = new GraphEdge();
					var source:IGraphNode = _keyToNode[ idToNodeKey[idSource] ];
					var target:IGraphNode = _keyToNode[ idToNodeKey[idTarget] ];
					
					if (!source)
					{
						//trace('no source node with id: ', idSource, ' exists');
						continue;
					}
					if (!target)
					{
						//trace('no target node with id: ', idTarget, ' exists');
						continue;
					}
					if (source == target)
					{
						//trace('cannot have nodes connected to themselves');
						continue;
					}
						
					newEdge.id = i;
					newEdge.source = source;
					newEdge.target = target;
					_edges.push(newEdge);
					source.addConnection(target);
					target.addConnection(source);
				}
			}
			
			// setup the partitions of the nodes
			var numVisited:int = 0;
			var visited:Dictionary = new Dictionary();
			var iPartition:int = 0;
			_partitions = new Vector.<Vector.<IQualifiedKey>>();
//			while (numVisited != _numNodes)
//			{
//				_partitions[iPartition] = new Vector.<IQualifiedKey>();
//				var firstNode:IGraphNode;
//				for (var obj:* in _keyToNode)
//				{
//					if (visited[(_keyToNode[obj] as IGraphNode).id] == undefined)
//					{
//						firstNode = _keyToNode[obj];
//						break;
//					}
//				}
//				visited[firstNode.id] = true;
//				_partitions[iPartition].push(firstNode.key);
//				_keyToPartition[firstNode.key] = iPartition;
//				++numVisited;
//				var queue:Array = [firstNode];
//				while (queue.length > 0)
//				{
//					var node:GraphNode = queue.shift();
//					var connections:Vector.<IGraphNode> = node.connections;
//					for each (var otherNode:IGraphNode in connections)
//					{
//						if (visited[otherNode.id] == undefined)
//						{
//							queue.push(otherNode);
//							visited[otherNode.id] = true;
//							_partitions[iPartition].push(otherNode.key);
//							_keyToPartition[otherNode.key] = iPartition;
//							++numVisited;
//						}
//					}
//				}
//				++iPartition;
//			}

				
//			trace('num partitions: ', iPartition);
//			if (numVisited != _numNodes)
//			{
//				trace('something: ', numVisited, _numNodes);
//			}
			
			_constrainedBounds.setCenteredRectangle(0, 0, 2 * _numNodes, 2 * _numNodes);
			incrementLayout(_keys, _constrainedBounds);
		}

		public function getNeighboringKeys(keys:Array):Array
		{
			var result:Dictionary = new Dictionary();
			var keyDictionary:Dictionary = new Dictionary();
			
			for each (var key:IQualifiedKey in keys)
			{
				keyDictionary[key] = true; 
				result[key] = true; // ensure lone nodes are always considered
			}
			for each (var edge:GraphEdge in _edges)
			{
				var source:IGraphNode = edge.source;
				var target:IGraphNode = edge.target;
				var sourceKey:IQualifiedKey = source.key;
				var targetKey:IQualifiedKey = target.key;
				
				// if we haven't seen the key and it's in the keys array, push it to result
				if (keyDictionary[sourceKey] != undefined || keyDictionary[targetKey] != undefined)
				{
					result[sourceKey] = true;
					result[targetKey] = true;
				}
			}
			var resultArray:Array = [];
			for (var nodeKeyObj:Object in result)
			{
				resultArray.push(nodeKeyObj as IQualifiedKey);
			}
			return resultArray;
		}
		
		public function incrementLayout(keys:Array, bounds:IBounds2D):void
		{
			throw new Error("incrementLayout() not implemented by subclass.");
		}
		
		public function getOutputBounds(keys:Array, output:IBounds2D):void
		{
			// if keys is the key source, just use the total output bounds
			if (!keys || keys.length == _numNodes)
			{
				output.copyFrom(outputBounds);
				return;
			}
			
			// otherwise, iterate through keys and get output
			output.reset();
			for each (var key:IQualifiedKey in keys)
			{
				var node:IGraphNode = getNodeFromKey(key);
				if (!node)
					continue;
				output.includePoint(node.position);
			}			
		}
		
		public function resetAllNodes():void
		{
			var i:int = 0;
			var length:int = 0;
			
			outputBounds.reset();
			for each (var node:GraphNode in _keyToNode)
			{
				if (node == null)
				{
					trace('empty element in _idToNode');
					continue;
				}
				node.position.x = 0; 
				node.position.y = 0;
				outputBounds.includePoint(node.position);
			}
			incrementLayout(_keys, _constrainedBounds);
		}
		
		public function getNodeFromKey(key:IQualifiedKey):IGraphNode
		{
			return _keyToNode[key];
		}
		
		public function updateOutputBounds():void
		{
			outputBounds.reset();
			for each (var node:IGraphNode in _keyToNode)
			{
				var nextPos:Point = node.nextPosition;
				node.setPosition(nextPos.x, nextPos.y);
				outputBounds.includePoint(nextPos);				
			}
			outputBounds.centeredResize(
						outputBounds.getWidth() * 1.1,
						outputBounds.getHeight() * 1.1
					);
		}

		public function updateDraggedKeys(keys:Array, dx:Number, dy:Number, runSpatialCallbacks:Boolean = true):void
		{
			var key:IQualifiedKey;
			var rScript:String = '';
			for each (key in keys)
			{
				var node:IGraphNode = _keyToNode[key];
				if (!node)
					continue;
				// next pos?
				node.nextPosition.x = node.position.x + dx;
				node.nextPosition.y = node.position.y + dy;
			}

			updateOutputBounds();
		}
		
		protected function generateVertexesString(keys:Array):String
		{
			var vectorVerticesString:String = 'vertexes <- data.frame(c(';
			var vertices:Array = [];
			for (var iKey:int = 0; iKey < keys.length; ++iKey)
			{
				var key:IQualifiedKey = keys[iKey];
				var node:IGraphNode = _keyToNode[key];
				if (!node)
					continue;
				vertices.push("'" + node.key.localName + "'");
				lastUsedNodes.push(node);
			}
			vectorVerticesString += vertices.join(',') + '))';
			return vectorVerticesString;
		}
		
		public function initRService(url:String):void
		{
			rService = new WeaveRServlet(url);
			getCallbackCollection(this).triggerCallbacks();
		}

		protected function generateGraphString(graphName:String, edges:String, vertexes:String):String
		{
			return graphName + ' <- graph.data.frame(' + edges + ', vertices=' + vertexes + ') ';
		}
		protected function generateEdgesString(keys:Array):String
		{
			var key:IQualifiedKey;
			var keyHash:Dictionary = new Dictionary();
			for each (key in keys)
			{
				keyHash[key] = true;
			}
			
			// build the script to store the edges data.frame
			var edgesString:String = 
				'edges <- data.frame(from=c(';
			var edgeSources:Array = [];
			var edgeTargets:Array = [];
			for each (var edge:GraphEdge in _edges)
			{
				var source:IGraphNode = edge.source;
				var target:IGraphNode = edge.target;
				
				if (keyHash[source.key] == undefined || keyHash[target.key] == undefined)
					continue;
				
				edgeSources.push("'" + source.key.localName + "'");
				edgeTargets.push("'" + target.key.localName + "'");
			}
			edgesString += edgeSources.join(',') + '),' + 'to=c(' + edgeTargets.join(',') + '))';
			
			return edgesString;
		}
		
		protected function handleLayoutResult(event:ResultEvent, token:Object = null):void
		{
			// do nothing if this wasn't the last R call
			var rId:int = (token as RToken).id;
			if (rId != _rId)
				return;
			
			var node:IGraphNode;
			var constrainingBounds:IBounds2D = (token as RToken).bounds;
			
			var array:Array = event.result as Array;
			if (!array || array.length < 3)
			{
				reportError("Invalid or insufficient results from RService:" + ObjectUtil.toString(event.result));
				return;
			}
			/* Convert the result's name/value pair objects to a flat object. */
			var layoutResult:Object = {};
			for (var i:int = 0; i < array.length; i++)
			{
				var subResult:Object = array[i] as Object;
				layoutResult[subResult.name] = subResult.value as Array;
			}
			outputBounds.reset();
			
			try
			{
				var vertexNames:Array = layoutResult["V(weaveGraph)$name"];
				var vertexes:Array = layoutResult["vertexes"];
				var raw_layout:Array = layoutResult["weaveGraphLayout"];
				var resultKeys:Array = new Array();
				for (var keyName:String in layoutResult)
				{
					resultKeys.push(keyName);
				}

				debugTrace(raw_layout);
				// this is an array of arrays.
				// resultLocations[0] is the first object, where resultLocations[0][0] is x and resultLocations[0][1] for y
				var resultLocations:Array = array[1].value as Array;
				// this is an array of key.localName values. 
				// localKeyNames[i] is the localName of the QKey for the corresponding node of resultLocations[i]
				var localKeyNames:Array = array[2].value as Array;
				for (var i:int = 0; i < resultLocations.length; ++i)
				{
					// get the key and node
					var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(_nodeKeyType, localKeyNames[i]);
					if (!key)
						trace('no key in handleLayoutResult');
					node = _keyToNode[key];
					if (!node)
						throw new Error("Result returned from RService contains invalid vertices.");
					
					var point:Array = resultLocations[i] as Array;
					if (!point)
						throw new Error("Invalid result returned from RService. Is Rserve running with the igraph library?");
					
					var x:Number = point[0];
					var y:Number = point[1];
					
					node.nextPosition.x = x;
					node.nextPosition.y = y;
					outputBounds.includePoint(node.nextPosition);
				}
				
				if (constrainingBounds) // constrain the nodes
				{
					for each (node in lastUsedNodes)
					{
						outputBounds.projectPointTo(node.nextPosition, constrainingBounds);
					}
				}
				else // no constrain--this was a global layout
				{
					_constrainedBounds.copyFrom(outputBounds);
				}
				updateOutputBounds(); // update the node positions
				getCallbackCollection(this).triggerCallbacks(); 
				
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		protected function handleLayoutFault(event:FaultEvent, token:Object = null):void
		{
			reportError(event.fault);
		}

		private var _rId:int = 0;
		
		protected var _keys:Array = [];
		protected var _nodeKeyType:String = null; // the key type of the nodes
		protected var _partitions:Vector.<Vector.<IQualifiedKey>> = null; // vector of vector of keys, where each vector of keys is a partition of the graph (NOT USED)
		protected var _edges:Array = []; // Array of GraphEdges
		protected var _keyToNode:Dictionary = new Dictionary();; // IQualifiedKey -> GraphNode
		protected var _numNodes:int = 0; // the number of nodes in _keyToNode
		protected var outputBounds:IBounds2D = new Bounds2D(); // the aggregate bounds of the graph
		protected var _keyToPartition:Dictionary = new Dictionary(); // a mapping of IQualifiedKey -> int (partition index)
		protected var _constrainedBounds:IBounds2D = new Bounds2D(); 

		// the mappings used to handle R calls
		protected var lastUsedNodes:Array = []; // the nodes of the last R call
		
		protected const tempPoint:Point = new Point();
		protected const tempNode:IGraphNode = new GraphNode();
		
		
		// R service
		protected var rService:WeaveRServlet = null;

		// the name of the graph for R
		protected var graphName:String = 'weaveGraph';
		protected var graphEdges:String = 'E(' + graphName + ')';
		protected var graphNodes:String = 'V(' + graphName + ')$name';
		
		// the name of the subgraph used in R
//		protected var subGraphName:String = 'weaveSubGraph';
//		protected var subGraphEdges:String = 'E(' + subGraphName + ')';
//		protected var subGraphNodes:String = 'V(' + subGraphName + ')$name';
		
		// the name of the layout
		protected var weaveGraphLayout:String = 'weaveGraphLayout';
		
		// the string of the library
		protected var libraryCall:String = 'library(igraph)';
		
		// the current active request
		protected var _activeLoader:URLLoader = null;
	}
}

import weave.api.primitives.IBounds2D;

internal class RToken
{
	public var bounds:IBounds2D = null;
	public var id:int = 0;
	public function RToken(b:IBounds2D, uid:int)
	{
		bounds = b;
		id = uid;
	}
	
}

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

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.graphs.IGraphAlgorithm;
	import weave.api.graphs.IGraphNode;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.graphs.ForceDirectedLayout;
	import weave.graphs.GridForceDirectedLayout;
	import weave.graphs.KamadaKawaiLayout;
	import weave.graphs.LargeGraphLayout;
	import weave.primitives.Bounds2D;
	import weave.utils.LinkableTextFormat;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This is a plotter for a node edge chart, commonly referred to as a graph.
	 * 
	 * @author kmonico
	 */	
	public class GraphPlotter extends AbstractPlotter
	{
		public function GraphPlotter()
		{
			lineStyle.color.internalDynamicColumn.requestLocalObjectCopy(Weave.root.getObject(Weave.DEFAULT_COLOR_COLUMN));
			lineStyle.scaleMode.defaultValue.value = LineScaleMode.NORMAL;
			lineStyle.weight.defaultValue.value = 1.5;

			fillStyle.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat); // redraw when text format changes
			setKeySource(nodesColumn);

			layoutAlgorithm.requestLocalObject(ForceDirectedLayout, true);

			init();
		}
	
		/**
		 * Initialize the algorithms array.
		 */
		public function init():void
		{
			algorithms[FORCE_DIRECTED] = ForceDirectedLayout;
			algorithms[GRID_FORCE_DIRECTED] = GridForceDirectedLayout;
			algorithms[LARGE_GRAPH_LAYOUT] = LargeGraphLayout;
			algorithms[KAMADA_KAWAI] = KamadaKawaiLayout;
			(layoutAlgorithm.internalObject as IGraphAlgorithm).initRService(Weave.properties.rServiceURL.value);
		}

		/**
		 * Recompute the positions of the nodes in the graph and then draw the plot.
		 */
		public function recomputePositions():void 
		{ 
			resetAllNodes();
			_iterations = 0;
			continueComputation(null);
		}
		
		/**
		 * Offset the x and y positions of the nodes with the corresponding keys in keys. 
		 */		
		public function updateDraggedKeys(keys:Array, dx:Number, dy:Number, runSpatialCallbacks:Boolean = true):void
		{
			(layoutAlgorithm.internalObject as IGraphAlgorithm).updateDraggedKeys(keys, dx, dy, runSpatialCallbacks);
			(layoutAlgorithm.internalObject as IGraphAlgorithm).getOutputBounds(null, tempBounds);
			if (runSpatialCallbacks)
				spatialCallbacks.triggerCallbacks();
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * Scale the positions of the nodes specified by <code>keys</code> by a factor of <code>scaleFactor</code>.
		 * @param keys The keys to scale.
		 * @param scaleFactor The scaling factor used for the spread.
		 */		
		public function scaleNodes(keys:Array, scaleFactor:Number = 2):void
		{
			var nodes:Array = [];
			var key:IQualifiedKey;
			var node:IGraphNode;
			var xCenter:Number = 0;
			var yCenter:Number = 0;
			// get the running sum of the node positions
			for each (key in keys)
			{
				node = (layoutAlgorithm.internalObject as IGraphAlgorithm).getNodeFromKey(key);
				if (!node)
					continue;
				nodes.push(node);
				xCenter += node.position.x;
				yCenter += node.position.y;
			}
			// divide by the number of nodes
			xCenter /= nodes.length;
			yCenter /= nodes.length;
			
			// xCenter and yCenter are now the center of the node cluster
			// for each node, set its new position
			for each (node in nodes)
			{
				var currPos:Point = node.position;
				var nextPos:Point = node.nextPosition;
				node.setNextPosition(
					scaleFactor * (currPos.x - xCenter) + xCenter, 
					scaleFactor * (currPos.y - yCenter) + yCenter
				);			
			}
			(layoutAlgorithm.internalObject as IGraphAlgorithm).updateOutputBounds();
			spatialCallbacks.triggerCallbacks();
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * Reset all the nodes the default circular position. 
		 */		
		public function resetAllNodes():void
		{
			(layoutAlgorithm.internalObject as IGraphAlgorithm).resetAllNodes();
			_iterations = 0;
			(layoutAlgorithm.internalObject as IGraphAlgorithm).getOutputBounds(null, tempBounds);
		}
//		/**
//		 * Set the keys to be drawn in the draggable layer.
//		 */
//		public function setDraggableLayerKeys(keys:Array):void
//		{
//			_draggedKeysArray = keys.concat();
//			if (keys.length == 0)
//			{
//				_isDragging = false;
//				return;
//			}
//			
//			_isDragging = true;
//			
//			_draggedKeysLookup = new Dictionary();
//			// for each key, add the immediate neighbor to _draggedKeys
//			for each (var key:IQualifiedKey in keys)
//			{
//				_draggedKeysLookup[key] = key;
//				var node:GraphNode = _keyToNode[key];
//				var connectedNodes:Vector.<GraphNode> = node.connections;
//				for each (var neighbor:GraphNode in connectedNodes)
//				{
//					var neighborKey:IQualifiedKey = neighbor.key;
//					if (_draggedKeysLookup[neighborKey] == undefined)
//					{
//						_draggedKeysLookup[neighborKey] = neighborKey;
//						_draggedKeysArray.push(neighborKey);
//					}
//				}
//			}
//		}
		
		/**
		 * Continue the algorithm.
		 * 
		 * @param keys The keys whose positions should be computed.
		 */
		public function continueComputation(keys:Array):void
		{
			if (!keys)
				keys = (nodesColumn).keys;
			
			algorithmRunning.value = true;
			if (!shouldStop.value)
			{
				(layoutAlgorithm.internalObject as IGraphAlgorithm).getOutputBounds(keys, tempBounds);
				(layoutAlgorithm.internalObject as IGraphAlgorithm).incrementLayout(keys, tempBounds);
			}
			shouldStop.value = false;
			algorithmRunning.value = false;
		}
		
		/**
		 * Verify the algorithm string is correct and use the corresponding function.
		 */
		private function changeAlgorithm():void
		{
			var newAlgorithm:Class = algorithms[currentAlgorithm.value];
			if (newAlgorithm == null)
				return;
			
			layoutAlgorithm.requestLocalObject(newAlgorithm, true);
			(layoutAlgorithm.internalObject as IGraphAlgorithm).initRService(Weave.properties.rServiceURL.value);
			handleColumnsChange();
			(layoutAlgorithm.internalObject as IGraphAlgorithm).setupData(
				nodesColumn, 
				edgeSourceColumn, 
				edgeTargetColumn);
			spatialCallbacks.triggerCallbacks();
			getCallbackCollection(this).triggerCallbacks();
		}

		// the styles
		public const lineStyle:SolidLineStyle = registerLinkableChild(this, new SolidLineStyle());
		public const fillStyle:SolidFillStyle = registerLinkableChild(this, new SolidFillStyle());

		// the columns
		public function get colorColumn():AlwaysDefinedColumn { return fillStyle.color; }

		public const sizeColumn:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn());
		public const nodesColumn:DynamicColumn = registerLinkableChild(this, new DynamicColumn(IAttributeColumn), handleColumnsChange);
		public const edgeSourceColumn:DynamicColumn = registerLinkableChild(this, new DynamicColumn(IAttributeColumn), handleColumnsChange);
		public const edgeTargetColumn:DynamicColumn = registerLinkableChild(this, new DynamicColumn(IAttributeColumn), handleColumnsChange);
		public const labelColumn:DynamicColumn = registerLinkableChild(this, new DynamicColumn());
		public function get edgeColorColumn():AlwaysDefinedColumn { return lineStyle.color; }
		
		// the algorithms
		[Bindable] public var algorithms:Array = [ FORCE_DIRECTED, GRID_FORCE_DIRECTED, LARGE_GRAPH_LAYOUT, KAMADA_KAWAI ];
		public const layoutAlgorithm:LinkableDynamicObject = registerSpatialProperty( new LinkableDynamicObject(IGraphAlgorithm));
		public const currentAlgorithm:LinkableString = registerLinkableChild(this, new LinkableString(FORCE_DIRECTED), changeAlgorithm); // the algorithm
		private static const FORCE_DIRECTED:String = "Force Directed";	
		private static const LARGE_GRAPH_LAYOUT:String = "Large Graph Layout";
		private static const GRID_FORCE_DIRECTED:String = "Grid Force Directed";
		private static const KAMADA_KAWAI:String = "Kamada Kawai";
		// properties
		public const radius:LinkableNumber = registerSpatialProperty(new LinkableNumber(2)); // radius of the circles
		public const shouldStop:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false)); // should the algorithm halt on the next iteration? 
		public const algorithmRunning:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false)); // is an algorithm running?
		public const drawCurvedLines:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true)); // should we draw curved lines instead of a gradient?
		
		// dragged layer properties
//		private var _draggedKeysLookup:Dictionary = new Dictionary(); 
//		private var _draggedKeysArray:Array = []; 
//		public var draggedLayerDrawn:Boolean = false;
//		private var _isDragging:Boolean = false;
		
		// clipping rectangle
		private const _clipRectangle:Rectangle = new Rectangle();

		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var nodesGraphics:Graphics = tempShape.graphics;
			var edgesGraphics:Graphics = edgesShape.graphics;
			screenBounds.getRectangle(_clipRectangle);
			nodesGraphics.clear();
			edgesGraphics.clear();
			
			if (recordKeys.length == 0)
				return;
			
			var count:int = 0;
			var key:IQualifiedKey;
			var x:Number;
			var y:Number;
			var nodesCount:int = 0;
			var edgesCount:int = 0;
			var fullyDrawnNodes:Dictionary = new Dictionary();
			var recordKeyMap:Dictionary = new Dictionary();
			
			for each (key in recordKeys)
			{
				recordKeyMap[key] = true;
			}
			
			// we need to get the neighboring keys of the given keys to draw full edges when probing 
			// and to draw edges when one node is offscreen
			var keys:Array = (layoutAlgorithm.internalObject as IGraphAlgorithm).getNeighboringKeys(recordKeys);
			// loop through each node and draw it
			for (var iKey:int = keys.length - 1; iKey >= 0; --iKey)
			{
				key = keys[iKey];
				var node:IGraphNode = (layoutAlgorithm.internalObject as IGraphAlgorithm).getNodeFromKey(key);
				if (!node)
					continue;
				var connections:Vector.<IGraphNode> = node.connections;
				
				lineStyle.beginLineStyle(key, nodesGraphics);
				nodesGraphics.beginFill(fillStyle.color.getValueFromKey(key));
				lineStyle.beginLineStyle(key, edgesGraphics);				
				
				// first draw the node
				x = node.position.x;
				y = node.position.y;
				screenPoint.x = x;     
				screenPoint.y = y;
				dataBounds.projectPointTo(screenPoint, screenBounds);
				var xNode:Number = screenPoint.x;
				var yNode:Number = screenPoint.y;
				nodesGraphics.drawCircle(xNode, yNode, radius.value);
				++nodesCount;
				
				for (var j:int = connections.length - 1; j >= 0; --j)
				{
					var connectedNode:IGraphNode = connections[j];
					var connectedNodeKey:IQualifiedKey = connectedNode.key;
					
					// don't draw connections to nodes which weren't in the record keys
					if (recordKeyMap[key] == undefined && recordKeyMap[connectedNodeKey] == undefined)
						continue;
					
					edgesGraphics.moveTo(xNode, yNode);
					x = connectedNode.position.x;
					y = connectedNode.position.y;
					screenPoint.x = x;     
					screenPoint.y = y;
					dataBounds.projectPointTo(screenPoint, screenBounds);
					
					if (!connectedNode.hasConnection(node)) // single connection
					{
						edgesGraphics.lineTo(screenPoint.x, screenPoint.y);
					}
					else // double connection
					{
						x = screenPoint.x;
						y = screenPoint.y;
						var dx:Number = x - xNode;
						var dy:Number = y - yNode;
						var dx2:Number = dx * dx;
						var dy2:Number = dy * dy;
						var xMid:Number = (xNode + x) / 2;
						var yMid:Number = (yNode + y) / 2;
						var distance:Number = Math.sqrt(dx2 + dy2);
						var radius2:Number = 0.5 * distance;
						var anchorRadius:Number = Math.max(5, Math.min(0.2 * radius2, 12));
						var angle:Number = Math.atan2(dy, dx);
						if (drawCurvedLines.value) // draw curved lines
						{
							var xAnchor:Number;
							var yAnchor:Number;
							
							angle -= Math.PI / 2; // i forget why...
							xAnchor = xMid + anchorRadius * Math.cos(angle);
							yAnchor = yMid + anchorRadius * Math.sin(angle);
							edgesGraphics.curveTo(xAnchor, yAnchor, screenPoint.x, screenPoint.y);
						}
						else // otherwise draw halfway
						{
							edgesGraphics.lineTo(xMid, yMid);
						}
					}
					++edgesCount;
				} // end connections for loop
				if (edgesCount > recordsPerDraw)
				{
					destination.draw(edgesShape, null, null, null, null, true);
					edgesGraphics.clear();
					edgesCount = 0;
				}
				nodesGraphics.endFill();
			} // end key for loop
			if (edgesCount != 0)
				destination.draw(edgesShape, null, null, null, null, true);
			destination.draw(tempShape, null, null, null, null, true);
		}

		public function get alphaColumn():AlwaysDefinedColumn { return fillStyle.alpha; }
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var bounds:IBounds2D = getReusableBounds();
			var node:IGraphNode = (layoutAlgorithm.internalObject as IGraphAlgorithm).getNodeFromKey(recordKey);
			var keyPoint:Point;
			var edgePoint:Point;
			if (node)
			{
				keyPoint = node.position;
				bounds.includePoint( keyPoint );
			}
			
			return [ bounds ];
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			var b:IBounds2D = getReusableBounds();
			(layoutAlgorithm.internalObject as IGraphAlgorithm).getOutputBounds(null, b);
			
			return b;
		}

		/**
		 * When the columns change, the columns need to be verified for valid input.
		 */		
		private function handleColumnsChange():void
		{
			if (!nodesColumn.internalObject || !edgeSourceColumn.internalObject || !edgeTargetColumn.internalObject)
				return;
			// set the keys
			setKeySource(nodesColumn);
			
			// if we don't have the required keys, do nothing
			if ((nodesColumn).keys.length == 0 || 
				(edgeSourceColumn).keys.length == 0 || 
				(edgeTargetColumn).keys.length == 0)
				return;
			if ((edgeSourceColumn).keys.length != (edgeTargetColumn).keys.length)
				return;
			
			// verify source and target column have same keytype
			var sourceKey:IQualifiedKey = (edgeSourceColumn).keys[0];
			var targetKey:IQualifiedKey = (edgeTargetColumn).keys[0];
			if (sourceKey.keyType != targetKey.keyType)
				return;
			
			// setup the lookups and objects
			(layoutAlgorithm.internalObject as IGraphAlgorithm).setupData(
				nodesColumn, 
				edgeSourceColumn, 
				edgeTargetColumn);

			_iterations = 0;
			
			// if there isn't a specified color column or if the color column's keytype differs from node column, request default
			if (fillStyle.color.keys.length == 0 || (fillStyle.color.keys[0] as IQualifiedKey).keyType != sourceKey.keyType)
				fillStyle.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
		}

		public function resetIterations(newMaxValue:int):void
		{
			_iterations = 0;
		}

		// the iterations
		private var _iterations:int = 0;
		private var _maxColorValue:Number;
		// reusable objects
		private const edgesShape:Shape = new Shape();
		
		private const screenPoint:Point = new Point(); // reusable object
		private const tempBounds:IBounds2D = new Bounds2D(); // reusable object
		

	}
}
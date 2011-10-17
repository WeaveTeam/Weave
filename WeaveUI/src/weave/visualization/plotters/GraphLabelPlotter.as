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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	
	import weave.Weave;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.graphs.IGraphAlgorithm;
	import weave.api.graphs.IGraphNode;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.graphs.DynamicGraphAlgorithm;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.ObjectPool;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;

	/**
	 * A plotter for placing and rendering labels on the graph plotter.
	 * This is a separate plotter for probing.
	 * 
	 * @author kmonico
	 */	
	public class GraphLabelPlotter extends AbstractPlotter
	{
		public function GraphLabelPlotter()
		{
			super();
			nodesColumn.addImmediateCallback(this, setKeySource, [nodesColumn], true);
		}
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// TODO Figure out why fillRect alpha isn't working
			// don't let labels overlap nodes (might need a separate KDTree to handle this)
			// dynamically place labels
			var i:int;
			var textWasDrawn:Array = [];
			var reusableBoundsObjects:Array = [];
			var bounds:IBounds2D;
			var nodes:Array = [];
			
			for (i = 0; i < recordKeys.length; ++i)
			{
				var recordKey:IQualifiedKey = recordKeys[i];
				var node:IGraphNode = (layoutAlgorithm.internalObject as IGraphAlgorithm).getNodeFromKey(recordKey);
				
				// project data coordinates to screen coordinates and draw graphics onto tempShape
				tempDataPoint.x = node.position.x;
				tempDataPoint.y = node.position.y;
				dataBounds.projectPointTo(tempDataPoint, screenBounds);

				// round to nearest pixel to get clearer text
				bitmapText.x = Math.round(tempDataPoint.x);
				bitmapText.y = Math.round(tempDataPoint.y);
				bitmapText.text = labelColumn.getValueFromKey(recordKey, String) as String;

				// init text format			
				var f:TextFormat = bitmapText.textFormat;
				f.size = Weave.properties.axisFontSize.value;
				f.color = Weave.properties.axisFontColor.value;
				f.font = Weave.properties.axisFontFamily.value;
				f.bold = Weave.properties.axisFontBold.value;
				f.italic = Weave.properties.axisFontItalic.value;
				f.underline = Weave.properties.axisFontUnderline.value;
				bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				
				// grab a bounds object to store the screen size of the bitmap text
				bounds = reusableBoundsObjects[i] = ObjectPool.borrowObject(Bounds2D);
				bitmapText.getUnrotatedBounds(bounds);
				bounds.offset(radius.value, 0);
				bitmapText.x = bounds.getXMin();
				//					bitmapText.y = bounds.getYMin();
				
				// brute force check to see if this bounds overlaps with any previous bounds
				var overlaps:Boolean = false;
				var j:int;
				for (j = 0; j < i; j++)
				{
					if (textWasDrawn[j] && bounds.overlaps(reusableBoundsObjects[j] as IBounds2D))
					{
						overlaps = true;
						break;
					}
				}

				// The code below is _TOO_ _SLOW_ to be used. With 500 nodes, this function takes 250ms+
//				for (j = 0; j < nodes.length; ++j)
//				{
//					if (bounds.overlaps((nodes[j] as IGraphNode).bounds))
//					{
//						overlaps = true;
//						break;
//					}
//				}
				
				if (overlaps)
				{
					textWasDrawn[i] = false;
					continue;
				}
				else
				{
					textWasDrawn[i] = true;
				}
				
				if (bitmapText.angle == 0)
				{
					// draw almost-invisible rectangle behind text
					bitmapText.getUnrotatedBounds(tempBounds);
					tempBounds.getRectangle(tempRectangle);
					destination.fillRect(tempRectangle, 0x02808080);
				}
				
				bitmapText.draw(destination);
			}
			for each (bounds in reusableBoundsObjects)
				ObjectPool.returnObject(bounds);
		}
		
		public function setBaseKeySource(source:IKeySet):void
		{
			setKeySource(source);
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var bounds:IBounds2D = getReusableBounds();
			
			if (!layoutAlgorithm.internalObject)
				return [ bounds ];
			
			var node:IGraphNode = (layoutAlgorithm.internalObject as IGraphAlgorithm).getNodeFromKey(recordKey);
			if (node)
				bounds.includePoint(node.position);
			
			return [ bounds ];
		}
				
		
		private function handleColumnsChange():void
		{
//			(layoutAlgorithm.internalObject as IGraphAlgorithm).setupData(nodesColumn, edgeSourceColumn, edgeTargetColumn);
		}
		
		// the styles
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fillStyle:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		
		public function get colorColumn():AlwaysDefinedColumn { return fillStyle.color; }
		public const sizeColumn:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn());
		public const nodesColumn:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn());
		public const edgeSourceColumn:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(), handleColumnsChange);
		public const edgeTargetColumn:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(), handleColumnsChange);
		public const labelColumn:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn());
		public function get edgeColorColumn():AlwaysDefinedColumn { return lineStyle.color; }
		public const radius:LinkableNumber = registerSpatialProperty(new LinkableNumber(2)); // radius of the circles
		
		public const layoutAlgorithm:LinkableDynamicObject = registerSpatialProperty(new LinkableDynamicObject(IGraphAlgorithm), handleColumnsChange);
		public const currentAlgorithm:LinkableString = registerLinkableChild(this, new LinkableString());

		private const tempRectangle:Rectangle = new Rectangle();
		private const tempDataPoint:Point = new Point(); // reusable object
		private const bitmapText:BitmapText = new BitmapText();
		private const tempBounds:IBounds2D = new Bounds2D(); // reusable object
	}
}
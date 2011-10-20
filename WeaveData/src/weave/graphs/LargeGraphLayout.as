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
	import flash.system.fscommand;
	import flash.utils.Dictionary;
	
	import mx.events.RSLEvent;
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
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveStatisticsServlet;
	import weave.services.beans.RResult;
	
	/**
	 * This is a layout algorithm for large, connected graphs. It can provide a great overall layout,
	 * but it's lacking finer details.
	 *
	 * @author kmonico
	 */
	public class LargeGraphLayout extends AbstractGraphAlgorithm implements IGraphAlgorithm
	{
		public function LargeGraphLayout()
		{
		}

		override public function incrementLayout(keys:Array, bounds:IBounds2D):void
		{
			lastUsedNodes = [];

			// load the igraph library 
			var libraryString:String = libraryCall;
			
			// create the vector of vertices
			var vectorVerticesString:String = generateVertexesString(keys);
			
			// create the subgraph
			var subGraphString:String = generateSubGraphString();

			// the string to store the graph layout
			var layoutString:String = 
				weaveGraphLayout + ' <- layout.lgl(' + 
				subGraphName + 												// graph name
				',' + _numNodes +											// num iterations 
				',' + _numNodes + 											// max delta
				',' + outputBounds.getArea() +								// area
				',' + 3 +													// cooling exp
				',' + outputBounds.getArea() * _numNodes + 					// repulsion cancellation radius
				',' + Math.sqrt(Math.sqrt(outputBounds.getArea())) + ')'; 	// cell size

				
			var rScript:String = 
				libraryString + '\n' +
				vectorVerticesString + '\n' +
				subGraphString + '\n' +
				layoutString + '\n';

			var constrainingBounds:IBounds2D = (keys.length == _numNodes) ? null : bounds;
			callRServe(rScript, [weaveGraphLayout, subGraphNodes], constrainingBounds);
		}
	}
}
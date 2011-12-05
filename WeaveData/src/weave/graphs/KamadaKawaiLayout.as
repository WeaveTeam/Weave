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
	 * This class is a layout algorithm using the PDE minimizing approach described
	 * by Kamada and Kawai. This algorithm works well for connected graphs, but may give poor or
	 * completely unusable results for disconnected graphs.
	 * 
	 * @author kmonico 
	 */	
	public class KamadaKawaiLayout extends AbstractGraphAlgorithm implements IGraphAlgorithm
	{
		public function KamadaKawaiLayout()
		{
		}

		override public function incrementLayout(keys:Array, bounds:IBounds2D):void
		{
			lastUsedNodes = [];

			// create the graph because Weave clears out R data objects
			var libraryString:String = libraryCall;
			var vectorVerticesString:String = generateVertexesString(keys);
			var edgesString:String = generateEdgesString(keys); 
			var graphString:String = generateGraphString(graphName, edgesString, vectorVerticesString);
							
			// the string to store the graph layout
			var layoutString:String = 
				weaveGraphLayout + ' <- layout.kamada.kawai(' + 
				graphName + 						// graph name
				',' + _numNodes +					// num iterations 
				',' + _numNodes / 4 +				// base STDDEV of position change
				',' + 10 + 							// initial temperature
				',' + 0.99 +						// cooling exponent
				',' + _numNodes * _numNodes + ')';	// the vertex attraction constant
				
			var rScript:String = 
				libraryString + '\n' +
				vectorVerticesString + '\n' +
				edgesString + '\n' + 
				graphString + '\n' +
				layoutString + '\n';

			var constrainingBounds:IBounds2D = (keys.length == _numNodes) ? null : bounds;
			callRServe(rScript, [weaveGraphLayout, graphNodes], constrainingBounds);
		}
	}
}
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
	import weave.api.graphs.IGraphAlgorithm;
	import weave.api.primitives.IBounds2D;
	
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

			// create the graph because Weave clears out R data objects
			var libraryString:String = libraryCall;
			var vectorVerticesString:String = generateVertexesString(keys);
			var edgesString:String = generateEdgesString(keys); 
			var graphString:String = generateGraphString(graphName, edgesString, vectorVerticesString);
							
			// the string to store the graph layout
			var layoutString:String = 
				weaveGraphLayout + ' <- layout.lgl(' + 
				graphName + 												// graph name
				',' + _numNodes +											// num iterations 
				',' + _numNodes + 											// max delta
				',' + outputBounds.getArea() +								// area
				',' + 3 +													// cooling exp
				',' + outputBounds.getArea() * _numNodes + 					// repulsion cancellation radius
				',' + Math.sqrt(Math.sqrt(outputBounds.getArea())) + ')'; 	// cell size
				
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
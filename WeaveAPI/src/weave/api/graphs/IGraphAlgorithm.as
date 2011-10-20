/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package weave.api.graphs
{
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	
	/**
	 * An interface for an algorithm for graph layout.
	 *  
	 * @author kmonico
	 */	
	public interface IGraphAlgorithm extends ICallbackCollection
	{
		/**
		 * This function should be used to initialize the data.
		 * @param nodes The column with the nodes.
		 * @param edgeSources The column of the source of the edges. Each value in this column should correspond to a node.
		 * @param edgeTargets The column of the targets of the edges. Similar to above.
		 */		
		function setupData(nodes:IAttributeColumn, edgeSources:IAttributeColumn, edgeTargets:IAttributeColumn):void;
		
		/**
		 * This function will perform one interation on the graph. 
		 * @param keys The keys to increment.
		 * @param bounds The bounds to constrain the points.
		 */		
		function incrementLayout(keys:Array, bounds:IBounds2D):void;
		
		/**
		 * Update the output bounds to include the next positions of the nodes. 
		 */
		function updateOutputBounds():void;
		
		/**
		 * Returns the bounds of the nodes.
		 * @param keys The keys whose bounds should be considered.
		 * @param output The bounds to store the result.
		 */		
		function getOutputBounds(keys:Array, output:IBounds2D):void;
		
		/**
		 * Get the IGraphNode for this key. 
		 * @param key The key to lookup.
		 * @return The IGraphNode for the key.
		 */		
		function getNodeFromKey(key:IQualifiedKey):IGraphNode;
		
		/**
		 * Reset the positions of all the IGraphNode objects. 
		 */		
		function resetAllNodes():void;
		
		/**
		 * Updates all of the nodes specified by the keys array to be offset by the dx and dy values. 
		 * @param keys The array of IQualifiedKey objects to modify.
		 * @param dx The x offset.
		 * @param dy The y offset.
		 * @param runSpatialCallbacks A boolean specifying whether to run the spatial callbacks. 
		 */		
		function updateDraggedKeys(keys:Array, dx:Number, dy:Number, runSpatialCallbacks:Boolean = true):void;
		
		/**
		 * Connects to Rserve. 
		 * @param url The url of Rserve.
		 */		
		function initRService(url:String):void;
	
		/**
		 * Gets an array of keys which contains keys in the parameter and the nearest neighbors.
		 * @param keys The filter.
		 * @return An array of IQualifiedKey objects.
		 */		
		function getNeighboringKeys(keys:Array):Array;
	}
}
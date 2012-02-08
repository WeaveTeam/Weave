/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.graphs
{
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;

	/**
	 * An interface defining a Graph Node. 
	 * @author kmonico
	 */	
	public interface IGraphNode
	{
		function get position():Point;
		function setPosition(x:Number, y:Number):void;
			
		function get id():int;
		function set id(val:int):void;
			
		function get key():IQualifiedKey;
		function set key(q:IQualifiedKey):void;
		
		function get connections():Vector.<IGraphNode>;
		function addConnection(node:IGraphNode):void;
		function removeConnection(node:IGraphNode):void;
		
		function get bounds():IBounds2D;
		
		function get label():String;
		
		function get nextPosition():Point;
		function setNextPosition(x:Number, y:Number):void;
		
		function hasConnection(otherNode:IGraphNode):Boolean;
	}
}
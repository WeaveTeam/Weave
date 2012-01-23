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

package weave.api.data
{
	/**
	 * This is an interface to a geometry object defined by an array of vertices
	 * and a type.
	 * 
	 * @author kmonico
	 */
	public interface ISimpleGeometry
	{
		/**
		 * This function will return a boolean indicating if this
		 * geometry is a line.
		 * 
		 * @return <code>True</code> if this is a line.
		 */
		function isLine():Boolean;

		/**
		 * This function will return a boolean indicating if this
		 * geometry is a point.
		 * 
		 * @return <code>True</code> if this is a point.
		 */
		function isPoint():Boolean;
		
		/**
		 * This function will return a boolean indicating if this
		 * geometry is a polygon.
		 * 
		 * @return <code>True</code> if this is a polygon.
		 */
		function isPolygon():Boolean;
		
		/**
		 * Get the vertices.
		 */
		function getVertices():Array;
		
		/**
		 * Set the vertices.
		 * 
		 * @param An array of objects with x and y properties. 
		 */		
		function setVertices(o:Array):void;
		
	}
}
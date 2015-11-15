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

package weavejs.api.ui
{
	import flash.display.Graphics;
	
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.IQualifiedKey;

	/**
	 * A class implementing ILineStyle defines the properties required to set line styles corresponding to record keys.
	 * This interface is meant to be as lightweight and generic as possible.
	 * 
	 * @author adufilie
	 */
	public interface ILineStyle extends ILinkableObject
	{
		/**
		 * This will set the line style on the specified Graphics object using the properties saved in this class.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 */
		function beginLineStyle(recordKey:IQualifiedKey, target:Graphics):void;
	}
}

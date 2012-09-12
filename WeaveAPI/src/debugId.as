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

package
{
	import flash.utils.getQualifiedClassName;

	/**
	 * This function generates or returns a previously generated identifier for an object.
	 * @author adufilie
	 */
	public function debugId(object:Object):String
	{
		var type:String = typeof(object);
		if (object == null || type != 'object' && type != 'function')
			return String(object);
		return $.lookup[object]
			|| ($.lookup[object] = getQualifiedClassName(object).split(':').pop() + $.i++);
	}
}

import flash.utils.Dictionary;

internal class $
{
	public static var i:uint = 0;
	public static var lookup:Dictionary = new Dictionary(true);
}

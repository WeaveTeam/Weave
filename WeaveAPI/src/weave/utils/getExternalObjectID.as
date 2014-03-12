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

package weave.utils
{
	import flash.external.ExternalInterface;

	/**
	 * A way to get a Flash application's external object ID when ExternalInterface.objectID is null.
	 * @param desiredId If the flash application really has no id, this will be used as a base for creating a new unique id.
	 * @return The id of the flash application.
	 * @author adufilie
	 */
	public function getExternalObjectID(desiredId:String = null):String
	{
		var id:String = ExternalInterface.objectID;
		if (!id) // if we don't know our ID
		{
			// generate an ID
			id = new Date() + ' ' + Math.random();
			// use addCallback() to add a property to the flash component that will allow us to be found 
			ExternalInterface.addCallback(id, trace);
			// find the element with the unique property name and get its ID (or set the ID if it doesn't have one)
			id = ExternalInterface.call(
				"function(uid, newId){\
					while (document.getElementById(newId))\
						newId += '_';\
					var elements = document.getElementsByTagName('*');\
					for (var i in elements)\
						if (elements[i][uid])\
							return elements[i].id || (elements[i].id = newId);\
				}",
				id,
				desiredId || id
			);
		}
		return id;
	}
}

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

package weave.api.core
{
	/**
	 * This class is a central location for reporting and detecting errors.
	 * The callbacks for the IErrorManager get called when an error is reported.
	 * 
	 * @author adufilie
	 */
	public interface IErrorManager extends ILinkableObject
	{
		/**
		 * This function is intended to be the global error reporting mechanism for Weave.
		 * @param error An Error or a String describing the error.
		 * @param faultMessage A message associated with the error, if any.  If specified, the error will be wrapped in a Fault object.
		 * @param faultCessage Content associated with the error, if any.  If specified, the error will be wrapped in a Fault object.
		 */
		function reportError(error:Object, faultMessage:String = null, faultContent:Object = null):void;
		
		/**
		 * This is the list of all previously reported errors.
		 */
		function get errors():Array;
	}
}

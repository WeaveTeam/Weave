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

package org.oicweave.core
{
	import org.oicweave.core.CallbackCollection;
	import org.oicweave.core.SessionManager;
	import org.oicweave.api.core.ICallbackCollection;
	
	/**
	 * This class is a central location for reporting and detecting errors.
	 * 
	 * @author adufilie
	 */
	public class ErrorManager
	{
		//These callbacks get called when an error is reported.
		public static const callbacks:ICallbackCollection = new CallbackCollection();
		//This is the list of all previous errors.
		public static const errors:Array = new Array();
		
		/**
		 * This function is intended to be the global error reporting mechanism for Weave.
		 */
		public static function reportError(error:Error):void
		{
			if (SessionManager.runningDebugFlashPlayer)
			{
				//throw error; // COMMENT THIS OUT WHEN NOT DEVELOPING
				trace(error.getStackTrace() + "\n");
			}
			
			errors.push(error);
			callbacks.triggerCallbacks();
		}
	}
}

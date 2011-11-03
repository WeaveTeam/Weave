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

package weave.core
{
	import flash.system.Capabilities;
	
	import weave.api.core.IErrorManager;
	import weave.api.getCallbackCollection;
	import weave.core.SessionManager;
	
	/**
	 * This class is a central location for reporting and detecting errors.
	 * The callbacks for this object get called when an error is reported.
	 * 
	 * @author adufilie
	 */
	public class ErrorManager implements IErrorManager
	{
		private var _errors:Array = [];
		
		/**
		 * This is the list of all previous errors.
		 */
		public function get errors():Array
		{
			return _errors;
		}
		
		/**
		 * This function is intended to be the global error reporting mechanism for Weave.
		 */
		public function reportError(error:Error):void
		{
			if (Capabilities.isDebugger)
			{
				//throw error; // COMMENT THIS OUT WHEN NOT DEVELOPING
				trace(error.getStackTrace() + "\n");
			}
			
			errors.push(error);
			getCallbackCollection(this).triggerCallbacks();
		}
	}
}

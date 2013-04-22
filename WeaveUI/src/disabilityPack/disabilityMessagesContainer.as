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
package disabilityPack
{
	
	/** 
	 * @mervetuccar
	 */
	public class disabilityMessagesContainer
	{
		public var messageContainer:Array = new Array();
		
		public function disabilityMessagesContainer()
		{
			
			var mDisabilityMessage:disabilityMessage = new disabilityMessage("is a stable trend", "is a stable trend", -5, 5);
			messageContainer.push(mDisabilityMessage);
			mDisabilityMessage = new disabilityMessage("is a slightly falling trend","is a slightly increasing trend", -30, 30);
			messageContainer.push(mDisabilityMessage);
			mDisabilityMessage = new disabilityMessage("is a falling trend", "is an increasing trend", -60, 60);
			messageContainer.push(mDisabilityMessage);
			mDisabilityMessage = new disabilityMessage("is a sharp falling trend", "is a sharp increasing trend", -90, 90);
			messageContainer.push(mDisabilityMessage);
						
			}			
		}
}

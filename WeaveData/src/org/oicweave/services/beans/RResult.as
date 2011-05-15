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
package org.oicweave.services.beans
{
	
	/**
	 * Object to store result obtained from R for user generated script
	 * 
	 * @author spurushe
	 * @author sanbalag
	 */
	
	public class RResult
	{
		public var name:String = null;
		public var value:Object = null;
		
		public function RResult(rResult:Object)
		{
			this.name = rResult.name;				
			this.value = rResult.value;			
		}
	}
}
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

package weave.services.beans
{
	public class ConnectionInfo
	{
		[Bindable] public var name:String = "";
		[Bindable] public var dbms:String = "";
		[Bindable] public var ip:String = "";
		[Bindable] public var port:String = "";
		[Bindable] public var database:String = "";
		[Bindable] public var user:String = "";
		[Bindable] public var pass:String = "";
		[Bindable] public var privileges:String = "";
		
		public function ConnectionInfo(obj:Object)
		{
			for (var name:String in obj)
				if (this.hasOwnProperty(name))
					this[name] = obj[name];

			if (ip == '')
				ip = 'localhost';
			
			var defaultPorts:Object = { mysql:'3306', postgresql:'5432' };
			if (port == '')
				port = defaultPorts[dbms.toLowerCase()];
		}
	}
}
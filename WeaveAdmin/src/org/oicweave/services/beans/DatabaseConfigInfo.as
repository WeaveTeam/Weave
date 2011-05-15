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
	public class DatabaseConfigInfo
	{
		[Bindable] public var connection:String = "";
		[Bindable] public var schema:String = "";
		[Bindable] public var geometryConfigTable:String = "";
		[Bindable] public var dataConfigTable:String = "";
		
		public function DatabaseConfigInfo(obj:Object)
		{
			if (obj == null)
			{
				schema = 'weave';
				geometryConfigTable = 'config_geometry';
				dataConfigTable = 'config_data';
			}
			else
			{
				for (var name:String in obj)
					if (this.hasOwnProperty(name))
						this[name] = obj[name];
			}
		}
	}
}
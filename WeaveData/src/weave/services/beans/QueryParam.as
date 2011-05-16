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
	/**
	 * QueryParam
	 * This object represents a named parameter to a function.
	 * 
	 * @author adufilie
	 */
	public class QueryParam
	{
		public function QueryParam(name:String, value:String)
		{
			this.name = name;
			this.value = value;
		}
		public var name:String;
		public var value:String;
		
		public function toString():String
		{
			return name + "=" + value;
		}
		
		/**
		 * convertParamsObjectToQueryParamArray
		 * A params object is easier to deal with in flex, but a params array is used
		 * as the webservice parameter type.  This function provides a translation.
		 * @param params An object like {year: "1994"}
		 * @return An Array of QueryParam objects mapping variable names to string values.
		 */
		public static function convertParamsObjectToQueryParamArray(params:Object):Array
		{
			var paramsList:Array = [];
			if (params != null)
				for (var name:String in params)
					paramsList.push(new QueryParam(name, params[name]));
			return paramsList;
		}
	}
}

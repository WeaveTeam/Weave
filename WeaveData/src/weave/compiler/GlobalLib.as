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

package weave.compiler
{
	import flash.system.ApplicationDomain;
	import flash.utils.getQualifiedClassName;

	/**
	 * This provides a set of static functions for use with the Weave Compiler.
	 * This set of functions allows access to almost any object, so it should be used with care when exposing these functions to users.
	 * 
	 * @author adufilie
	 */
	public dynamic class GlobalLib
	{
		{
			GlobalLib['Class'] = function(value:*):Class {
				if (value is Class)
					return value;
				if (!(value is String))
					value = getQualifiedClassName(value);
				if (value is String)
				{
					var domain:ApplicationDomain = ApplicationDomain.currentDomain;
					if (domain.hasDefinition(value))
						return domain.getDefinition(value) as Class;
				}
				return null;
			};
		}
	}
}

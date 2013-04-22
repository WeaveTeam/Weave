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

package weave.utils;

import java.util.Collection;


/**
 * @author pkovac
 * @author adufilie
 */
public class StringUtils
{
	public static boolean isEmpty(String str)
	{
		return str == null || str.length() == 0;
	}
	public static String join(String separator, Object[] items)
	{
	    StringBuilder result = new StringBuilder((separator.length()+1)*items.length);
	    for (int i = 0; i < items.length; i++)
	    {
	        if (i > 0)
	        	result.append(separator);
	        result.append(items[i].toString());
	    }
	    return result.toString();
	}
	public static String join(String separator, Collection<?> items)
	{
		StringBuilder result = new StringBuilder((separator.length()+1)*items.size());
		int i = 0;
		for (Object item : items)
		{
			if (i > 0)
				result.append(separator);
			result.append(item.toString());
			i++;
		}
		return result.toString();
	}
	public static String mult(String separator, String item, Integer repeat)
	{
		StringBuilder out = new StringBuilder();
	    for (int i = 0; i < repeat; i++)
	    {
	    	if (i > 0)
	    		out.append(separator);
	    	out.append(item);
	    }
	    return out.toString();
	}
}

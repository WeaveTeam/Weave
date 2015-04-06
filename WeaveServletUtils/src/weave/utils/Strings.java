/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.utils;

import java.util.Collection;


/**
 * @author pkovac
 * @author adufilie
 */
public class Strings
{
	public static boolean equal(String a, String b)
	{
		if (a == null || b == null)
			return a == b;
		return a.equals(b);
	}
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

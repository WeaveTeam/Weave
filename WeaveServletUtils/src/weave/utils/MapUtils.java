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

import java.util.HashMap;
import java.util.Map;

import java.lang.IllegalArgumentException;

/**
 * @author adufilie
 */
public class MapUtils
{
	/**
	 * @param pairs A list of Key-value pairs, like [key1,value1,key2,value2,...]
	 */
	public static <K,V> Map<K,V> fromPairs(Object ...pairs)
    {
    	Map<K,V> map = new HashMap<K,V>(pairs.length / 2);
    	putPairs(map, pairs);
    	return map;
    }
	
	/**
	 * @param pairs A list of Key-value pairs, like [key1,value1,key2,value2,...]
	 */
	@SuppressWarnings("unchecked")
	public static <K,V> void putPairs(Map<K,V> map, Object ...pairs)
	{
		for (int i = 1; i < pairs.length; i += 2)
			map.put((K)pairs[i - 1], (V)pairs[i]);
	}
	
	@SuppressWarnings({ "rawtypes", "unchecked" })
	public static <T> T getValue(Map map, String key, T defaultValue)
	{
		if (map.containsKey(key))
			return (T)map.get(key);
		return defaultValue;
	}
	public static <K,V> Map<K,V> fromArrays(K[] keys, V[] values) throws IllegalArgumentException
    {
        if (keys.length != values.length)
        {
            throw new IllegalArgumentException("Arrays have mismatched lengths");
        }
        Map<K,V> result = new HashMap<K,V>(keys.length);
        for (int i = 0; i < keys.length; i++)
        {
            result.put(keys[i], values[i]);
        }
        return result;
    }
}

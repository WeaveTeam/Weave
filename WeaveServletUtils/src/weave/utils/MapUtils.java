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

import java.util.HashMap;
import java.util.Map;

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
}

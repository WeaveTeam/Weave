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
import java.util.Map.Entry;

public class MyEntry<K, V> implements Entry<K, V>
{
    private final K key;
    private V value;
    public MyEntry(final K key)
    {
        this.key = key;
    }
    public MyEntry(final K key, final V value)
    {
        this.key = key;
        this.value = value;
    }
    public K getKey()
    {
        return key;
    }
    public V getValue()
    {
        return value;
    }
    public V setValue(final V value)
    {
        final V oldValue = this.value;
        this.value = value;
        return oldValue;
    }
    
    @SuppressWarnings("unchecked")
	public static <K,V> Map<K,V> mapFromPairs(Object ... pairs)
    {
    	Map<K,V> map = new HashMap<K,V>();
    	for (int i = 1; i < pairs.length; i += 2)
    		map.put((K)pairs[i - 1], (V)pairs[i]);
    	return map;
    }
}

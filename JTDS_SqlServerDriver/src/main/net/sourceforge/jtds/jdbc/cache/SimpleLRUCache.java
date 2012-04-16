// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2004 The jTDS Project
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
package net.sourceforge.jtds.jdbc.cache;

import java.util.HashMap;
import java.util.LinkedList;

/**
 * Simple LRU cache for any type of object. Implemented as an extended
 * <code>HashMap</code> with a maximum size and an aggregated <code>List</code>
 * as LRU queue.
 *
 * @author Brett Wooldridge
 * @version $Id: SimpleLRUCache.java,v 1.1 2005-04-25 11:46:56 alin_sinpalean Exp $
 */
public class SimpleLRUCache extends HashMap {
    /** Maximum cache size. */
    private final int maxCacheSize;
    /** LRU list. */
    private final LinkedList list;

    /**
     * Constructs a new LRU cache instance.
     *
     * @param maxCacheSize the maximum number of entries in this cache before
     *                     entries are aged off
     */
    public SimpleLRUCache(int maxCacheSize) {
        super(maxCacheSize);
        this.maxCacheSize = Math.max(0, maxCacheSize);
        this.list = new LinkedList();
    }

    /**
     * Overrides clear() to also clear the LRU list.
     */
    public synchronized void clear() {
        super.clear();
        list.clear();
    }

    /**
     * Overrides <code>put()</code> so that it also updates the LRU list.
     *
     * @param key   key with which the specified value is to be associated
     * @param value value to be associated with the key
     * @return previous value associated with key or <code>null</code> if there
     *         was no mapping for key; a <code>null</code> return can also
     *         indicate that the cache previously associated <code>null</code>
     *         with the specified key
     * @see java.util.Map#put(Object, Object)
     */
    public synchronized Object put(Object key, Object value) {
        if (maxCacheSize == 0) {
            return null;
        }

        // if the key isn't in the cache and the cache is full...
        if (!super.containsKey(key) && !list.isEmpty() && list.size() + 1 > maxCacheSize) {
            Object deadKey = list.removeLast();
            super.remove(deadKey);
        }

        freshenKey(key);
        return super.put(key, value);
    }

    /**
     * Overrides <code>get()</code> so that it also updates the LRU list.
     *
     * @param key key with which the expected value is associated
     * @return the value to which the cache maps the specified key, or
     *         <code>null</code> if the map contains no mapping for this key
     */
    public synchronized Object get(Object key) {
        Object value = super.get(key);
        if (value != null) {
            freshenKey(key);
        }
        return value;
    }

    /**
     * @see java.util.Map#remove(Object)
     */
    public synchronized Object remove(Object key) {
        list.remove(key);
        return super.remove(key);
    }

    /**
     * Moves the specified value to the top of the LRU list (the bottom of the
     * list is where least recently used items live).
     *
     * @param key key of the value to move to the top of the list
     */
    private void freshenKey(Object key) {
        list.remove(key);
        list.addFirst(key);
    }
}

//jTDS JDBC Driver for Microsoft SQL Server and Sybase
//Copyright (C) 2004 The jTDS Project
//
//This library is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public
//License as published by the Free Software Foundation; either
//version 2.1 of the License, or (at your option) any later version.
//
//This library is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public
//License along with this library; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
package net.sourceforge.jtds.jdbc.cache;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;

import net.sourceforge.jtds.jdbc.ProcEntry;

/**
 * LRU cache for procedures and statement handles.
 *
 * @version $Id: ProcedureCache.java,v 1.5 2005-07-05 16:44:25 alin_sinpalean Exp $
 */
public class ProcedureCache implements StatementCache {

    /**
     * Encapsulates the cached Object and implements the linked list used to
     * implement the LRU logic.
     */
    private static class CacheEntry {
        String key;
        ProcEntry value;
        CacheEntry next;
        CacheEntry prior;

        /**
         * Constructs a new cache entry encapsulating the supplied key and
         * value.
         *
         * @param key   key used to identify the cache entry
         * @param value object being cached
         */
        CacheEntry(String key, ProcEntry value) {
            this.key = key;
            this.value = value;
        }

        /**
         * Unlinks this CacheEntry from the linked list.
         */
        void unlink() {
            next.prior = prior;
            prior.next = next;
        }

        /**
         * Links this CacheEntry into the linked list after the node specified.
         *
         * @param ce node after which this entry will be linked
         */
        void link(CacheEntry ce) {
            next = ce.next;
            prior = ce;
            next.prior = this;
            ce.next = this;
        }
    }

    /** The maximum initial HashMap size. */
    private static final int MAX_INITIAL_SIZE = 50;
    /** The actual cache instance. */
    private HashMap cache;
    /** Maximum cache size or 0 to disable. */
    int cacheSize;
    /** Head node of the linked list. */
    CacheEntry head;
    /** Tail node of the linked list. */
    CacheEntry tail;
    /** List of redundant cache entries. */
    ArrayList free;

    /**
     * Constructs a new statement cache.
     *
     * @param cacheSize maximum cache size or 0 to disable caching
     */
    public ProcedureCache(int cacheSize) {
        this.cacheSize = cacheSize;
        cache = new HashMap(Math.min(MAX_INITIAL_SIZE, cacheSize) + 1);
        head  = new CacheEntry(null, null);
        tail  = new CacheEntry(null, null);
        head.next = tail;
        tail.prior = head;
        free = new ArrayList();
    }

    /**
     * Retrieves a ProcEntry object from the cache.
     * <p/>
     * If the entry exists it is moved to the front of the linked list to keep
     * it alive as long as possible.
     *
     * @param key the key value identifying the required entry
     * @return the keyed entry as an <code>Object</code> or null if the entry
     *         does not exist
     */
    public synchronized Object get(String key) {
        CacheEntry ce = (CacheEntry) cache.get(key);
        if (ce != null) {
            // remove entry from linked list
            ce.unlink();
            // Relink at Head
            ce.link(head);
            // Increment usage count
            ce.value.addRef();

            return ce.value;
        }
        return null;
    }

    /**
     * Inserts a new entry, identified by a key, into the cache.
     * <p/>
     * If the cache is full then one or more entries are removed and
     * transferred to a list for later destruction.
     *
     * @param key    value used to identify the entry
     * @param handle proc entry to be inserted into the cache
     */
    public synchronized void put(String key, Object handle) {
        // Increment usage count
        ((ProcEntry) handle).addRef();

        // Add new entry to cache
        CacheEntry ce = new CacheEntry(key, (ProcEntry) handle);
        cache.put(key, ce);
        ce.link(head);

        // See if we need to scavenge some existing entries
        scavengeCache();
    }

    /**
     * Removes a redundant entry from the cache.
     *
     * @param key value that identifies the cache entry
     */
    public synchronized void remove(String key) {
        CacheEntry ce = (CacheEntry) cache.get(key);
        if (ce != null) {
            // remove entry from linked list
            ce.unlink();
            // Remove from HashMap
            cache.remove(key);
        }
    }

    /**
     * Obtains a list of statement handles or procedures that can now be
     * dropped.
     *
     * @param handles a collection of single use statements that will be
     *                returned for dropping if the cache is disabled
     * @return the collection of redundant statments for dropping
     */
    public synchronized Collection getObsoleteHandles(Collection handles) {
        if (handles != null) {
            // Update the usage count for handles belonging to statements
            // that are being closed.
            for (Iterator iterator = handles.iterator(); iterator.hasNext();) {
                ProcEntry handle = (ProcEntry) iterator.next();
                handle.release();
            }
        }

        // Scavenge some existing entries
        scavengeCache();

        if (free.size() > 0) {
            // There are redundant entries to drop
            Collection list = free;
            free = new ArrayList();
            return list;
        } else {
            // Nothing to do this time
            return null;
        }
    }

    /**
     * Removes unused entries trying to bring down the cache to the requested
     * size. The removed entries are placed in the {@link #free} list.
     * <p/>
     * <b>Note:</b> entries that are in use will not be removed so it is
     * possible for the cache to still be larger than {@link #cacheSize} after
     * the call finishes.
     */
    private void scavengeCache() {
        CacheEntry ce = tail.prior;
        while (ce != head && cache.size() > cacheSize) {
            if (ce.value.getRefCount() == 0) {
                // remove entry from linked list
                ce.unlink();
                // Add to free list for reclaiming
                free.add(ce.value);
                // Remove from HashMap
                cache.remove(ce.key);
            }
            ce = ce.prior;
        }
    }
}

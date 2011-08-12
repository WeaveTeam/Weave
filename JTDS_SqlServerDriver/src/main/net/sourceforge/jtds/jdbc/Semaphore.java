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
package net.sourceforge.jtds.jdbc;

/**
 * Simple semaphore class used to serialize access requests over the network
 * connection.
 * <p/>
 * Based on the code originally written by Doug Lea. Once JDK 1.5 is the
 * standard this class can be replaced by the
 * <code>java.util.concurrent.Sempahore</code> class.
 *
 * @author  Mike Hutchinson
 * @version $Id: Semaphore.java,v 1.1 2004-12-20 15:51:17 alin_sinpalean Exp $
 */
public class Semaphore {
    /**
     * Current number of available permits.
     */
    protected long permits;

    /**
     * Create a Semaphore with the given initial number of permits. Using a
     * seed of one makes the semaphore act as a mutual exclusion lock. Negative
     * seeds are also allowed, in which case no acquires will proceed until the
     * number of releases has pushed the number of permits past 0.
     */
    public Semaphore(long initialPermits) {
        permits = initialPermits;
    }

    /**
     * Wait until a permit is available, and take one.
     */
    public void acquire() throws InterruptedException {
        if (Thread.interrupted()) {
            throw new InterruptedException();
        }

        synchronized (this) {
            try {
                while (permits <= 0) {
                    wait();
                }
                --permits;
            } catch (InterruptedException ex) {
                notify();
                throw ex;
            }
        }
    }

    /**
     * Wait at most msecs millisconds for a permit.
     */
    public boolean attempt(long msecs) throws InterruptedException {
        if (Thread.interrupted()) {
            throw new InterruptedException();
        }

        synchronized (this) {
            if (permits > 0) {
                --permits;
                return true;
            } else if (msecs <= 0) {
                return false;
            } else {
                try {
                    long startTime = System.currentTimeMillis();
                    long waitTime = msecs;

                    while (true) {
                        wait(waitTime);

                        if (permits > 0) {
                            --permits;
                            return true;
                        } else {
                            waitTime = msecs - (System.currentTimeMillis() - startTime);
                            if (waitTime <= 0) {
                                return false;
                            }
                        }
                    }
                } catch (InterruptedException ex) {
                    notify();
                    throw ex;
                }
            }
        }
    }

    /**
     * Release a permit.
     */
    public synchronized void release() {
        ++permits;
        notify();
    }

    /**
     * Release N permits. <code>release(n)</code> is equivalent in effect to:
     * <pre>
     *   for (int i = 0; i < n; ++i) release();
     * </pre>
     * <p/>
     * But may be more efficient in some semaphore implementations.
     *
     * @exception IllegalArgumentException if n is negative
     */
    public synchronized void release(long n) {
        if (n < 0) {
            throw new IllegalArgumentException("Negative argument");
        }

        permits += n;
        for (long i = 0; i < n; ++i) {
            notify();
        }
    }

    /**
     * Return the current number of available permits. Returns an accurate, but
     * possibly unstable value, that may change immediately after returning.
     */
    public synchronized long permits() {
        return permits;
    }
}

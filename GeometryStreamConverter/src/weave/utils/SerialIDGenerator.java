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

/**
 * @author adufilie
 */
public class SerialIDGenerator
{
	private int nextID = 0;
	/**
	 * Allocates a single ID
	 * @return A new ID
	 */
	public synchronized int getNext()
	{
		return nextID++;
	}
	/**
	 * Allocates a range of IDs.
	 * @param allocate The number of IDs to allocate.
	 * @return A new ID.  The additional IDs will be allocated in succession to this one.  The last ID allocated will be (result + allocate - 1).
	 */
	public synchronized int getNext(int allocate)
	{
		if (allocate < 1)
			return -1;
		return nextID += allocate;
	}
}

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

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

package weave.servlets;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * Represents an R object that is not converted to Java types when returned.
 * The object is cached in the R environment.
 */
public class JRIOpaque {

	/** Name of the cache variable. */
	public static final String name = "mycache";
	private static AtomicInteger counter = new AtomicInteger();
	private int id;

	/** Creates opaque with unique id. */
	JRIOpaque() {
		id = counter.incrementAndGet();
	}

	public String toString() {
		return name + "[[" + id + "]]";
	}

}

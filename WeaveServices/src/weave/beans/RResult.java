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

package weave.beans;

public class RResult
{
	public RResult()
	{
	}
	public RResult(String name, Object value)
	{
		this.name = name;
		this.value = value;
	}
	
	public String toString() { return "name :" + name + "  value:" + value ;}
	
	private String name;
	public String getName() { return name; }
	public void setName(String name) { this.name = name; }

	private Object value;
	public Object getValue() { return value; }
	public void setValue(Object value) { this.value = value; }
}

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

import java.util.Map;

public class WeaveRecordList
{
	// this is a list of columns that were used to get the values in this record
	public Map<String,String>[] attributeColumnMetadata = null;
	
	// this is the keyType of the keys in recordKeys.
	public String keyType = null;
	
	// this is a list of the record identifiers that correspond to the rows in recordData.
	public String[] recordKeys = null;
	
	// this is a 2D table of data.
	// the column index corresponds to the index in attributeColumnMetadata.
	// the row index corresponds to the index in recordKeys.
	public Object[][] recordData = null;
}

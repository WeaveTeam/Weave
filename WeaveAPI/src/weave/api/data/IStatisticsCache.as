/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.data
{
	/**
	 * This is an interface for getting cached numerical statistics on columns.
	 * 
	 * @author adufilie
	 */
	public interface IStatisticsCache
	{
		/**
		 * This will retrieve a reusable IColumnStatistics object responsible for reporting statistics from an IAttributeColumn.
		 * @param column A column to get statistics for.
		 * @return An IColumnStatistics object for the specified column.
		 */
		function getColumnStatistics(column:IAttributeColumn):IColumnStatistics;
	}
}

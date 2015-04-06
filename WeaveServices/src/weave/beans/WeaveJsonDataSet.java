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

import java.util.HashMap;
import java.util.Map;

import weave.config.DataConfig.DataType;
import weave.config.DataConfig.PublicMetadata;

/**
 * Below is an example JSON representation of a WeaveJsonDataSet object.
 * This example illustrates the need to specify keyType by showing that record keys referring
 * to different things can have identical string representations ("25" could refer to a state or a person).
 * <pre><code>
 * {
 *    columns: {
 *       "22": {"title": "State name", "keyType": "state fips", "dataType": "string"},
 *       "23": {"title": "Population", "year": "2000", "keyType": "state fips", "dataType": "number"},
 *       "71": {"title": "Name", "keyType": "person id", "dataType": "string"},
 *       "72": {"title": "Age", "keyType": "person id", "dataType": "number"},
 *       "73": {"title": "State", "keyType": "person id", "dataType": "state fips"}
 *    },
 *    records: {
 *       "state fips": {
 *          "01": {"22": "Alabama", "23": 4452000},
 *          "09": {"22": "Connecticut", "23": 3412000},
 *          "25": {"22": "Massachusetts", "23": 3636000},
 *          "37": {"22": "North Carolina", "23": 8080000}
 *       },
 *       "person id": {
 *          "25": {"71": "Alice", "72": 31, "73": "01"},
 *          "22": {"71": "Bob", "72": 43, "73": "09"},
 *          "37": {"71": "Cindy", "72": 23, "73": "01"},
 *          "73": {"71": "Dave", "72": 60, "73": "25"},
 *          "5": {"71": "Eugene", "72": 38, "73": "25"}
 *       }
 *    }
 * }
 * </code></pre>
 */
public class WeaveJsonDataSet
{
	/**
	 * This maps a Weave entity id to a hash map containing its public metadata.
	 * In other words, a two-tiered mapping: columnId -> metaName -> metaValue
	 */
	public ColumnMetadataMap columns;
	
	/**
	 * This is a three-tiered mapping of data: keyType -> localName -> columnId -> value
	 */
	public QualifiedKeyRecordMap records;
	
	/**
	 * This will add all the data from an AttributeColumnData object.
	 * Columns configured for the dimension slider are not supported.
	 * @param columnData
	 */
	public void addColumnData(AttributeColumnData columnData)
	{
		if (columns == null)
			columns = new ColumnMetadataMap();
		if (records == null)
			records = new QualifiedKeyRecordMap();
		
		// streaming geometry columns not supported
		if (columnData.data == null)
			return;
		// dimension slider hack not supported
		if (columnData.thirdColumn != null)
			return;
		
		int columnId = columnData.id;
		columns.put(columnId, columnData.metadata);
		
		if (!columnData.metadata.containsKey(PublicMetadata.KEYTYPE))
			columnData.metadata.put(PublicMetadata.KEYTYPE, DataType.STRING);
		
		String keyType = columnData.metadata.get(PublicMetadata.KEYTYPE);
		KeyRecordMap krm = records.get(keyType);
		if (krm == null)
			records.put(keyType, krm = new KeyRecordMap());
		
		for (int i = columnData.data.length; i-- > 0;)
		{
			String localName = columnData.keys[i];
			Record record = krm.get(localName);
			if (record == null)
				krm.put(localName, record = new Record());
			
			record.put(columnId, columnData.data[i]);
		}
	}
	
	public static class ColumnMetadataMap extends HashMap<Integer, Map<String,String>>
	{
		private static final long serialVersionUID = 1L;
	}
	public static class QualifiedKeyRecordMap extends HashMap<String,KeyRecordMap>
	{
		private static final long serialVersionUID = 1L;
	}
	public static class KeyRecordMap extends HashMap<String,Record>
	{
		private static final long serialVersionUID = 1L;
	}
	public static class Record extends HashMap<Integer,Object>
	{
		private static final long serialVersionUID = 1L;
	}
}

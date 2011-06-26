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

package weave.servlets;

import java.io.IOException;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.AttributeColumnDataWithKeys;
import weave.beans.DataServiceMetadata;
import weave.beans.DataTableMetadata;
import weave.beans.GeometryStreamMetadata;
import weave.beans.WeaveRecordList;
import weave.reports.WeaveReport;
import weave.servlets.GenericServlet;
import weave.utils.DebugTimer;
import weave.utils.ListUtils;
import weave.utils.SQLResult;
import weave.config.ISQLConfig;
import weave.config.SQLConfigManager;
import weave.config.SQLConfigUtils;
import weave.config.ISQLConfig.AttributeColumnInfo;
import weave.config.ISQLConfig.GeometryCollectionInfo;
import weave.config.ISQLConfig.AttributeColumnInfo.DataType;
import weave.config.ISQLConfig.AttributeColumnInfo.Metadata;
import weave.geometrystream.SQLGeometryStreamReader;

/**
 * This class connects to a database and gets data
 * uses xml configuration file to get connection/query info
 * 
 * @author Andy Dufilie
 */
public class DataService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	private SQLConfigManager configManager;
	
	public DataService()
	{
	}
	
	/**
	 * This constructor is for testing only.
	 * @param configManager
	 */
	public DataService(SQLConfigManager configManager)
	{
		this.configManager = configManager;
	}

	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		configManager = SQLConfigManager.getInstance(config.getServletContext());
	}
	
	public DataServiceMetadata getDataServiceMetadata()
		throws RemoteException
	{
		configManager.detectConfigChanges();
		// encoding method is set to null here because we don't know what format it will be converted to later
		ISQLConfig config = configManager.getConfig();
		return new DataServiceMetadata(
		        config.getServerName(),
		        config.getDataTableNames(null).toArray(new String[0]),
		        config.getGeometryCollectionNames(null).toArray(new String[0])
		    );
	}
	
	@SuppressWarnings("unchecked")
	public DataTableMetadata getDataTableMetadata(String dataTableName)
		throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		
		if (dataTableName == null || dataTableName.length() == 0)
			return null;
		
		boolean geometryCollectionExists = ListUtils.findString(dataTableName, config.getGeometryCollectionNames(null)) >= 0;
		List<AttributeColumnInfo> infoList = config.getAttributeColumnInfo(dataTableName);
		if (infoList.size() == 0 && !geometryCollectionExists)
			throw new RemoteException("DataTable \""+dataTableName+"\" does not exist.");
		
		Map<String,String>[] metadata = new Map[infoList.size()];
		for (int i = 0; i < infoList.size(); i++)
			metadata[i] = infoList.get(i).metadata; // everything in metadata is public (no SQL info)
		
		// prepare result object
		DataTableMetadata result = new DataTableMetadata();
		
		result.setGeometryCollectionExists(geometryCollectionExists);
		if (geometryCollectionExists)
		{
			GeometryCollectionInfo info = config.getGeometryCollectionInfo(dataTableName);
			
			result.setGeometryCollectionKeyType(info.keyType);
			result.setGeometryCollectionProjectionSRS(info.projection);
		}
		result.setColumnMetadata(metadata);

		return result;
	}
	
	@SuppressWarnings("unchecked")
	public WeaveRecordList getRows(String keyType, String[] keysArray) throws RemoteException
	{
		List<String> keys = new ArrayList<String>();
		keys = ListUtils.copyArrayToList(keysArray, keys);
		HashMap<String,String> params = new HashMap<String,String>();
		params.put(AttributeColumnInfo.Metadata.KEYTYPE.toString(),keyType);
		
		HashMap<String,Integer> keyMap = new HashMap<String,Integer>();
		for(int keyIndex =0; keyIndex < keysArray.length; keyIndex ++ ){
			keyMap.put( keysArray[keyIndex],keyIndex);
		}
		
		int rowIndex =0;
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		List<AttributeColumnInfo> infoList =config.getAttributeColumnInfo(params);
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		if (infoList.size() > 100)
			infoList = infoList.subList(0, 100);
		
		Object recordData[][] =  new Object[keys.size()][infoList.size()];
		
		Map<String,String> metadataList[] = new Map[infoList.size()];
		for (int colIndex = 0; colIndex < infoList.size(); colIndex++){
			AttributeColumnInfo info = infoList.get(colIndex);
			String dataWithKeysQuery = info.sqlQuery;
			metadataList[colIndex] = info.metadata;

			//if (dataWithKeysQuery.length() == 0)
			//	throw new RemoteException(String.format("No SQL query is associated with column \"%s\" in dataTable \"%s\"", attributeColumnName, dataTableName));
			
			List<Double> numericData = null;
			List<String> stringData = null;
			List<String> secKeys = new ArrayList<String>();
			String dataType = info.getMetadata(Metadata.DATATYPE.toString());
			boolean hasSecondaryKey = true;
			
			// use config min,max or param min,max to filter the data
			String infoMinStr = info.metadata.get(Metadata.MIN.toString());
			String infoMaxStr = info.metadata.get(Metadata.MAX.toString());
			double minValue = Double.NEGATIVE_INFINITY;
			double maxValue = Double.POSITIVE_INFINITY;
			// first try parsing config min,max values
			try { minValue = Double.parseDouble(infoMinStr); } catch (Exception e) { }
			try { maxValue = Double.parseDouble(infoMaxStr); } catch (Exception e) { }
			// override config min,max with param values if given
			
			/**
			 * columnInfoArray = config.getAttributeColumnInfo(params);
			 * for each info in columnInfoArray
			 *      get sql data
			 *      for each row in sql data
			 *            if key is in keys array,
			 *                  add this value to the result
			 * return result
			 */
			
			try
			{
				//timer.start();
				SQLResult result = SQLConfigUtils.getRowSetFromQuery(config, info.connection, dataWithKeysQuery);
				//timer.lap("get row set");
				// if dataType is defined in the config file, use that value.
				// otherwise, derive it from the sql result.
				if (dataType.length() == 0)
					dataType = DataType.fromSQLType(result.columnTypes[1]).toString();
				if (dataType.equalsIgnoreCase(DataType.NUMBER.toString()))
					numericData = new ArrayList<Double>();
				else
					stringData = new ArrayList<String>();
				
				Object keyObj, dataObj;
				double value;
				
				for( int i = 0; i < result.rows.length; i++)
				{
					keyObj = result.rows[i][0];
					if(keyMap.get(keyObj)!= null){
						rowIndex = keyMap.get(keyObj);
						if (keyObj == null)
							continue;
			
						if (numericData != null)
						{
							if (result.rows[i][1] == null)
								continue;
							try
							{
								value = ((Double)result.rows[i][1]).doubleValue();
							}
							catch (Exception e)
							{
								continue;
							}

							// filter the data based on the min,max values
							if (minValue <= value && value <= maxValue){
								numericData.add(value);
								recordData[rowIndex][colIndex] = value;
							}								
							else
								continue;
						}
						else
						{
							dataObj = result.rows[i][1];
							if (dataObj == null)
								continue;
							
							stringData.add(dataObj.toString());
							recordData[rowIndex][colIndex] =  dataObj;
						}
						if (hasSecondaryKey)
							hasSecondaryKey = getSecKeys(result, secKeys, i);
					}
				}
				//timer.lap("get rows");
			}
			catch (SQLException e)
			{
				e.printStackTrace();
				
			}
			catch (NullPointerException e)
			{
				e.printStackTrace();
				throw(new RemoteException(e.getMessage()));
			}
			
		}
		
		WeaveRecordList result = new WeaveRecordList();
		result.recordData = recordData;
		result.keyType = keyType;
		result.recordKeys = keysArray;
		result.attributeColumnMetadata = metadataList;
		
		return result;
	}	
	
	/**
	 * should return two columns -- keys and data
	 */
	public AttributeColumnDataWithKeys getAttributeColumn(Map<String, String> params)
		throws RemoteException
	{
		DebugTimer timer = new DebugTimer();
		String dataTableName = params.get(Metadata.DATATABLE.toString());
		String attributeColumnName = params.get(Metadata.NAME.toString());

		// remove min,max params -- do not use them to query the config
		String paramMinStr = params.remove(Metadata.MIN.toString());
		String paramMaxStr = params.remove(Metadata.MAX.toString());

		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		
		timer.lap("getConfig");
		List<AttributeColumnInfo> infoList = config.getAttributeColumnInfo(params);
		timer.lap("get column info "+params);
		
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		if (infoList.size() > 1)
			throw new RemoteException("More than one matching column found. "+params);
		
		AttributeColumnInfo info = infoList.get(0);
		String dataWithKeysQuery = info.sqlQuery;

		if (dataWithKeysQuery.length() == 0)
			throw new RemoteException(String.format("No SQL query is associated with column \"%s\" in dataTable \"%s\"", attributeColumnName, dataTableName));
		
		List<String> keys = new ArrayList<String>();
		List<Double> numericData = null;
		List<String> stringData = null;
		List<String> secKeys = new ArrayList<String>();
		String dataType = info.getMetadata(Metadata.DATATYPE.toString());
		boolean hasSecondaryKey = true;
		
		// use config min,max or param min,max to filter the data
		String infoMinStr = info.metadata.get(Metadata.MIN.toString());
		String infoMaxStr = info.metadata.get(Metadata.MAX.toString());
		double minValue = Double.NEGATIVE_INFINITY;
		double maxValue = Double.POSITIVE_INFINITY;
		// first try parsing config min,max values
		try { minValue = Double.parseDouble(infoMinStr); } catch (Exception e) { }
		try { maxValue = Double.parseDouble(infoMaxStr); } catch (Exception e) { }
		// override config min,max with param values if given
		try {
			minValue = Double.parseDouble(paramMinStr);
			infoMinStr = paramMinStr; // this happens only if parseDouble() succeeds
		} catch (Exception e) { }
		try {
			maxValue = Double.parseDouble(paramMaxStr);
			infoMaxStr = paramMaxStr; // this happens only if parseDouble() succeeds
		} catch (Exception e) { }
		
		try
		{
			timer.start();
			SQLResult result = SQLConfigUtils.getRowSetFromQuery(config, info.connection, dataWithKeysQuery);
			timer.lap("get row set");
			// if dataType is defined in the config file, use that value.
			// otherwise, derive it from the sql result.
			if (dataType.length() == 0)
				dataType = DataType.fromSQLType(result.columnTypes[1]).toString();
			if (dataType.equalsIgnoreCase(DataType.NUMBER.toString()))
				numericData = new ArrayList<Double>();
			else
				stringData = new ArrayList<String>();
			
			Object keyObj, dataObj;
			double value;
			for( int i = 0; i < result.rows.length; i++)
			{
				keyObj = result.rows[i][0];
				if (keyObj == null)
					continue;
	
				if (numericData != null)
				{
					try
					{
						value = ((Double)result.rows[i][1]).doubleValue();
					}
					catch (Exception e)
					{
						continue;
					}
					if (result.rows[i][1] == null)
						continue;

					// filter the data based on the min,max values
					if (minValue <= value && value <= maxValue)
						numericData.add(value);
					else
						continue;
				}
				else
				{
					dataObj = result.rows[i][1];
					if (dataObj == null)
						continue;
					
					stringData.add(dataObj.toString());
				}
				keys.add(keyObj.toString());
				if (hasSecondaryKey)
					hasSecondaryKey = getSecKeys(result, secKeys, i);
			}
			timer.lap("get rows");
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			String msg = String.format(
					"Unable to retrieve AttributeColumn \"%s\" in DataTable \"%s\". %s",
					attributeColumnName, dataTableName, e.getMessage()
				);
			throw(new RemoteException(msg));
		}
		catch (NullPointerException e)
		{
			e.printStackTrace();
			throw(new RemoteException(e.getMessage()));
		}

		AttributeColumnDataWithKeys result = new AttributeColumnDataWithKeys(
				attributeColumnName,
				info.getMetadata(Metadata.KEYTYPE.toString()),
				dataType,
				infoMinStr,
				infoMaxStr,
				info.getMetadata(Metadata.YEAR.toString()),
				keys.toArray(new String[0]),
				numericData != null ? numericData.toArray(new Double[0]) : stringData.toArray(new String[0]),
				hasSecondaryKey ? secKeys.toArray(new String[0]) : null
			);
		timer.report("prepare result");
		
		return result;
	}
	
	private boolean getSecKeys(SQLResult rowset, List<String> secKeys, int rownum)
	{
		try
		{
			Object secKeyValueObject = rowset.rows[rownum][2];
			if (! secKeyValueObject.equals(null))
				secKeys.add(secKeyValueObject.toString());	
		}
		catch (Exception e)
		{
			return false;
		}
		return true;
	}
	
	public SQLResult getRowSetFromAttributeColumn(Map<String, String> params)
		throws RemoteException
	{
		DebugTimer timer = new DebugTimer();
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		timer.lap("get config");
		List<AttributeColumnInfo> infoList = config.getAttributeColumnInfo(params);
		timer.lap("get column info "+params);
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		if (infoList.size() > 1)
			throw new RemoteException("More than one matching column found. "+params);
		
		AttributeColumnInfo info = infoList.get(0);
		try
		{
			SQLResult result = SQLConfigUtils.getRowSetFromQuery(config, info.connection, info.sqlQuery);
			timer.report("get row set");
			return result;
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}
	
	public GeometryStreamMetadata getGeometryStreamTileDescriptors(String geometryCollectionName)
		throws RemoteException
	{
		DebugTimer timer = new DebugTimer();
		timer.report("getGeometryStreamTileDescriptors");
		configManager.detectConfigChanges();
		timer.lap("detect changes");
		ISQLConfig config = configManager.getConfig();
		timer.lap("get config");
	
		GeometryCollectionInfo info = config.getGeometryCollectionInfo(geometryCollectionName);
		if (info == null)
			throw new RemoteException(String.format("Geometry collection \"%s\" does not exist.", geometryCollectionName));
		timer.lap("get geom info");
		
		GeometryStreamMetadata result = new GeometryStreamMetadata();
		result.setProjection(info.projection);
		try {
			Connection conn = SQLConfigUtils.getStaticReadOnlyConnection(config, info.connection);
			timer.lap("get connection");
	
			// get tile descriptors
			result.setKeyType(info.keyType);
			result.setMetadataTileDescriptors(
					SQLGeometryStreamReader.getMetadataTileDescriptors(conn, info.schema, info.tablePrefix)
				);
			timer.lap("get meta tile desc");
			result.setGeometryTileDescriptors(
					SQLGeometryStreamReader.getGeometryTileDescriptors(conn, info.schema, info.tablePrefix)
				);
			timer.lap("get geom tile desc");
		}
		catch (SQLException e)
		{
			System.out.println(String.format("getGeometryStreamTileDescriptors(%s): schema=\"%s\" tablePrefix=\"%s\"", geometryCollectionName, info.schema, info.tablePrefix));
			e.printStackTrace();
			throw new RemoteException("Failed to retrieve GeometryStreamMetadata for GeometryCollection \""+geometryCollectionName+"\"", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		timer.report();
		
		// return tile descriptors
		return result;
	}
	
	public byte[] getGeometryStreamMetadataTiles(String geometryCollectionName, List<Integer> tileIDs)
		throws RemoteException
	{
		DebugTimer timer = new DebugTimer();
		timer.report("getGeometryStreamMetadataTiles");
		ISQLConfig config = configManager.getConfig();
		timer.lap("get config");
		GeometryCollectionInfo info = config.getGeometryCollectionInfo(geometryCollectionName);
		if (info == null)
			throw new RemoteException(String.format("Geometry collection \"%s\" does not exist.", geometryCollectionName));
		timer.lap("get geom info");
	
		// get stream from sql table
		byte[] result;
		try
		{
			Connection conn = SQLConfigUtils.getStaticReadOnlyConnection(config, info.connection);
			timer.lap("get conn");
	
			result = SQLGeometryStreamReader.getMetadataTiles(conn, info.schema, info.tablePrefix, tileIDs);
			timer.lap("get meta tiles "+tileIDs);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException("Unable to retrieve metadata tiles for geometry collection \""+geometryCollectionName+"\"", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage(), e);
		}
		timer.report();
	
		// return stream
		return result;
	}
	
	public byte[] getGeometryStreamGeometryTiles(String geometryCollectionName, List<Integer> tileIDs)
		throws RemoteException
	{
		DebugTimer timer = new DebugTimer();
		timer.report("getGeometryStreamGeometryTiles");
		ISQLConfig config = configManager.getConfig();
		timer.lap("get config");
		GeometryCollectionInfo info = config.getGeometryCollectionInfo(geometryCollectionName);
		if (info == null)
			throw new RemoteException(String.format("Geometry collection \"%s\" does not exist.", geometryCollectionName));
		timer.lap("get geom info");
	
		// get stream from sql table
		byte[] result;
		try
		{
			Connection conn = SQLConfigUtils.getStaticReadOnlyConnection(config, info.connection);
			timer.lap("get conn");
			
			result = SQLGeometryStreamReader.getGeometryTiles(conn, info.schema, info.tablePrefix, tileIDs);
			timer.lap("get geom tiles "+tileIDs);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException("Unable to retrieve geometry tiles for geometry collection \""+geometryCollectionName+"\"", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage(), e);
		}
		timer.report();
	
		// return stream
		return result;
	}
	
	
	
	

	/**
	 * createReport - sends a request to the webservices to create a report
	 * @param reportType - must match an item in the ReportFactory.ReportType enum 
	 *                     e.g. "CATEGORYREPORT" or "COMPAREREPORT"
	 * @param keys subset of keys to include in the report
	 * @return ((success or fail string) + (report name))
	 * @throws Exception 
	 */
	
	public String createReport(String reportDefinitionFileName, List<String> keys) throws Exception
	{
		WeaveReport rpt = new WeaveReport(configManager.getContextParams().getDocrootPath());
		String result = rpt.createReport(configManager.getConfig(), this, reportDefinitionFileName, keys);
		return result;
	}
}

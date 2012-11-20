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

import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import flex.messaging.io.amf.ASObject;

import weave.beans.AttributeColumnData;
import weave.beans.GeometryStreamMetadata;
import weave.beans.WeaveRecordList;
import weave.config.ConnectionConfig;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.DataConfig;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityTableInfo;
import weave.config.DataConfig.DataEntityWithChildren;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;
import static weave.config.WeaveConfig.*;
import weave.config.WeaveContextParams;
import weave.geometrystream.SQLGeometryStreamReader;
import weave.utils.CSVParser;
import weave.utils.ListUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;

/**
 * This class connects to a database and gets data
 * uses xml configuration file to get connection/query info
 * 
 * @author Andy Dufilie
 */
public class DataService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public DataService()
	{
	}
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
	}
	
	@Override
	protected Object cast(Object value, Class<?> type)
	{
		if (type == DataEntityMetadata.class && value != null && value instanceof ASObject)
		{
			ASObject aso = (ASObject) value;
			DataEntityMetadata dem = new DataEntityMetadata();
			ASObject privateMetadata = (ASObject)aso.get("privateMetadata");
			ASObject publicMetadata = (ASObject)aso.get("publicMetadata");
			for (Object key : privateMetadata.keySet())
				dem.privateMetadata.put((String)key, (String)privateMetadata.get(key));
			for (Object key : publicMetadata.keySet())
				dem.publicMetadata.put((String)key, (String)publicMetadata.get(key));
			return dem;
		}
		return super.cast(value, type);
	}
	
	/////////////////////
	// helper functions
	
	private DataEntity getColumnEntity(int columnId) throws RemoteException
	{
		DataEntity entity = getDataConfig().getEntity(columnId);
		if (entity == null || entity.type != DataEntity.TYPE_COLUMN)
			throw new RemoteException("No column with id " + columnId);
		return entity;
	}
	
	private boolean isEmpty(String str)
	{
		return str == null || str.length() == 0;
	}
	
	private void assertColumnHasPrivateMetadata(DataEntity columnEntity, String ... fields) throws RemoteException
	{
		for (String field : fields)
		{
			if (isEmpty(columnEntity.privateMetadata.get(field)))
			{
				String dataType = columnEntity.publicMetadata.get(PublicMetadata.DATATYPE);
				String description = dataType.equals(DataType.GEOMETRY) ? "Geometry column" : "Column";
				throw new RemoteException(String.format("%s %s is missing private metadata %s", description, columnEntity.id, field));
			}
		}
	}
	
	private void assertNonGeometryColumn(DataEntity entity) throws RemoteException
	{
		String dataType = entity.publicMetadata.get(PublicMetadata.DATATYPE);
		if (dataType.equals(DataType.GEOMETRY))
			throw new RemoteException(String.format("Column %s dataType is %s", dataType, DataType.GEOMETRY));
		assertColumnHasPrivateMetadata(entity, PrivateMetadata.CONNECTION, PrivateMetadata.SQLQUERY);
	}
	
	private void assertGeometryColumn(DataEntity entity) throws RemoteException
	{
		String dataType = entity.publicMetadata.get(PublicMetadata.DATATYPE);
		if (!dataType.equals(DataType.GEOMETRY))
			throw new RemoteException(String.format("Column %s dataType is %s, not %s", entity.id, dataType, DataType.GEOMETRY));
		assertColumnHasPrivateMetadata(entity, PrivateMetadata.CONNECTION, PrivateMetadata.SQLSCHEMA, PrivateMetadata.SQLTABLEPREFIX);
	}
	
	////////////////////////////////////
	// string and numeric data columns
	
	public AttributeColumnData getColumnData(int columnId, Double minParam, Double maxParam, String[] sqlParams)
		throws RemoteException
	{
		DataEntity entity = getColumnEntity(columnId);
		assertNonGeometryColumn(entity);
		
		String connName = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
		String query = entity.privateMetadata.get(PrivateMetadata.SQLQUERY);
		String dataType = entity.publicMetadata.get(PublicMetadata.DATATYPE);
		
		ConnectionInfo connInfo = getConnectionConfig().getConnectionInfo(connName);
		if (connInfo == null)
			throw new RemoteException(String.format("Connection associated with column %s no longer exists", columnId));
		
		List<String> keys = new ArrayList<String>();
		List<Double> numericData = null;
		List<String> stringData = null;
		List<Object> thirdColumn = null; // hack for dimension slider format
		
		// use config min,max or param min,max to filter the data
		double minValue = Double.NEGATIVE_INFINITY;
		double maxValue = Double.POSITIVE_INFINITY;
		
		// override config min,max with param values if given
		if (minParam != null)
		{
			minValue = minParam;
		}
		else
		{
			try {
				minValue = Double.parseDouble(entity.publicMetadata.get(PublicMetadata.MIN));
			} catch (Exception e) { }
		}
		if (maxParam != null)
		{
			maxValue = maxParam;
		}
		else
		{
			try {
				maxValue = Double.parseDouble(entity.publicMetadata.get(PublicMetadata.MAX));
			} catch (Exception e) { }
		}
		
		try
		{
			Connection conn = connInfo.getStaticReadOnlyConnection();
			
			// use default sqlParams if not specified by query params
			if (sqlParams == null || sqlParams.length == 0)
			{
				String sqlParamsString = entity.privateMetadata.get(PrivateMetadata.SQLPARAMS);
				sqlParams = CSVParser.defaultParser.parseCSV(sqlParamsString, true)[0];
			}
			
			SQLResult result = SQLUtils.getResultFromQuery(conn, query, sqlParams, false);
			
			// if dataType is defined in the config file, use that value.
			// otherwise, derive it from the sql result.
			if (dataType.length() == 0)
			{
				dataType = DataType.fromSQLType(result.columnTypes[1]);
				entity.publicMetadata.put(PublicMetadata.DATATYPE, dataType); // fill in missing metadata for the client
			}
			if (dataType.equalsIgnoreCase(DataType.NUMBER)) // special case: "number" => Double
				numericData = new ArrayList<Double>();
			else // for every other dataType, use String
				stringData = new ArrayList<String>();
			
			// hack for dimension slider format
			if (result.columnTypes.length == 3)
				thirdColumn = new LinkedList<Object>();
			
			Object keyObj, dataObj;
			double value;
			for (int i = 0; i < result.rows.length; i++)
			{
				keyObj = result.rows[i][0];
				if (keyObj == null)
					continue;
				
				dataObj = result.rows[i][1];
				if (dataObj == null)
					continue;
				
				if (numericData != null)
				{
					try
					{
						if (dataObj instanceof String)
							dataObj = Double.parseDouble((String)dataObj);
						value = ((Number)dataObj).doubleValue();
					}
					catch (Exception e)
					{
						continue;
					}
					// filter the data based on the min,max values
					if (minValue <= value && value <= maxValue)
						numericData.add(value);
					else
						continue;
				}
				else
				{
					stringData.add(dataObj.toString());
				}
				keys.add(keyObj.toString());
				
				// hack for dimension slider format
				if (thirdColumn != null)
					thirdColumn.add(result.rows[i][2]);
			}
		}
		catch (SQLException e)
		{
			System.out.println(query);
			e.printStackTrace();
			throw new RemoteException(String.format("Unable to retrieve data for column %s", columnId));
		}
		catch (NullPointerException e)
		{
			e.printStackTrace();
			throw(new RemoteException(e.getMessage()));
		}

		AttributeColumnData result = new AttributeColumnData();
		result.metadata = entity.publicMetadata;
		result.keys = keys.toArray(new String[keys.size()]);
		if (numericData != null)
			result.data = numericData.toArray();
		else
			result.data = stringData.toArray();
		// hack for dimension slider
		if (thirdColumn != null)
			result.thirdColumn = thirdColumn.toArray();
		
		return result;
	}
	
	@SuppressWarnings("unchecked")
	public WeaveRecordList getRows(String keyType, String[] keysArray) throws RemoteException
	{
		List<String> keys = new ArrayList<String>();
		keys = ListUtils.copyArrayToList(keysArray, keys);
		HashMap<String,Integer> keyMap = new HashMap<String,Integer>();
		for (int keyIndex = 0; keyIndex < keysArray.length; keyIndex++)
			keyMap.put(keysArray[keyIndex], keyIndex);
		
		ConnectionConfig connConfig = getConnectionConfig();
		DataConfig dataConfig = getDataConfig();
		
		DataEntityMetadata params = new DataEntityMetadata();
		params.publicMetadata.put(PublicMetadata.KEYTYPE,keyType);
		Collection<Integer> columnIds = dataConfig.getEntityIdsByMetadata(params, DataEntity.TYPE_COLUMN);
		List<DataEntity> infoList = new ArrayList<DataEntity>(dataConfig.getEntitiesById(columnIds));
		
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		if (infoList.size() > 100)
			infoList = infoList.subList(0, 100);
		
		Object recordData[][] =  new Object[keys.size()][infoList.size()];
		
		Map<String,String> metadataList[] = new Map[infoList.size()];
		for (int colIndex = 0; colIndex < infoList.size(); colIndex++)
		{
			DataEntity info = infoList.get(colIndex);
			String connectionName = info.privateMetadata.get(PrivateMetadata.CONNECTION);
			String sqlQuery = info.privateMetadata.get(PrivateMetadata.SQLQUERY);
			String sqlParams = info.privateMetadata.get(PrivateMetadata.SQLPARAMS);
			metadataList[colIndex] = info.publicMetadata;
			
			//if (dataWithKeysQuery.length() == 0)
			//	throw new RemoteException(String.format("No SQL query is associated with column \"%s\" in dataTable \"%s\"", attributeColumnName, dataTableName));
			
			List<Double> numericData = null;
			List<String> stringData = null;
			String dataType = info.publicMetadata.get(PublicMetadata.DATATYPE);
			
			// use config min,max or param min,max to filter the data
			String infoMinStr = info.publicMetadata.get(PublicMetadata.MIN);
			String infoMaxStr = info.publicMetadata.get(PublicMetadata.MAX);
			double minValue = Double.NEGATIVE_INFINITY;
			double maxValue = Double.POSITIVE_INFINITY;
			// first try parsing config min,max values
			try { minValue = Double.parseDouble(infoMinStr); } catch (Exception e) { }
			try { maxValue = Double.parseDouble(infoMaxStr); } catch (Exception e) { }
			// override config min,max with param values if given
			
			/**
			 * columnInfoArray = config.getDataEntity(params);
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
				
				Connection conn = connConfig.getConnectionInfo(connectionName).getStaticReadOnlyConnection();
				String[] sqlParamsArray = null;
				if (sqlParams != null && sqlParams.length() > 0)
					sqlParamsArray = CSVParser.defaultParser.parseCSV(sqlParams, true)[0];
				
				SQLResult result = SQLUtils.getResultFromQuery(conn, sqlQuery, sqlParamsArray, false);
				
				//timer.lap("get row set");
				// if dataType is defined in the config file, use that value.
				// otherwise, derive it from the sql result.
				if (dataType.length() == 0)
					dataType = DataType.fromSQLType(result.columnTypes[1]);
				if (dataType.equalsIgnoreCase(DataType.NUMBER)) // special case: "number" => Double
					numericData = new ArrayList<Double>();
				else // for every other dataType, use String
					stringData = new ArrayList<String>();
				
				Object keyObj, dataObj;
				double value;
				int rowIndex;
				for (int i = 0; i < result.rows.length; i++)
				{
					keyObj = result.rows[i][0];
					if (keyMap.get(keyObj) != null)
					{
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
							recordData[rowIndex][colIndex] = dataObj;
						}
					}
				}
			}
			catch (SQLException e)
			{
				e.printStackTrace();
			}
			catch (NullPointerException e)
			{
				e.printStackTrace();
				throw new RemoteException(e.getMessage());
			}
		}
		
		WeaveRecordList result = new WeaveRecordList();
		result.recordData = recordData;
		result.keyType = keyType;
		result.recordKeys = keysArray;
		result.attributeColumnMetadata = metadataList;
		
		return result;
	}
	
	/////////////////////
	// geometry columns
	
	public GeometryStreamMetadata getGeometryStreamTileDescriptors(int columnId) throws RemoteException
	{
		return (GeometryStreamMetadata) getGeometryData(GeomStreamStep.TILE_DESCRIPTORS, columnId, null);
	}
	
	public byte[] getGeometryStreamMetadataTiles(int columnId, List<Integer> tileIDs) throws RemoteException
	{
		return (byte[]) getGeometryData(GeomStreamStep.METADATA_TILES, columnId, tileIDs);
	}
	
	public byte[] getGeometryStreamGeometryTiles(int columnId, List<Integer> tileIDs) throws RemoteException
	{
		return (byte[]) getGeometryData(GeomStreamStep.GEOMETRY_TILES, columnId, tileIDs);
	}
	
	private static enum GeomStreamStep { TILE_DESCRIPTORS, METADATA_TILES, GEOMETRY_TILES };
	
	private Object getGeometryData(GeomStreamStep step, int columnId, List<Integer> tileIDs) throws RemoteException
	{
		DataEntity entity = getColumnEntity(columnId);
		assertGeometryColumn(entity);
		
		String connName = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
		String schema = entity.privateMetadata.get(PrivateMetadata.SQLSCHEMA);
		String tablePrefix = entity.privateMetadata.get(PrivateMetadata.SQLTABLEPREFIX);
		
		Connection conn = getConnectionConfig().getConnectionInfo(connName).getStaticReadOnlyConnection();
		try
		{
			switch (step)
			{
				case TILE_DESCRIPTORS:
					GeometryStreamMetadata result = new GeometryStreamMetadata();
					result.id = columnId;
					result.metadata = entity.publicMetadata;
					result.metadataTileDescriptors = SQLGeometryStreamReader.getMetadataTileDescriptors(conn, schema, tablePrefix);
					result.geometryTileDescriptors = SQLGeometryStreamReader.getGeometryTileDescriptors(conn, schema, tablePrefix);
					return result;
					
				case METADATA_TILES:
					return SQLGeometryStreamReader.getMetadataTiles(conn, schema, tablePrefix, tileIDs);
					
				case GEOMETRY_TILES:
					return SQLGeometryStreamReader.getGeometryTiles(conn, schema, tablePrefix, tileIDs);
					
				default:
					throw new InvalidParameterException("Invalid step.");
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(String.format("Unable to read geometry data (id=%s)", columnId));
		}
	}

	////////////////////
	// DataEntity info
	
	public DataEntityTableInfo[] getDataTableList() throws RemoteException
	{
		return getDataConfig().getDataTableList();
	}

	public int[] getEntityChildIds(int parentId) throws RemoteException
	{
		return ListUtils.toIntArray( getDataConfig().getChildIds(parentId) );
	}

	public int[] getEntityIdsByMetadata(DataEntityMetadata meta, int entityType) throws RemoteException
	{
		return ListUtils.toIntArray( getDataConfig().getEntityIdsByMetadata(meta, entityType) );
	}

	public DataEntity[] getEntitiesById(int[] ids) throws RemoteException
	{
		DataConfig config = getDataConfig();
		Set<Integer> idSet = new HashSet<Integer>();
		for (int id : ids)
			idSet.add(id);
		DataEntity[] result = config.getEntitiesById(idSet).toArray(new DataEntity[0]);
		for (int i = 0; i < result.length; i++)
		{
			int[] childIds = ListUtils.toIntArray( config.getChildIds(result[i].id) );
			result[i] = new DataEntityWithChildren(result[i], childIds);
		}
		return result;
	}
	
	/////////////////////////////
	// backwards compatibility
	
	@Deprecated
	public int[] getColumnIds(Map<String, String> publicMetadata)
		throws RemoteException
	{
		DataEntityMetadata params = new DataEntityMetadata();
		params.publicMetadata = publicMetadata;
		Collection<Integer> idCollection = getDataConfig().getEntityIdsByMetadata(params, DataEntity.TYPE_COLUMN);
		int ids[] = new int[idCollection.size()];
		int i = 0;
		for (int id : idCollection)
			ids[i++] = id;
		return ids;
	}
}

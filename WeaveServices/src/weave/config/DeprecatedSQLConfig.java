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

package weave.config;

import java.rmi.RemoteException;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

/**
 * ISQLConfig An interface to retrieve strings from a configuration file. TODO:
 * needs documentation
 * 
 * @author Andy Dufilie
 */
@Deprecated
public abstract class DeprecatedSQLConfig extends ISQLConfig
{
	/**
	 * Gets the display name of for the server in which this configuration
	 * lives.
	 */
	abstract String getServerName() throws RemoteException;

	/**
	 * Gets the names of all geometry collections in this configuration
	 * @param connectionName A connection used as a filter, or null for no filter.
	 */
	public abstract String[] getGeometryCollectionNames(String connectionName) throws RemoteException;

	/**
	 * Looks up a geometry collection in this configuration by name
	 * 
	 * @param geometryCollection
	 *            The name of a geometryCollection configuration entry.
	 * @return An object containing the configuration for the specified
	 *         geometryCollection.
	 * @throws RemoteException
	 *             if the info could not be retrieved.
	 */
	public abstract GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName) throws RemoteException;

	static public class GeometryCollectionInfo
	{
		public DataEntity getDataEntity()
		{
			// private metadata
			Map<String, String> pri = new HashMap<String, String>();
			pri.put(PrivateMetadata.CONNECTION, connection);
			pri.put(PrivateMetadata.SCHEMA, schema);
			pri.put(PrivateMetadata.TABLEPREFIX, tablePrefix);
			pri.put(PrivateMetadata.IMPORTNOTES, importNotes);
			
			// public metadata
			Map<String, String> pub = new HashMap<String, String>();
			pub.put(PublicMetadata.NAME, name);
			pub.put(PublicMetadata.KEYTYPE, keyType);
			pub.put(PublicMetadata.PROJECTION, projection);
			pub.put(PublicMetadata.DATATYPE, DataType.GEOMETRY);
			
			DataEntity info = new DataEntity();
			info.publicMetadata = pub;
			info.privateMetadata = pri;
			return info;
		}
		
		public String name = "", connection = "", schema = "", tablePrefix = "", keyType = "", projection = "", importNotes = "";
	}
	
	static public class DeprecatedDatabaseConfigInfo extends DatabaseConfigInfo
	{
		public String geometryConfigTable, dataConfigTable; // not used in new implementation
	}
	
	@Deprecated static public final String GEOMETRYCOLLECTION = "geometryCollection";
	/**
	 * This is a list of metadata property names used in the old implementation of ISQLConfig
	 */
	static public final String[] PUBLIC_METADATA_NAMES = {
		PublicMetadata.NAME,
		PublicMetadata.KEYTYPE,
		PublicMetadata.DATATYPE,
		PublicMetadata.DATATABLE,
		GEOMETRYCOLLECTION,
		PublicMetadata.YEAR,
		PublicMetadata.MIN,
		PublicMetadata.MAX,
		PublicMetadata.TITLE,
		PublicMetadata.NUMBER,
		PublicMetadata.STRING
	};

    public void addChild(Integer parent, Integer child) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public void removeChild(Integer parent, Integer child) throws RemoteException
    {
    	throw new RemoteException("Not implemented");
    }
    public int addTag(String tagtitle) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public Integer addEntity(Integer type_id, DataEntityMetadata properties) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public void removeTag(int tag_id) throws RemoteException
    {
    	throw new RemoteException("Not implemented");
    }
    public Boolean isTag(int tag_id) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public Collection<String> getUniquePublicValues(String property) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public Collection<DataEntity> findEntities(DataEntityMetadata properties, Integer type_id) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public void updateEntity(Integer id, DataEntityMetadata properties) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public void removeEntity(Integer id) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    
    public Collection<DataEntity> getEntities(Collection<Integer> entity_ids) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public Collection<DataEntity> getEntitiesByType(Integer type_id) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public Collection<Integer> getParentIds(Integer child_id) throws RemoteException
    {
        throw new RemoteException("Not implemented");
    }
    public Collection<Integer> getChildIds(Integer parent_id) throws RemoteException
    {
    	throw new RemoteException("Not implemented");
    }
    public Collection<DataEntity> getChildEntities(Integer parent_id) throws RemoteException
    {
    	throw new RemoteException("Not implemented");
    }
    public int getEntityType(int id) throws RemoteException
    {
    	throw new RemoteException("Not implemented");
    }
}

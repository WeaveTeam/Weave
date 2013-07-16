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

package weave.beans;

public class RequestObject
{
	public RequestObject()
	{
	}
	
	
	private String databaseName;
	private String schema;
	private String scriptLocation;
	private String[] columns;
	private String script;
	private ConnectionInfo connection;
	
	public String getDatabaseName(){
		return this.databaseName;
	}
	
	public void setDatabaseName(String _name){
		this.databaseName = _name;
	}
	
	public String getSchema(){
		return this.schema;
	}
	
	public void setSchema(String _schema){
		this.schema = _schema;
	}
	
	public String[] getColumns(){
		return this.columns;
	}
	
	public void setColumns(String[] _columns){
		this.columns = _columns;
	}
	
	public String getScript(){
		return this.script;
	}
	
	public void setScript(String _script){
		this.script = _script;
	}
	
	public ConnectionInfo getConnectionInfo(){
		return this.connection;
	}
	
	//??
//	public void setdatabaseName(Object _connection){
//		this.connection.name = _connection.name;
//		
//	}
	
	class ConnectionInfo 
	{
	 public String name = "";
	 public String pass = "";
	 public String folderName = "" ;
	 public String connectString = "" ;
	public Boolean is_superuser = false;
	}
}

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

package weave
{
	public class Strings
	{
		public static const SQL_SCHEMA:String = "SQL schema";
		public static const SQL_TABLE:String = "SQL table";
		public static const KEY_COLUMN_NAME:String = "Key column name";
		public static const TABLE_DISPLAY_NAME:String = "Table display name";
		public static const GEOMETRY_COLLECTION:String = "Geometry collection";
		public static const KEY_TYPE:String = "Key type";
		public static const SELECT_SHP_FILES:String = "Select .SHP files"
		
		//public static const SQL_SCHEMA_DROPDOWNBOX_TIP:String = "Select the database that contains the table you wish to publish.";
		public static const SQL_SCHEMA_DROPDOWNBOX_TIP:String = "A schema is just a collection of tables; " +
																			"please select the schema in which to place this new table";
		
		public static const SQL_TABLE_DROPDOWNBOX_TIP:String = "Select the SQL table that you wish to publish. " +
																		   "Tables shown in this dropdown menu are those that exist in the schema selected above.";
		
		public static const IMPORT_SQL_DATA_BUTTON_TIP:String = "This publishes an existing SQL table through the Weave server. " +
																	        "This will not create any new tables in the database. " +
																	        "It will just make it so that Weave can see them.";
		
		public static const SQL_TABLE_DISPLAY_NAME_TEXTINPUT_TIP:String = "Type in a name for the table that is chosen above. " +
																				  "This is the name that will be visible in Weave and will be visible to users.";
		
		public static const SCHEMAS_REFRESH_BUTTON_TIP:String = "This button updates the list of SQL schemas - use it if you think the list of schemas " +
																		    "may have changed since you first opened the admin console.";
		
		public static const TABLES_REFRESH_BUTTON_TIP:String = "This button updates the list of tables that exist in the SQL schema you selected above. " +
																		   "Use this button to refresh the list if you suspect it may have changed since you first " +
																		   "opened the admin console."
																		   
		public static const GEOMETRY_COLLECTIONS_REFRESH_BUTTON_TIP:String = "This button updates the list of geometry collections - use it if you think the list of geometry collections " +
																						 "may have changed since you first opened the admin console.";

		public static const KEY_TYPES_REFRESH_BUTTON_TIP:String = "This button updates the list of key types - use it if you think the list of key types " +
																			  "may have changed since you first opened the admin console.";
																		   
		public static const GEOMETRY_COLLECTION_DROPDOWNBOX_TIP:String = "Select the geometry collection whose shapes correspond to the rows in the table " +
																					 "you are using.";
		
		public static const KEY_TYPE_DROPDOWNBOX_TIP:String = "Choose a key type that describes the identifiers in the key column.";
		
		public static const KEY_TYPE_RADIOBUTTON_TIP:String = "If two tables have compatible keys, you should give them the same key type. " +
																		  "If two tables have incompatible keys, they should not have the same key type. " +
																		  "Weave only allows two columns to be compared if they have the same key type."
		
		public static const CSV_TABLES_OVERWRITE_CHECKBOX_TIP:String = "Checking this box will allow you to overwrite the data in an existing table. " +
																				   "The data will be replaced with the data from your CSV. The old data will be lost. Forever.";
		
		public static  const SELECT_KEY_COLUMN_TIP:String = "Select the column whose values uniquely identify the rows in the table.";
		
		public static const CSV_TABLE_DISPLAY_NAME_TEXTINPUT_TIP:String = "Type in a name for the table that you are creating using the CSV data that you are uploading. " +
																			          "This is the name that will be used in Weave and will be visible to users.";
		
		//public static const IMPORT_SHAPEFILE_DATA_BUTTON_TIP:String = "Convert shapefile data from .SHP and .DBF to streaming SQL format";
		public static const IMPORT_SHAPEFILE_DATA_BUTTON_TIP:String = "This uploads and publishes shape data from files on your computer.";
		
		public static const SHAPE_KEY_TYPE_DROPDOWNBOX_TIP:String = "Choose a key type that corresponds to the type of the column that was chosen for the DBF key column name(s). " +
																				"For example US State Fips codes or US State Abbreviations.";
	}
}
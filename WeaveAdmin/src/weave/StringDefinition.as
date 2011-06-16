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
	public class StringDefinition
	{
		public static const DEFAULT_SQL_SCHEMA_LABEL:String = "SQL schema";
		public static const DEFAULT_SQL_TABLE_LABEL:String = "SQL table";
		public static const DEFAULT_KEY_COLUMN_NAME_LABEL:String = "Key column name";
		public static const DEFAULT_TABLE_DISPLAY_NAME_LABEL:String = "Table display name";
		public static const DEFAULT_GEOMETRY_COLLECTION_RADIOBUTTON_LABEL:String = "Geometry collection";
		public static const DEFAULT_KEY_TYPE_RADIOBUTTON_LABEL:String = "Key type";
		public static const DEFAULT_SELECT_SHAPE_FILES_BUTTON_LABEL:String = "Select .SHP files"
		
		//public static const DEFAULT_SQL_SCHEMA_DROPDOWNBOX_TOOLTIP:String = "Select the database that contains the table you wish to publish.";
		public static const DEFAULT_SQL_SCHEMA_DROPDOWNBOX_TOOLTIP:String = "A schema is just a collection of tables; " +
																			"please select the schema in which to place this new table";
		
		public static const DEFAULT_SQL_TABLE_DROPDOWNBOX_TOOLTIP:String = "Select the SQL table that you wish to publish. " +
																		   "Tables shown in this dropdown menu are those that exist in the schema selected above.";
		
		public static const DEFAULT_IMPORT_SQL_DATA_BUTTON_TOOLTIP:String = "This publishes an existing SQL table through the Weave server. " +
																	        "This will not create any new tables in the database. " +
																	        "It will just make it so that Weave can see them.";
		
		public static const DEFAULT_KEY_COLUMN_NAME_DROPDOWNBOX_TOOLTIP:String = "Select the name of the column in the table selected above that contains " +
																				 "the values which uniquely identify each row/record; for example " +
																				 "StateAbbreviation or CountyName.";
		
		public static const DEFAULT_SQL_TABLE_DISPLAY_NAME_TEXTINPUT_TOOLTIP:String = "Type in a name for the table that is chosen above. " +
																				  "This is the name that will be visible in Weave and will be visible to users.";
		
		public static const DEFAULT_SCHEMAS_REFRESH_BUTTON_TOOLTIP:String = "This button updates the list of SQL schemas - use it if you think the list of schemas " +
																		    "may have changed since you first opened the admin console.";
		
		public static const DEFAULT_TABLES_REFRESH_BUTTON_TOOLTIP:String = "This button updates the list of tables that exist in the SQL schema you selected above. " +
																		   "Use this button to refresh the list if you suspect it may have changed since you first " +
																		   "opened the admin console."
																		   
		public static const DEFAULT_GEOMETRY_COLLECTIONS_REFRESH_BUTTON_TOOLTIP:String = "This button updates the list of geometry collections - use it if you think the list of geometry collections " +
																						 "may have changed since you first opened the admin console.";

		public static const DEFAULT_KEY_TYPES_REFRESH_BUTTON_TOOLTIP:String = "This button updates the list of key types - use it if you think the list of key types " +
																			  "may have changed since you first opened the admin console.";
																		   
		public static const DEFAULT_GEOMETRY_COLLECTION_DROPDOWNBOX_TOOLTIP:String = "Select the shape collection whose shapes correspond to the rows in the table " +
																					 "you are using.";
		
		public static const DEFAULT_KEY_TYPE_DROPDOWNBOX_TOOLTIP:String = "Choose a list of key that corresponds to the column that you chose in the key column.";
		
		public static const DEFAULT_KEY_TYPE_RADIOBUTTON_TOOLTIP:String = "If two tables have compatible keys, you should give them the same key type. " +
																		  "If two tables have incompatible keys, they should not have the same key type. " +
																		  "Weave only allows two columns to be compared if they have the same key type."
		
		public static const DEFAULT_CSV_TABLES_OVERWRITE_CHECKBOX_TOOLTIP:String = "Checking this box will allow you to overwrite the data in an existing table. " +
																				   "The data will be replaced with the data from your CSV. The old data will be lost. Forever.";
		
		public static  const DEFAULT_CSV_KEY_COLUMN_DROPDOWNBOX_TOOLTIP:String = "Select the name of the column in your CSV file that contains the values that uniquely identify each row/record. " +
																				 "For example stateAbbreviation or CountyName.";
		
		public static const DEFAULT_CSV_TABLE_DISPLAY_NAME_TEXTINPUT_TOOLTIP:String = "Type in a name for the table that you are creating using the CSV data that you are uploading. " +
																			          "This is the name that will be used in Weave and will be visible to users.";
		
		//public static const DEFAULT_IMPORT_SHAPEFILE_DATA_BUTTON_LABEL:String = "Convert shapefile data from .SHP and .DBF to streaming SQL format";
		public static const DEFAULT_IMPORT_SHAPEFILE_DATA_BUTTON_LABEL:String = "This uploads and publishes shape data from files on your computer.";
		
		public static const DEFAULT_SHAPE_KEY_TYPE_DROPDOWNBOX_TOOLTIP:String = "Choose a key type that corresponds to the type of the column that was chosen for the DBF key column name(s). " +
																				"For example US State Fips codes or US State Abbreviations.";
		
		public static const DEFAULT_CONNECTION:String = '';
	}
}
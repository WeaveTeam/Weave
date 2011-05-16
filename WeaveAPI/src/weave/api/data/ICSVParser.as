/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package weave.api.data
{
	/**
	 * This is an interface for parsing and generating valid CSV data.
	 * 
	 * @author adufilie
	 */	
	public interface ICSVParser
	{
		// if string begins with ", text up until the matching " will be parsed, replacing "" with "
		function parseCSVToken(token:String):String;
		
		//if necessary, adds quotes around string and replaces " with ""
		function createCSVToken(str:String):String;
		
		/**
		 * @param csvData The CSV string to parse.
		 * @param parseTokens If this is true, tokens surrounded in quotes will be unquoted and escaped characters will be unescaped.
		 * @return The destination Array, or a new Array if none was specified.  The result of parsing the CSV string will be stored here.
		 */
		function parseCSV(csvData:String, parseTokens:Boolean = true, destination:Array = null):Array;
		
		//takes an array of arrays and convert it into a CSV string
		function createCSVFromArrays(table:Array):String;
		
		/**
		 * This function converts an Array of Arrays to an Array of Objects compatible with DataGrid.
		 * @param rows An Array of Arrays, the first being a header line containing property names
		 * @return An Array of Objects containing String properties using the names in the header line.
		 */
		function convertRowsToRecords(rows:Array):Array;
		
		/**
		 * This function returns a comprehensive list of all the field names defined by a list of record objects.
		 * @param records An Array of record objects.
		 * @param includeNullFields If this is true, fields that have null values will be included.
		 * @return A comprehensive list of all the field names defined by the given record objects.
		 */
		function getRecordFieldNames(records:Array, includeNullFields:Boolean = false):Array;
		
		/**
		 * This function converts an Array of Objects (compatible with DataGrid) to an Array of Arrays
		 * compatible with other functions in this class.
		 * @param records An Array of Objects containing String properties.
		 * @param columnOrder An optional list of column names to use in order.
		 * @param allowBlankColumns If this is set to true, then the function will include all columns even if they are blank.
		 * @return An Array of Arrays, the first being a header line containing all the property names.
		 */
		function convertRecordsToRows(records:Array, columnOrder:Array = null, allowBlankColumns:Boolean = false):Array;
	}
}

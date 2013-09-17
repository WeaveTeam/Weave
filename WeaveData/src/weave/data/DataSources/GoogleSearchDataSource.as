package weave.data.DataSources
{
	import weave.*;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.SessionManager;

	public class GoogleSearchDataSource extends CSVDataSource {
		public static const DOC_KEYTYPE:String = "googleDoc";
		public static const SOURCE_NAME:String = "Google Data Source";
		
		public function GoogleSearchDataSource() {
			setCSVDataString("url,title,snippest"); // ToDo Be careful not to have empty space
			keyColName.value = "url";
			keyType.value = DOC_KEYTYPE;
			
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,csvData);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,keyColName);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,keyType);
		}
		
		public function containsDoc(key:IQualifiedKey):Boolean {
			var title:String = getTitleForKey(key);
			
			if(title)
				return true;
			else 
				return false;
		}
		
		private function getKeyValueForColumn(csvColumnName:String, key:IQualifiedKey):* {
			var col:IAttributeColumn = getColumnByName(csvColumnName);
			
			return col.getValueFromKey(key);
		}
		
		public function getTitleForKey(key:IQualifiedKey):String {
			return getKeyValueForColumn("title", key) as String;
		}
		
		public function getSnippestForKey(key:IQualifiedKey):String {
			return getKeyValueForColumn("snippest", key) as String;
		}
		
		private function getColumnValueForURL(csvColumnName:String, url:String):* {
			var col:IAttributeColumn = getColumnByName(csvColumnName);
			var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(DOC_KEYTYPE, url);
			
			return col.getValueFromKey(key);
		}
		
		public function getTitleForURL(url:String):String {
			return getColumnValueForURL("title", url) as String;
		}
		
		public function getSnippestForURL(url:String):String {
			return getColumnValueForURL("snippest", url) as String;
		}
	}
	
}
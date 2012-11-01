package disabilityDictionary
{
	import flash.utils.Dictionary;

	public class DisabilityMessageProperties
	{
		private static const messageCategoryMap:Dictionary = new Dictionary();
		
		init();
		
		private static function init():void
		{
			//defining the dictionary
			messageCategoryMap[INCREASING_TREND_ID] = INCREASING_TREND; // eg : IT = "increasing trend"
			messageCategoryMap[PERIODICITY_ID] = PERIODICITY;
			
		}
		
		public static function getMessageCategoryMap():Dictionary
		{
			return messageCategoryMap;
			
		}
		
		
		public static const INCREASING_TREND_ID : String = "IT";
		public static const PERIODICITY_ID:String = "PD";
		
		
		private static const INCREASING_TREND:String = "This is an increasing trend";
		private static const PERIODICITY:String = "It has a high periodicty";
		
		
	}
}
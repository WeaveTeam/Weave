package weave.ui.infomap.utils
{
	import mx.formatters.DateFormatter;

	public class DateUtils
	{
		
		private static var tempDate:Date;
		public static function getCurrentDate():Date
		{
			tempDate = new Date();
			var currentDate:Date = new Date();
			tempDate.setDate(currentDate.getDate());
			tempDate.setMonth(currentDate.getMonth());
			tempDate.setFullYear(currentDate.getFullYear());
			
			return tempDate;
		}
		
		private static var dateFormatter:DateFormatter;
		public static function getCurrentDateInStringFormat(format:String='MM/DD/YYYY'):String
		{
			dateFormatter = new DateFormatter();
			dateFormatter.formatString = format;
			
			return dateFormatter.format(getCurrentDate());
		}
		
		public static function getDateInStringFormat(date:Date,format:String='MM/DD/YYYY'):String
		{
			dateFormatter = new DateFormatter();
			dateFormatter.formatString = format;
			
			return dateFormatter.format(date);
		}
		
		private static var validDateWords:Array = ['now','day','days','month','months'];
		private static var validDateOperators:Array = ['+','-']
		
		public static const millisecondsPerMinute:uint = 1000 * 60;
		public static const millisecondsPerHour:uint = 1000 * 60 * 60;
		public static const millisecondsPerDay:uint = 1000 * 60 * 60 * 24;
		//assumes 31 days
		public static const millisecondsPerMonth:uint = 1000 * 60 * 60 * 24 * 31;
		
		/**
		 * This function takes a string and converts it to a date object. This uses the Flex's
		 * standard date formater if the string is in the standard date string format.
		 * Else it assumes the string format uses the NOW keyword.
		 * @param str The Date in String format
		 * 
		 * @return The Date object.
		 * */
		public static function getDateFromString(str:String):Date
		{
			
			//if it does not start with now then use dateformatter to format the date
			if(str.substr(0,3).toLowerCase() != 'now')
				return DateFormatter.parseDateString(str);
			
			if(str.toLowerCase() == 'now')
				return getCurrentDate();
			
			
			var currentDate:Date = getCurrentDate();
			
			var operator:String = str.substr(3,1);
			
			//checking for valid operator
			if(validDateOperators.indexOf(operator) == -1)
				return null;
			
			var digit:Number = Number(str.substr(4,2));
			
			if(isNaN(digit))
				return null;
			
			var modifier:String = str.substr(6);
			
			//checking if valid date keyword is used
			if(validDateWords.indexOf(modifier.toLowerCase()) == -1)
				return null;
			
			var dateInMS:Number = currentDate.getTime();
			
			if(operator == '+')
			{
				dateInMS = dateInMS + digit * getDateKeywordInMS(modifier);
			}else if (operator == '-')
			{
				dateInMS = dateInMS - digit * getDateKeywordInMS(modifier);
			}
			
			tempDate = new Date();
			tempDate.setTime(dateInMS);
			
			return tempDate;
		}
		
		/**
		 * This function takes a date parameter and checks to see if it is within the range of the
		 * start and end dates.
		 * @param date The Date object we want to check
		 * @param start The start date of the range
		 * @param end The end date of the range
		 * 
		 * @return Boolean value.
		 * */
		public static function isDateWithinRange(date:Date,start:Date,end:Date):Boolean
		{
			var dateInMS:Number = date.getTime();
			
			var startInMS:Number = start.getTime();
			
			var endInMS:Number = end.getTime();
			
			if(startInMS <= dateInMS)
				if(endInMS >= dateInMS)
					return true;
			return false;
		}
		
		
		/**
		 * This function takes a date parameter in string format and checks to see if it is within the range of the
		 * start and end dates.
		 * @param date The date we want to check in String format 
		 * @param start The start date of the range in String format 
		 * @param end The end date of the range in String format 
		 * 
		 * @return Boolean value.
		 * */
		public static function isDateStringWithinRange(date:String,start:String,end:String):Boolean
		{
			var d:Date = getDateFromString(date);
			var s:Date = getDateFromString(start);
			var e:Date = getDateFromString(end);
			
			return isDateWithinRange(d,s,e);			
		}
		
		private static function getDateKeywordInMS(key:String):uint
		{
			if(key.toLowerCase() == 'day' || key.toLowerCase() == 'days')
				return millisecondsPerDay;
			if(key.toLowerCase() == 'month' || key.toLowerCase() == 'months')
				return millisecondsPerMonth;
			
			return null;
		}
	}
}
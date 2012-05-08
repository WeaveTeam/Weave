package weave.compiler
{
	/**
	 * Version: 1.0 Alpha-1 
	 * Build Date: 12-Nov-2007
	 * Copyright (c) 2006-2007, Coolite Inc. (http://www.coolite.com/). All rights reserved.
	 * License: Licensed under The MIT License. See license.txt and http://www.datejs.com/license/. 
	 * Website: http://www.datejs.com/ or http://www.coolite.com/datejs/
	 * 
	 * Ported to ActionScript by Andy Dufilie
	 */
	public class Datejs
	{
		private var _thisDate:Date;
		
		public function Datejs(year:*=null,month:*=null,date:*=null,hours:*=null,minutes:*=null,seconds:*=null,ms:*=null)
		{
			_thisDate = new Date(year,month,date,hours,minutes,seconds,ms);
		}
		
		private static var CultureInfo:Object;
		
		/**
		 * Gets the month number (0-11) if given a Culture Info specific string which is a valid monthName or abbreviatedMonthName.
		 * @param {String}   The name of the month (eg. "February, "Feb", "october", "oct").
		 * @return {Number}  The day number
		 */
		public static function getMonthNumberFromName(name) {
			var n = Datejs.CultureInfo.monthNames, m = Datejs.CultureInfo.abbreviatedMonthNames, s = name.toLowerCase();
			for (var i = 0; i < n.length; i++) {
				if (n[i].toLowerCase() == s || m[i].toLowerCase() == s) { 
					return i; 
				}
			}
			return -1;
		}

		/**
		 * Gets the day number (0-6) if given a CultureInfo specific string which is a valid dayName, abbreviatedDayName or shortestDayName (two char).
		 * @param {String}   The name of the day (eg. "Monday, "Mon", "tuesday", "tue", "We", "we").
		 * @return {Number}  The day number
		 */
		public static function getDayNumberFromName(name) {
			var n = Datejs.CultureInfo.dayNames, m = Datejs.CultureInfo.abbreviatedDayNames, o = Datejs.CultureInfo.shortestDayNames, s = name.toLowerCase();
			for (var i = 0; i < n.length; i++) { 
				if (n[i].toLowerCase() == s || m[i].toLowerCase() == s) { 
					return i; 
				}
			}
			return -1;  
		}
		
		/**
		 * Determines if the current date instance is within a LeapYear.
		 * @param {Number}   The year (0-9999).
		 * @return {Boolean} true if date is within a LeapYear, otherwise false.
		 */
		public static function isLeapYear(year) { 
			return (((year % 4 === 0) && (year % 100 !== 0)) || (year % 400 === 0)); 
		};
		
		/**
		 * Gets the number of days in the month, given a year and month value. Automatically corrects for LeapYear.
		 * @param {Number}   The year (0-9999).
		 * @param {Number}   The month (0-11).
		 * @return {Number}  The number of days in the month.
		 */
		public static function getDaysInMonth (year, month) {
			return [31, (Datejs.isLeapYear(year) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month];
		};
		
		public static function getTimezoneOffset (s, dst=null) {
			return (dst || false) ? Datejs.CultureInfo.abbreviatedTimeZoneDST[s.toUpperCase()] :
				Datejs.CultureInfo.abbreviatedTimeZoneStandard[s.toUpperCase()];
		};
		
		public static function getTimezoneAbbreviation (offset, dst=null) {
			var n = (dst || false) ? Datejs.CultureInfo.abbreviatedTimeZoneDST : Datejs.CultureInfo.abbreviatedTimeZoneStandard, p;
			for (p in n) { 
				if (n[p] === offset) { 
					return p; 
				}
			}
			return null;
		};

		/**
		 * Compares this instance to a Date object and return an number indication of their relative values.  
		 * @param {Date}     Date object to compare [Required]
		 * @return {Number}  1 = this is greaterthan Datejs. -1 = this is lessthan Datejs. 0 = values are equal
		 */
		public function compareTo (date) {
			if (isNaN(Number(_thisDate))) { 
				throw new Error(_thisDate); 
			}
			if (date instanceof Date && !isNaN(date)) {
				return (_thisDate > date) ? 1 : (_thisDate < date) ? -1 : 0;
			} else { 
				throw new TypeError(date); 
			}
		};
		
		/**
		 * Compares this instance to another Date object and returns true if they are equal.  
		 * @param {Date}     Date object to compare [Required]
		 * @return {Boolean} true if dates are equal. false if they are not equal.
		 */
		public function equals (date) { 
			return (this.compareTo(date) === 0); 
		};
		
		/**
		 * Determines is this instance is between a range of two dates or equal to either the start or end dates.
		 * @param {Date}     Start of range [Required]
		 * @param {Date}     End of range [Required]
		 * @return {Boolean} true is this is between or equal to the start and end dates, else false
		 */
		public function between (start, end) {
			var t = _thisDate.getTime();
			return t >= start.getTime() && t <= end.getTime();
		};
		
		/**
		 * Adds the specified number of milliseconds to this instance. 
		 * @param {Number}   The number of milliseconds to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addMilliseconds (value) {
			_thisDate.setMilliseconds(_thisDate.getMilliseconds() + value);
			return this;
		};
		
		/**
		 * Adds the specified number of seconds to this instance. 
		 * @param {Number}   The number of seconds to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addSeconds (value) { 
			return this.addMilliseconds(value * 1000); 
		};
		
		/**
		 * Adds the specified number of seconds to this instance. 
		 * @param {Number}   The number of seconds to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addMinutes (value) { 
			return this.addMilliseconds(value * 60000); /* 60*1000 */
		};
		
		/**
		 * Adds the specified number of hours to this instance. 
		 * @param {Number}   The number of hours to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addHours (value) { 
			return this.addMilliseconds(value * 3600000); /* 60*60*1000 */
		};
		
		/**
		 * Adds the specified number of days to this instance. 
		 * @param {Number}   The number of days to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addDays (value) { 
			return this.addMilliseconds(value * 86400000); /* 60*60*24*1000 */
		};
		
		/**
		 * Adds the specified number of weeks to this instance. 
		 * @param {Number}   The number of weeks to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addWeeks (value) { 
			return this.addMilliseconds(value * 604800000); /* 60*60*24*7*1000 */
		};
		
		/**
		 * Adds the specified number of months to this instance. 
		 * @param {Number}   The number of months to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addMonths (value) {
			var n = _thisDate.getDate();
			_thisDate.setDate(1);
			_thisDate.setMonth(_thisDate.getMonth() + value);
			_thisDate.setDate(Math.min(n, _thisDate.getDaysInMonth()));
			return this;
		};
		
		/**
		 * Adds the specified number of years to this instance. 
		 * @param {Number}   The number of years to add. The number can be positive or negative [Required]
		 * @return {Date}    this
		 */
		public function addYears (value) {
			return this.addMonths(value * 12);
		};
		
		private var orient;
		private var operator;
		
		/**
		 * Adds (or subtracts) to the value of the year, month, day, hour, minute, second, millisecond of the date instance using given configuration object. Positive and Negative values allowed.
		 * Example
		 <pre><code>
		 Datejs.today().add( { day: 1, month: 1 } )
		 
		 new Datejs().add( { year: -1 } )
		 </code></pre> 
		 * @param {Object}   Configuration object containing attributes (month, day, etc.)
		 * @return {Date}    this
		 */
		public function add (config) {
			if (typeof config == "number") {
				this.orient = config;
				return this;    
			}
			var x = config;
			if (x.millisecond || x.milliseconds) { 
				this.addMilliseconds(x.millisecond || x.milliseconds); 
			}
			if (x.second || x.seconds) { 
				this.addSeconds(x.second || x.seconds); 
			}
			if (x.minute || x.minutes) { 
				this.addMinutes(x.minute || x.minutes); 
			}
			if (x.hour || x.hours) { 
				this.addHours(x.hour || x.hours); 
			}
			if (x.month || x.months) { 
				this.addMonths(x.month || x.months); 
			}
			if (x.year || x.years) { 
				this.addYears(x.year || x.years); 
			}
			if (x.day || x.days) {
				this.addDays(x.day || x.days); 
			}
			return this;
		};
		
		// private
		private static function _validate (value, min, max, name) {
			if (typeof value != "number") {
				throw new TypeError(value + " is not a Number."); 
			} else if (value < min || value > max) {
				throw new RangeError(value + " is not a valid value for " + name + "."); 
			}
			return true;
		};
		
		/**
		 * Validates the number is within an acceptable range for milliseconds [0-999].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateMillisecond (n) {
			return Datejs._validate(n, 0, 999, "milliseconds");
		};
		
		/**
		 * Validates the number is within an acceptable range for seconds [0-59].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateSecond (n) {
			return Datejs._validate(n, 0, 59, "seconds");
		};
		
		/**
		 * Validates the number is within an acceptable range for minutes [0-59].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateMinute (n) {
			return Datejs._validate(n, 0, 59, "minutes");
		};
		
		/**
		 * Validates the number is within an acceptable range for hours [0-23].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateHour (n) {
			return Datejs._validate(n, 0, 23, "hours");
		};
		
		/**
		 * Validates the number is within an acceptable range for the days in a month [0-MaxDaysInMonth].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateDay (n, year, month) {
			return Datejs._validate(n, 1, Datejs.getDaysInMonth(year, month), "days");
		};
		
		/**
		 * Validates the number is within an acceptable range for months [0-11].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateMonth (n) {
			return Datejs._validate(n, 0, 11, "months");
		};
		
		/**
		 * Validates the number is within an acceptable range for years [0-9999].
		 * @param {Number}   The number to check if within range.
		 * @return {Boolean} true if within range, otherwise false.
		 */
		public static function validateYear (n) {
			return Datejs._validate(n, 1, 9999, "seconds");
		};
		
		/**
		 * Set the value of year, month, day, hour, minute, second, millisecond of date instance using given configuration object.
		 * Example
		 <pre><code>
		 Datejs.today().set( { day: 20, month: 1 } )
		 
		 new Datejs().set( { millisecond: 0 } )
		 </code></pre>
		 * 
		 * @param {Object}   Configuration object containing attributes (month, day, etc.)
		 * @return {Date}    this
		 */
		public function set (config) {
			var x = config;
			
			if (!x.millisecond && x.millisecond !== 0) { 
				x.millisecond = -1; 
			}
			if (!x.second && x.second !== 0) { 
				x.second = -1; 
			}
			if (!x.minute && x.minute !== 0) { 
				x.minute = -1; 
			}
			if (!x.hour && x.hour !== 0) { 
				x.hour = -1; 
			}
			if (!x.day && x.day !== 0) { 
				x.day = -1; 
			}
			if (!x.month && x.month !== 0) { 
				x.month = -1; 
			}
			if (!x.year && x.year !== 0) { 
				x.year = -1; 
			}
			
			if (x.millisecond != -1 && Datejs.validateMillisecond(x.millisecond)) {
				this.addMilliseconds(x.millisecond - _thisDate.getMilliseconds()); 
			}
			if (x.second != -1 && Datejs.validateSecond(x.second)) {
				this.addSeconds(x.second - _thisDate.getSeconds()); 
			}
			if (x.minute != -1 && Datejs.validateMinute(x.minute)) {
				this.addMinutes(x.minute - _thisDate.getMinutes()); 
			}
			if (x.hour != -1 && Datejs.validateHour(x.hour)) {
				this.addHours(x.hour - _thisDate.getHours()); 
			}
			if (x.month !== -1 && Datejs.validateMonth(x.month)) {
				this.addMonths(x.month - _thisDate.getMonth()); 
			}
			if (x.year != -1 && Datejs.validateYear(x.year)) {
				this.addYears(x.year - _thisDate.getFullYear()); 
			}
			
			/* day has to go last because you can't validate the day without first knowing the month */
			if (x.day != -1 && Datejs.validateDay(x.day, _thisDate.getFullYear(), _thisDate.getMonth())) {
				this.addDays(x.day - _thisDate.getDate()); 
			}
			if (x.timezone) { 
				this.setTimezone(x.timezone); 
			}
			if (x.timezoneOffset) { 
				this.setTimezoneOffset(x.timezoneOffset); 
			}
			
			return this;   
		};
		
		/**
		 * Resets the time of this Date object to 12:00 AM (00:00), which is the start of the day.
		 * @return {Date}    this
		 */
		public function clearTime () {
			_thisDate.setHours(0); 
			_thisDate.setMinutes(0); 
			_thisDate.setSeconds(0);
			_thisDate.setMilliseconds(0); 
			return this;
		};
		
		/**
		 * Determines whether or not this instance is in a leap year.
		 * @return {Boolean} true if this instance is in a leap year, else false
		 */
		public function isLeapYear () { 
			var y = _thisDate.getFullYear(); 
			return (((y % 4 === 0) && (y % 100 !== 0)) || (y % 400 === 0)); 
		};
		
		/**
		 * Determines whether or not this instance is a weekday.
		 * @return {Boolean} true if this instance is a weekday
		 */
//		public function isWeekday () { 
//			return !(this.is().sat() || this.is().sun());
//		};
		
		/**
		 * Get the number of days in the current month, adjusted for leap year.
		 * @return {Number}  The number of days in the month
		 */
		public function getDaysInMonth () { 
			return Datejs.getDaysInMonth(_thisDate.getFullYear(), _thisDate.getMonth());
		};
		
		/**
		 * Moves the date to the first day of the month.
		 * @return {Date}    this
		 */
		public function moveToFirstDayOfMonth () {
			return this.set({ day: 1 });
		};
		
		/**
		 * Moves the date to the last day of the month.
		 * @return {Date}    this
		 */
		public function moveToLastDayOfMonth () { 
			return this.set({ day: this.getDaysInMonth()});
		};
		
		/**
		 * Move to the next or last dayOfWeek based on the orient value.
		 * @param {Number}   The dayOfWeek to move to.
		 * @param {Number}   Forward (+1) or Back (-1). Defaults to +1. [Optional]
		 * @return {Date}    this
		 */
		public function moveToDayOfWeek (day, orient) {
			var diff = (day - _thisDate.getDay() + 7 * (orient || +1)) % 7;
			return this.addDays((diff === 0) ? diff += 7 * (orient || +1) : diff);
		};
		
		/**
		 * Move to the next or last month based on the orient value.
		 * @param {Number}   The month to move to. 0 = January, 11 = December.
		 * @param {Number}   Forward (+1) or Back (-1). Defaults to +1. [Optional]
		 * @return {Date}    this
		 */
		public function moveToMonth (month, orient) {
			var diff = (month - _thisDate.getMonth() + 12 * (orient || +1)) % 12;
			return this.addMonths((diff === 0) ? diff += 12 * (orient || +1) : diff);
		};
		
		/**
		 * Get the numeric day number of the year, adjusted for leap year.
		 * @return {Number} 0 through 364 (365 in leap years)
		 */
		public function getDayOfYear () {
			return Math.floor((Number(_thisDate) - Number(new Datejs(_thisDate.getFullYear(), 0, 1)._thisDate)) / 86400000);
		};
		
		/**
		 * Get the week of the year for the current date instance.
		 * @param {Number}   A Number that represents the first day of the week (0-6) [Optional]
		 * @return {Number}  0 through 53
		 */
		public function getWeekOfYear (firstDayOfWeek) {
			var y = _thisDate.getFullYear(), m = _thisDate.getMonth(), d = _thisDate.getDate();
			
			var dow = firstDayOfWeek || Datejs.CultureInfo.firstDayOfWeek;
			
			var offset = 7 + 1 - new Datejs(y, 0, 1)._thisDate.getDay();
			if (offset == 8) {
				offset = 1;
			}
			var daynum = ((Date.UTC(y, m, d, 0, 0, 0) - Date.UTC(y, 0, 1, 0, 0, 0)) / 86400000) + 1;
			var w = Math.floor((daynum - offset + 7) / 7);
			if (w === dow) {
				y--;
				var prevOffset = 7 + 1 - new Datejs(y, 0, 1)._thisDate.getDay();
				if (prevOffset == 2 || prevOffset == 8) { 
					w = 53; 
				} else { 
					w = 52; 
				}
			}
			return w;
		};
		
		/**
		 * Determine whether Daylight Saving Time (DST) is in effect
		 * @return {Boolean} True if DST is in effect.
		 */
		public function isDST () {
			/* TODO: not sure if this is portable ... get from Datejs.CultureInfo? */
			return _thisDate.toString().match(/(E|C|M|P)(S|D)T/)[2] == "D";
		};
		
		/**
		 * Get the timezone abbreviation of the current Datejs.
		 * @return {String} The abbreviated timezone name (e.g. "EST")
		 */
		public function getTimezone () {
			return Datejs.getTimezoneAbbreviation(this.getUTCOffset, this.isDST());
		};
		
		public function setTimezoneOffset (s) {
			var here = _thisDate.getTimezoneOffset(), there = Number(s) * -6 / 10;
			this.addMinutes(there - here); 
			return this;
		};
		
		public function setTimezone (s) { 
			return this.setTimezoneOffset(Datejs.getTimezoneOffset(s)); 
		};
		
		/**
		 * Get the offset from UTC of the current Datejs.
		 * @return {String} The 4-character offset string prefixed with + or - (e.g. "-0500")
		 */
		public function getUTCOffset () {
			var n = _thisDate.getTimezoneOffset() * -10 / 6, r;
			if (n < 0) { 
				r = (n - 10000).toString(); 
				return r[0] + r.substr(2); 
			} else { 
				r = (n + 10000).toString();  
				return "+" + r.substr(1); 
			}
		};
		
		/**
		 * Gets the name of the day of the week.
		 * @param {Boolean}  true to return the abbreviated name of the day of the week
		 * @return {String}  The name of the day
		 */
		public function getDayName (abbrev) {
			return abbrev ? Datejs.CultureInfo.abbreviatedDayNames[_thisDate.getDay()] : 
				Datejs.CultureInfo.dayNames[_thisDate.getDay()];
		};
		
		/**
		 * Gets the month name.
		 * @param {Boolean}  true to return the abbreviated name of the month
		 * @return {String}  The name of the month
		 */
		public function getMonthName (abbrev) {
			return abbrev ? Datejs.CultureInfo.abbreviatedMonthNames[_thisDate.getMonth()] : 
				Datejs.CultureInfo.monthNames[_thisDate.getMonth()];
		};
		
		/**
		 * Converts the value of the current Date object to its equivalent string representation.
		 * Format Specifiers
		 <pre>
		 Format  Description                                                                  Example
		 ------  ---------------------------------------------------------------------------  -----------------------
		 s      The seconds of the minute between 1-59.                                      "1" to "59"
		 ss     The seconds of the minute with leading zero if required.                     "01" to "59"
		 
		 m      The minute of the hour between 0-59.                                         "1"  or "59"
		 mm     The minute of the hour with leading zero if required.                        "01" or "59"
		 
		 h      The hour of the day between 1-12.                                            "1"  to "12"
		 hh     The hour of the day with leading zero if required.                           "01" to "12"
		 
		 H      The hour of the day between 1-23.                                            "1"  to "23"
		 HH     The hour of the day with leading zero if required.                           "01" to "23"
		 
		 d      The day of the month between 1 and 31.                                       "1"  to "31"
		 dd     The day of the month with leading zero if required.                          "01" to "31"
		 ddd    Abbreviated day name. Datejs.CultureInfo.abbreviatedDayNames.                  "Mon" to "Sun" 
		 dddd   The full day name. Datejs.CultureInfo.dayNames.                                "Monday" to "Sunday"
		 
		 M      The month of the year between 1-12.                                          "1" to "12"
		 MM     The month of the year with leading zero if required.                         "01" to "12"
		 MMM    Abbreviated month name. Datejs.CultureInfo.abbreviatedMonthNames.              "Jan" to "Dec"
		 MMMM   The full month name. Datejs.CultureInfo.monthNames.                            "January" to "December"
		 
		 yy     Displays the year as a maximum two-digit number.                             "99" or "07"
		 yyyy   Displays the full four digit year.                                           "1999" or "2007"
		 
		 t      Displays the first character of the A.M./P.M. designator.                    "A" or "P"
		 Datejs.CultureInfo.amDesignator or Datejs.CultureInfo.pmDesignator
		 tt     Displays the A.M./P.M. designator.                                           "AM" or "PM"
		 Datejs.CultureInfo.amDesignator or Datejs.CultureInfo.pmDesignator
		 </pre>
		 * @param {String}   A format string consisting of one or more format spcifiers [Optional].
		 * @return {String}  A string representation of the current Date object.
		 */
		public function toString (format) {
			var self = this;
			
			var p = function p(s) {
				return (s.toString().length == 1) ? "0" + s : s;
			};
			
			return format ? format.replace(/dd?d?d?|MM?M?M?|yy?y?y?|hh?|HH?|mm?|ss?|tt?|zz?z?/g, 
				function (format) {
					switch (format) {
						case "hh":
							return p(self.getHours() < 13 ? self.getHours() : (self.getHours() - 12));
						case "h":
							return self.getHours() < 13 ? self.getHours() : (self.getHours() - 12);
						case "HH":
							return p(self.getHours());
						case "H":
							return self.getHours();
						case "mm":
							return p(self.getMinutes());
						case "m":
							return self.getMinutes();
						case "ss":
							return p(self.getSeconds());
						case "s":
							return self.getSeconds();
						case "yyyy":
							return self.getFullYear();
						case "yy":
							return self.getFullYear().toString().substring(2, 4);
						case "dddd":
							return self.getDayName();
						case "ddd":
							return self.getDayName(true);
						case "dd":
							return p(self.getDate());
						case "d":
							return self.getDate().toString();
						case "MMMM":
							return self.getMonthName();
						case "MMM":
							return self.getMonthName(true);
						case "MM":
							return p((self.getMonth() + 1));
						case "M":
							return self.getMonth() + 1;
						case "t":
							return self.getHours() < 12 ? Datejs.CultureInfo.amDesignator.substring(0, 1) : Datejs.CultureInfo.pmDesignator.substring(0, 1);
						case "tt":
							return self.getHours() < 12 ? Datejs.CultureInfo.amDesignator : Datejs.CultureInfo.pmDesignator;
						case "zzz":
						case "zz":
						case "z":
							return "";
					}
				}
			) : this._toString();
		};
		
		private var _toString:Function = _thisDate.toString;

		private static var Parsing:Object;
		public var message:String;
		
		(function () {
			Datejs.Parsing = {
				Exception: function (s) { 
					this.message = "Parse error at '" + s.substring(0, 10) + " ...'"; 
				}
			};
			
			var $P = Datejs.Parsing; 
			var _ = $P.Operators = {
				//
				// Tokenizers
				//
				rtoken: function (r) { // regex token
					return function (s) {
						var mx = s.match(r);
						if (mx) { 
							return ([ mx[0], s.substring(mx[0].length) ]); 
						} else { 
							throw new Error(s); 
						}
					};
				},
				token: function (s) { // whitespace-eating token
					return function (s) {
						return _.rtoken(new RegExp("^\s*" + s + "\s*"))(s);
						// Removed .strip()
						// return _.rtoken(new RegExp("^\s*" + s + "\s*"))(s).strip();
					};
				},
				stoken: function (s) { // string token
					return _.rtoken(new RegExp("^" + s)); 
				},
				
				//
				// Atomic Operators
				// 
				
				until: function (p) {
					return function (s) {
						var qx = [], rx = null;
						while (s.length) { 
							try { 
								rx = p.call(this, s); 
							} catch (e) { 
								qx.push(rx[0]); 
								s = rx[1]; 
								continue; 
							}
							break;
						}
						return [ qx, s ];
					};
				},
				many: function (p) {
					return function (s) {
						var rx = [], r = null; 
						while (s.length) { 
							try { 
								r = p.call(this, s); 
							} catch (e) { 
								return [ rx, s ]; 
							}
							rx.push(r[0]); 
							s = r[1];
						}
						return [ rx, s ];
					};
				},
				
				// generator operators -- see below
				optional: function (p) {
					return function (s) {
						var r = null; 
						try { 
							r = p.call(this, s); 
						} catch (e) { 
							return [ null, s ]; 
						}
						return [ r[0], r[1] ];
					};
				},
				not: function (p) {
					return function (s) {
						try { 
							p.call(this, s); 
						} catch (e) { 
							return [null, s]; 
						}
						throw new Error(s);
					};
				},
				ignore: function (p) {
					return p ? 
					function (s) { 
						var r = null; 
						r = p.call(this, s); 
						return [null, r[1]]; 
					} : null;
				},
				product: function () {
					var px = arguments[0], 
					qx = Array.prototype.slice.call(arguments, 1), rx = [];
					for (var i = 0 ; i < px.length ; i++) {
						rx.push(_._each(px[i], qx));
					}
					return rx;
				},
				cache: function (rule) { 
					var cache = {}, r = null; 
					return function (s) {
						try { 
							r = cache[s] = (cache[s] || rule.call(this, s)); 
						} catch (e) { 
							r = cache[s] = e; 
						}
						if (r instanceof $P.Exception) { 
							throw r; 
						} else { 
							return r; 
						}
					};
				},
				
				// vector operators -- see below
				any: function () {
					var px = arguments;
					return function (s) { 
						var r = null;
						for (var i = 0; i < px.length; i++) { 
							if (px[i] == null) { 
								continue; 
							}
							try { 
								r = (px[i].call(this, s)); 
							} catch (e) { 
								r = null; 
							}
							if (r) { 
								return r; 
							}
						} 
						throw new Error(s);
					};
				},
				_each: function () { 
					var px = arguments;
					return function (s) { 
						var rx = [], r = null;
						for (var i = 0; i < px.length ; i++) { 
							if (px[i] == null) { 
								continue; 
							}
							try { 
								r = (px[i].call(this, s)); 
							} catch (e) { 
								throw new Error(s); 
							}
							rx.push(r[0]); 
							s = r[1];
						}
						return [ rx, s]; 
					};
				},
				all: function () { 
					var px = arguments, _ = _; 
					return _._each(_.optional(px)); 
				},
				
				// delimited operators
				sequence: function (px, d, c) {
					d = d || _.rtoken(/^\s*/);  
					c = c || null;
					
					if (px.length == 1) { 
						return px[0]; 
					}
					return function (s) {
						var r = null, q = null;
						var rx = []; 
						for (var i = 0; i < px.length ; i++) {
							try { 
								r = px[i].call(this, s); 
							} catch (e) { 
								break; 
							}
							rx.push(r[0]);
							try { 
								q = d.call(this, r[1]); 
							} catch (ex) { 
								q = null; 
								break; 
							}
							s = q[1];
						}
						if (!r) { 
							throw new Error(s); 
						}
						if (q) { 
							throw new Error(q[1]); 
						}
						if (c) {
							try { 
								r = c.call(this, r[1]);
							} catch (ey) { 
								throw new Error(r[1]); 
							}
						}
						return [ rx, (r?r[1]:s) ];
					};
				},
				
				//
				// Composite Operators
				//
				
				between: function (d1, p, d2) { 
					d2 = d2 || d1; 
					var _fn = _._each(_.ignore(d1), p, _.ignore(d2));
					return function (s) { 
						var rx = _fn.call(this, s);
						// ASD: r->rx
						return [[rx[0][0], rx[0][2]], rx[1]]; 
					};
				},
				list: function (p, d, c) {
					d = d || _.rtoken(/^\s*/);  
					c = c || null;
					return (p instanceof Array ?
						_._each(_.product(p.slice(0, -1), _.ignore(d)), p.slice(-1), _.ignore(c)) :
						// ASD: px->undefined
						_._each(_.many(_._each(p, _.ignore(d))), undefined, _.ignore(c)));
				},
				set: function (px, d, c) {
					d = d || _.rtoken(/^\s*/); 
					c = c || null;
					return function (s) {
						// r is the current match, best the current 'best' match
						// which means it parsed the most amount of input
						var r = null, p = null, q = null, rx = null, best = [[], s], last = false;
						
						// go through the rules in the given set
						for (var i = 0; i < px.length ; i++) {
							
							// last is a flag indicating whether this must be the last element
							// if there is only 1 element, then it MUST be the last one
							q = null; 
							p = null; 
							r = null; 
							last = (px.length == 1); 
							
							// first, we try simply to match the current pattern
							// if not, try the next pattern
							try { 
								r = px[i].call(this, s);
							} catch (e) { 
								continue; 
							}
							
							// since we are matching against a set of elements, the first
							// thing to do is to add r[0] to matched elements
							rx = [[r[0]], r[1]];
							
							// if we matched and there is still input to parse and 
							// we don't already know this is the last element,
							// we're going to next check for the delimiter ...
							// if there's none, or if there's no input left to parse
							// than this must be the last element after all ...
							if (r[1].length > 0 && ! last) {
								try { 
									q = d.call(this, r[1]); 
								} catch (ex) { 
									last = true; 
								}
							} else { 
								last = true; 
							}
							
							// if we parsed the delimiter and now there's no more input,
							// that means we shouldn't have parsed the delimiter at all
							// so don't update r and mark this as the last element ...
							if (!last && q[1].length === 0) { 
								last = true; 
							}
							
							
							// so, if this isn't the last element, we're going to see if
							// we can get any more matches from the remaining (unmatched)
							// elements ...
							if (!last) {
								
								// build a list of the remaining rules we can match against,
								// i.e., all but the one we just matched against
								var qx = []; 
								for (var j = 0; j < px.length ; j++) { 
									if (i != j) { 
										qx.push(px[j]); 
									}
								}
								
								// now invoke recursively set with the remaining input
								// note that we don't include the closing delimiter ...
								// we'll check for that ourselves at the end
								p = _.set(qx, d).call(this, q[1]);
								
								// if we got a non-empty set as a result ...
								// (otw rx already contains everything we want to match)
								if (p[0].length > 0) {
									// update current result, which is stored in rx ...
									// basically, pick up the remaining text from p[1]
									// and concat the result from p[0] so that we don't
									// get endless nesting ...
									rx[0] = rx[0].concat(p[0]); 
									rx[1] = p[1]; 
								}
							}
							
							// at this point, rx either contains the last matched element
							// or the entire matched set that starts with this element.
							
							// now we just check to see if this variation is better than
							// our best so far, in terms of how much of the input is parsed
							if (rx[1].length < best[1].length) { 
								best = rx; 
							}
							
							// if we've parsed all the input, then we're finished
							if (best[1].length === 0) { 
								break; 
							}
						}
						
						// so now we've either gone through all the patterns trying them
						// as the initial match; or we found one that parsed the entire
						// input string ...
						
						// if best has no matches, just return empty set ...
						if (best[0].length === 0) { 
							return best; 
						}
						
						// if a closing delimiter is provided, then we have to check it also
						if (c) {
							// we try this even if there is no remaining input because the pattern
							// may well be optional or match empty input ...
							try { 
								q = c.call(this, best[1]); 
							} catch (ey) { 
								throw new Error(best[1]); 
							}
							
							// it parsed ... be sure to update the best match remaining input
							best[1] = q[1];
						}
						
						// if we're here, either there was no closing delimiter or we parsed it
						// so now we have the best match; just return it!
						return best;
					};
				},
				forward: function (gr, fname) {
					return function (s) { 
						return gr[fname].call(this, s); 
					};
				},
				
				//
				// Translation Operators
				//
				replace: function (rule, repl) {
					return function (s) { 
						var r = rule.call(this, s); 
						return [repl, r[1]]; 
					};
				},
				process: function (rule, fn) {
					return function (s) {  
						var r = rule.call(this, s); 
						return [fn.call(this, r[0]), r[1]]; 
					};
				},
				min: function (min, rule) {
					return function (s) {
						var rx = rule.call(this, s); 
						if (rx[0].length < min) { 
							throw new Error(s); 
						}
						return rx;
					};
				}
			};
			
			
			// Generator Operators And Vector Operators
			
			// Generators are operators that have a signature of F(R) => R,
			// taking a given rule and returning another rule, such as 
			// ignore, which parses a given rule and throws away the result.
			
			// Vector operators are those that have a signature of F(R1,R2,...) => R,
			// take a list of rules and returning a new rule, such as each.
			
			// Generator operators are converted (via the following _generator
			// function) into functions that can also take a list or array of rules
			// and return an array of new rules as though the function had been
			// called on each rule in turn (which is what actually happens).
			
			// This allows generators to be used with vector operators more easily.
			// Example:
			// each(ignore(foo, bar)) instead of each(ignore(foo), ignore(bar))
			
			// This also turns generators into vector operators, which allows
			// constructs like:
			// not(cache(foo, bar))
			
			var _generator = function (op) {
				return function () {
					var args = null, rx = [];
					if (arguments.length > 1) {
						args = Array.prototype.slice.call(arguments);
					} else if (arguments[0] instanceof Array) {
						args = arguments[0];
					}
					if (args) { 
						for (var i = 0, px = args.shift() ; i < px.length ; i++) {
							args.unshift(px[i]); 
							rx.push(op.apply(null, args)); 
							args.shift();
							return rx;
						} 
					} else { 
						return op.apply(null, arguments); 
					}
				};
			};
			
			var gx = "optional not ignore cache".split(/\s/);
			
			for (var i = 0 ; i < gx.length ; i++) { 
				_[gx[i]] = _generator(_[gx[i]]); 
			}
			
			var _vector = function (op) {
				return function () {
					if (arguments[0] instanceof Array) { 
						return op.apply(null, arguments[0]); 
					} else { 
						return op.apply(null, arguments); 
					}
				};
			};
			
			var vx = "each any all".split(/\s/);
			
			for (var j = 0 ; j < vx.length ; j++) { 
				_[vx[j]] = _vector(_[vx[j]]); 
			}
			
		}());
		
		private static function flattenAndCompact (ax) { 
			var rx = []; 
			for (var i = 0; i < ax.length; i++) {
				if (ax[i] instanceof Array) {
					rx = rx.concat(flattenAndCompact(ax[i]));
				} else { 
					if (ax[i]) { 
						rx.push(ax[i]); 
					}
				}
			}
			return rx;
		};
		
		private static var Grammar = {};
		
		private static var Translator = {
			hour: function (s) { 
				return function () { 
					this._thisDate.hour = Number(s); 
				}; 
			},
			minute: function (s) { 
				return function () { 
					this._thisDate.minute = Number(s); 
				}; 
			},
			second: function (s) { 
				return function () { 
					this._thisDate.second = Number(s); 
				}; 
			},
			meridian: function (s) { 
				return function () { 
					this._thisDate.meridian = s.slice(0, 1).toLowerCase(); 
				}; 
			},
			timezone: function (s) {
				return function () {
					var n = s.replace(/[^\d\+\-]/g, "");
					if (n.length) { 
						this._thisDate.timezoneOffset = Number(n); 
					} else { 
						this._thisDate.timezone = s.toLowerCase(); 
					}
				};
			},
			day: function (x) { 
				var s = x[0];
				return function () { 
					this._thisDate.day = Number(s.match(/\d+/)[0]); 
				};
			}, 
			month: function (s) {
				return function () {
					this._thisDate.month = ((s.length == 3) ? Datejs.getMonthNumberFromName(s) : (Number(s) - 1));
				};
			},
			year: function (s) {
				return function () {
					var n = Number(s);
					this._thisDate.year = ((s.length > 2) ? n : 
						(n + (((n + 2000) < Datejs.CultureInfo.twoDigitYearMax) ? 2000 : 1900))); 
				};
			},
			rday: function (s) { 
				return function () {
					switch (s) {
						case "yesterday": 
							this._thisDate.days = -1;
							break;
						case "tomorrow":  
							this._thisDate.days = 1;
							break;
						case "today": 
							this._thisDate.days = 0;
							break;
						case "now": 
							this._thisDate.days = 0; 
							this._thisDate.now = true; 
							break;
					}
				};
			},
			finishExact: function (x) {  
				x = (x instanceof Array) ? x : [ x ]; 
				
				var now = new Datejs();
				
				this._thisDate.year = now.getFullYear(); 
				this._thisDate.month = now.getMonth(); 
				this._thisDate.day = 1; 
				
				this._thisDate.hour = 0; 
				this._thisDate.minute = 0; 
				this._thisDate.second = 0;
				
				for (var i = 0 ; i < x.length ; i++) { 
					if (x[i]) { 
						x[i].call(this); 
					}
				} 
				
				this._thisDate.hour = (this._thisDate.meridian == "p" && this._thisDate.hour < 13) ? this._thisDate.hour + 12 : this._thisDate.hour;
				
				if (this._thisDate.day > Datejs.getDaysInMonth(this._thisDate.year, this._thisDate.month)) {
					throw new RangeError(this._thisDate.day + " is not a valid value for days.");
				}
				
				var r = new Datejs(this._thisDate.year, this._thisDate.month, this._thisDate.day, this._thisDate.hour, this._thisDate.minute, this._thisDate.second);
				
				if (this._thisDate.timezone) { 
					r.set({ timezone: this._thisDate.timezone }); 
				} else if (this._thisDate.timezoneOffset) { 
					r.set({ timezoneOffset: this._thisDate.timezoneOffset }); 
				}
				return r;
			},			
			finish: function (x) {
				x = (x instanceof Array) ? flattenAndCompact(x) : [ x ];
				
				if (x.length === 0) { 
					return null; 
				}
				
				for (var i = 0 ; i < x.length ; i++) { 
					if (typeof x[i] == "function") {
						x[i].call(this); 
					}
				}
				
				if (this._thisDate.now) { 
					return new Datejs(); 
				}
				
				var today = new Date(); // Datejs.today(); 
				var method = null;
				
				var expression = !!(this._thisDate.days != null || this.orient || this.operator);
				if (expression) {
					var gap, mod, orient;
					orient = ((this.orient == "past" || this.operator == "subtract") ? -1 : 1);
					
					if (this._thisDate.weekday) {
						this._thisDate.unit = "day";
						gap = (Datejs.getDayNumberFromName(this._thisDate.weekday) - today.getDay());
						mod = 7;
						this._thisDate.days = gap ? ((gap + (orient * mod)) % mod) : (orient * mod);
					}
					if (this._thisDate.month) {
						this._thisDate.unit = "month";
						gap = (this._thisDate.month - today.getMonth());
						mod = 12;
						this._thisDate.months = gap ? ((gap + (orient * mod)) % mod) : (orient * mod);
						this._thisDate.month = null;
					}
					if (!this._thisDate.unit) { 
						this._thisDate.unit = "day"; 
					}
					if (this[this._thisDate.unit + "s"] == null || this.operator != null) {
						if (!this._thisDate.value) { 
							this._thisDate.value = 1;
						}
						
						if (this._thisDate.unit == "week") { 
							this._thisDate.unit = "day"; 
							this._thisDate.value = this._thisDate.value * 7; 
						}
						
						this[this._thisDate.unit + "s"] = this._thisDate.value * orient;
					}
					return today.add(this);
				} else {
					if (this._thisDate.meridian && this._thisDate.hour) {
						this._thisDate.hour = (this._thisDate.hour < 13 && this._thisDate.meridian == "p") ? this._thisDate.hour + 12 : this._thisDate.hour;			
					}
					if (this._thisDate.weekday && !this._thisDate.day) {
						this._thisDate.day = (today.addDays((Datejs.getDayNumberFromName(this._thisDate.weekday) - today.getDay()))).getDate();
					}
					if (this._thisDate.month && !this._thisDate.day) { 
						this._thisDate.day = 1; 
					}
					return today.set(this);
				}
			}
		};
		
		(function(){
			var _ = Datejs.Parsing.Operators, g = Datejs.Grammar, t = Datejs.Translator, _fn;
			
			g.datePartDelimiter = _.rtoken(/^([\s\-\.\,\/\x27]+)/); 
			g.timePartDelimiter = _.stoken(":");
			g.whiteSpace = _.rtoken(/^\s*/);
			g.generalDelimiter = _.rtoken(/^(([\s\,]|at|on)+)/);
			
			var _C = {};
			g.ctoken = function (keys) {
				var fn = _C[keys];
				if (! fn) {
					var c = Datejs.CultureInfo.regexPatterns;
					var kx = keys.split(/\s+/), px = []; 
					for (var i = 0; i < kx.length ; i++) {
						px.push(_.replace(_.rtoken(c[kx[i]]), kx[i]));
					}
					fn = _C[keys] = _.any.apply(null, px);
				}
				return fn;
			};
			g.ctoken2 = function (key) { 
				return _.rtoken(Datejs.CultureInfo.regexPatterns[key]);
			};
			
			// hour, minute, second, meridian, timezone
			g.h = _.cache(_.process(_.rtoken(/^(0[0-9]|1[0-2]|[1-9])/), t.hour));
			g.hh = _.cache(_.process(_.rtoken(/^(0[0-9]|1[0-2])/), t.hour));
			g.H = _.cache(_.process(_.rtoken(/^([0-1][0-9]|2[0-3]|[0-9])/), t.hour));
			g.HH = _.cache(_.process(_.rtoken(/^([0-1][0-9]|2[0-3])/), t.hour));
			g.m = _.cache(_.process(_.rtoken(/^([0-5][0-9]|[0-9])/), t.minute));
			g.mm = _.cache(_.process(_.rtoken(/^[0-5][0-9]/), t.minute));
			g.s = _.cache(_.process(_.rtoken(/^([0-5][0-9]|[0-9])/), t.second));
			g.ss = _.cache(_.process(_.rtoken(/^[0-5][0-9]/), t.second));
			g.hms = _.cache(_.sequence([g.H, g.mm, g.ss], g.timePartDelimiter));
			
			// _.min(1, _.set([ g.H, g.m, g.s ], g._t));
			g.t = _.cache(_.process(g.ctoken2("shortMeridian"), t.meridian));
			g.tt = _.cache(_.process(g.ctoken2("longMeridian"), t.meridian));
			g.z = _.cache(_.process(_.rtoken(/^(\+|\-)?\s*\d\d\d\d?/), t.timezone));
			g.zz = _.cache(_.process(_.rtoken(/^(\+|\-)\s*\d\d\d\d/), t.timezone));
			g.zzz = _.cache(_.process(g.ctoken2("timezone"), t.timezone));
			g.timeSuffix = _._each(_.ignore(g.whiteSpace), _.set([ g.tt, g.zzz ]));
			g.time = _._each(_.optional(_.ignore(_.stoken("T"))), g.hms, g.timeSuffix);
			
			// days, months, years
			g.d = _.cache(_.process(_._each(_.rtoken(/^([0-2]\d|3[0-1]|\d)/), 
				_.optional(g.ctoken2("ordinalSuffix"))), t.day));
			g.dd = _.cache(_.process(_._each(_.rtoken(/^([0-2]\d|3[0-1])/), 
				_.optional(g.ctoken2("ordinalSuffix"))), t.day));
			g.ddd = g.dddd = _.cache(_.process(g.ctoken("sun mon tue wed thu fri sat"), 
				function (s) { 
					return function () { 
						this._thisDate.weekday = s; 
					}; 
				}
			));
			g.M = _.cache(_.process(_.rtoken(/^(1[0-2]|0\d|\d)/), t.month));
			g.MM = _.cache(_.process(_.rtoken(/^(1[0-2]|0\d)/), t.month));
			g.MMM = g.MMMM = _.cache(_.process(
				g.ctoken("jan feb mar apr may jun jul aug sep oct nov dec"), t.month));
			g.y = _.cache(_.process(_.rtoken(/^(\d\d?)/), t.year));
			g.yy = _.cache(_.process(_.rtoken(/^(\d\d)/), t.year));
			g.yyy = _.cache(_.process(_.rtoken(/^(\d\d?\d?\d?)/), t.year));
			g.yyyy = _.cache(_.process(_.rtoken(/^(\d\d\d\d)/), t.year));
			
			// rolling these up into general purpose rules
			_fn = function () { 
				return _._each(_.any.apply(null, arguments), _.not(g.ctoken2("timeContext")));
			};
			
			g.day = _fn(g.d, g.dd); 
			g.month = _fn(g.M, g.MMM); 
			g.year = _fn(g.yyyy, g.yy);
			
			// relative date / time expressions
			g.orientation = _.process(g.ctoken("past future"), 
				function (s) { 
					return function () { 
						this.orient = s; 
					}; 
				}
			);
			g.operator = _.process(g.ctoken("add subtract"), 
				function (s) { 
					return function () { 
						this.operator = s; 
					}; 
				}
			);  
			g.rday = _.process(g.ctoken("yesterday tomorrow today now"), t.rday);
			g.unit = _.process(g.ctoken("minute hour day week month year"), 
				function (s) { 
					return function () { 
						this._thisDate.unit = s; 
					}; 
				}
			);
			g.value = _.process(_.rtoken(/^\d\d?(st|nd|rd|th)?/), 
				function (s) { 
					return function () { 
						this._thisDate.value = s.replace(/\D/g, ""); 
					}; 
				}
			);
			g.expression = _.set([ g.rday, g.operator, g.value, g.unit, g.orientation, g.ddd, g.MMM ]);
			
			// pre-loaded rules for different date part order preferences
			_fn = function () { 
				return  _.set(arguments, g.datePartDelimiter); 
			};
			g.mdy = _fn(g.ddd, g.month, g.day, g.year);
			g.ymd = _fn(g.ddd, g.year, g.month, g.day);
			g.dmy = _fn(g.ddd, g.day, g.month, g.year);
			g.date = function (s) { 
				return (((g[Datejs.CultureInfo.dateElementOrder] || g.mdy) as Function).call(this, s));
			}; 
			
			// parsing date format specifiers - ex: "h:m:s tt" 
			// this little guy will generate a custom parser based
			// on the format string, ex: g.format("h:m:s tt")
			g.format = _.process(_.many(
				_.any(
					// translate format specifiers into grammar rules
					_.process(
						_.rtoken(/^(dd?d?d?|MM?M?M?|yy?y?y?|hh?|HH?|mm?|ss?|tt?|zz?z?)/), 
						function (fmt) { 
							if (g[fmt]) { 
								return g[fmt]; 
							} else { 
								throw Datejs.Parsing.Exception(fmt); 
							}
						}
					),
					// translate separator tokens into token rules
					_.process(
						_.rtoken(/^[^dMyhHmstz]+/), // all legal separators 
						function (s) { 
							return _.ignore(_.stoken(s)); 
						} 
					)
				)), 
				// construct the parser ...
				function (rules) { 
					return _.process(_._each.apply(null, rules), t.finishExact); 
				}
			);
			
			var _F = {
				//"M/d/yyyy": function (s) { 
				//	var m = s.match(/^([0-2]\d|3[0-1]|\d)\/(1[0-2]|0\d|\d)\/(\d\d\d\d)/);
				//	if (m!=null) { 
				//		var r =  [ t.month.call(this,m[1]), t.day.call(this,m[2]), t.year.call(this,m[3]) ];
				//		r = t.finishExact.call(this,r);
				//		return [ r, "" ];
				//	} else {
				//		throw new Datejs.Parsing.Exception(s);
				//	}
				//}
				//"M/d/yyyy": function (s) { return [ new Datejs(Datejs._parse(s)), ""]; }
			}; 
			var _get = function (f) { 
				return _F[f] = (_F[f] || g.format(f)[0]);      
			};
			
			g.formats = function (fx) {
				if (fx instanceof Array) {
					var rx = []; 
					for (var i = 0 ; i < fx.length ; i++) {
						rx.push(_get(fx[i])); 
					}
					return _.any.apply(null, rx);
				} else { 
					return _get(fx); 
				}
			};
			
			// check for these formats first
			g._formats = g.formats([
				"yyyy-MM-ddTHH:mm:ss",
				"ddd, MMM dd, yyyy H:mm:ss tt",
				"ddd MMM d yyyy HH:mm:ss zzz",
				"d"
			]);
			
			// starting rule for general purpose grammar
			g._start = _.process(_.set([ g.date, g.time, g.expression ], 
				g.generalDelimiter, g.whiteSpace), t.finish);
			
			// real starting rule: tries selected formats first, 
			// then general purpose rule
			g.start = function (s) {
				try { 
					var r = g._formats.call({}, s); 
					if (r[1].length === 0) {
						return r; 
					}
				} catch (e) {}
				return g._start.call({}, s);
			};
		}());
		
		public static var _parse:Function = Datejs.parse;
		
		/**
		 * Converts the specified string value into its JavaScript Date equivalent using CultureInfo specific format information.
		 * 
		 * Example
		 <pre><code>
		 ///////////
		 // Dates //
		 ///////////
		 
		 // 15-Oct-2004
		 var d1 = Datejs.parse("10/15/2004");
		 
		 // 15-Oct-2004
		 var d1 = Datejs.parse("15-Oct-2004");
		 
		 // 15-Oct-2004
		 var d1 = Datejs.parse("2004.10.15");
		 
		 //Fri Oct 15, 2004
		 var d1 = Datejs.parse("Fri Oct 15, 2004");
		 
		 ///////////
		 // Times //
		 ///////////
		 
		 // Today at 10 PM.
		 var d1 = Datejs.parse("10 PM");
		 
		 // Today at 10:30 PM.
		 var d1 = Datejs.parse("10:30 P.M.");
		 
		 // Today at 6 AM.
		 var d1 = Datejs.parse("06am");
		 
		 /////////////////////
		 // Dates and Times //
		 /////////////////////
		 
		 // 8-July-2004 @ 10:30 PM
		 var d1 = Datejs.parse("July 8th, 2004, 10:30 PM");
		 
		 // 1-July-2004 @ 10:30 PM
		 var d1 = Datejs.parse("2004-07-01T22:30:00");
		 
		 ////////////////////
		 // Relative Dates //
		 ////////////////////
		 
		 // Returns today's Datejs. The string "today" is culture specific.
		 var d1 = Datejs.parse("today");
		 
		 // Returns yesterday's Datejs. The string "yesterday" is culture specific.
		 var d1 = Datejs.parse("yesterday");
		 
		 // Returns the date of the next thursday.
		 var d1 = Datejs.parse("Next thursday");
		 
		 // Returns the date of the most previous monday.
		 var d1 = Datejs.parse("last monday");
		 
		 // Returns today's day + one year.
		 var d1 = Datejs.parse("next year");
		 
		 ///////////////
		 // Date Math //
		 ///////////////
		 
		 // Today + 2 days
		 var d1 = Datejs.parse("t+2");
		 
		 // Today + 2 days
		 var d1 = Datejs.parse("today + 2 days");
		 
		 // Today + 3 months
		 var d1 = Datejs.parse("t+3m");
		 
		 // Today - 1 year
		 var d1 = Datejs.parse("today - 1 year");
		 
		 // Today - 1 year
		 var d1 = Datejs.parse("t-1y"); 
		 
		 
		 /////////////////////////////
		 // Partial Dates and Times //
		 /////////////////////////////
		 
		 // July 15th of this year.
		 var d1 = Datejs.parse("July 15");
		 
		 // 15th day of current day and year.
		 var d1 = Datejs.parse("15");
		 
		 // July 1st of current year at 10pm.
		 var d1 = Datejs.parse("7/1 10pm");
		 </code></pre>
		 *
		 * @param {String}   The string value to convert into a Date object [Required]
		 * @return {Date}    A Date object or null if the string cannot be converted into a Datejs.
		 */
		public static function parse (s) {
			var r = null; 
			if (!s) { 
				return null; 
			}
			try { 
				r = Datejs.Grammar.start.call({}, s); 
			} catch (e) { 
				return null; 
			}
			return ((r[1].length === 0) ? r[0] : null);
		};
		
		public static function getParseFunction (fx) {
			var fn = Datejs.Grammar.formats(fx);
			return function (s) {
				var r = null;
				try { 
					r = fn.call({}, s); 
				} catch (e) { 
					return null; 
				}
				return ((r[1].length === 0) ? r[0] : null);
			};
		};
		/**
		 * Converts the specified string value into its JavaScript Date equivalent using the specified format {String} or formats {Array} and the CultureInfo specific format information.
		 * The format of the string value must match one of the supplied formats exactly.
		 * 
		 * Example
		 <pre><code>
		 // 15-Oct-2004
		 var d1 = Datejs.parseExact("10/15/2004", "M/d/yyyy");
		 
		 // 15-Oct-2004
		 var d1 = Datejs.parse("15-Oct-2004", "M-ddd-yyyy");
		 
		 // 15-Oct-2004
		 var d1 = Datejs.parse("2004.10.15", "yyyy.MM.dd");
		 
		 // Multiple formats
		 var d1 = Datejs.parseExact("10/15/2004", [ "M/d/yyyy" , "MMMM d, yyyy" ]);
		 </code></pre>
		 *
		 * @param {String}   The string value to convert into a Date object [Required].
		 * @param {Object}   The expected format {String} or an array of expected formats {Array} of the date string [Required].
		 * @return {Date}    A Date object or null if the string cannot be converted into a Datejs.
		 */
		public static function parseExact (s, fx) { 
			return Datejs.getParseFunction(fx)(s); 
		};
	}
}
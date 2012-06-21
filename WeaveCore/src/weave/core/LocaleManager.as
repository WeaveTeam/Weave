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

package weave.core
{
	import flash.net.SharedObject;
	
	import mx.resources.ResourceManager;
	import mx.utils.StringUtil;
	
	import weave.api.core.ILocaleManager;

	/**
	 * @author adufilie
	 */
	public class LocaleManager implements ILocaleManager
	{
		// BEGIN TEMPORARY SOLUTION
		public function LocaleManager()
		{
			// load previously stored translation data
			var obj:SharedObject = SharedObject.getLocal('Weave.lang');
			importLocalizations(obj.data[LOCALIZATIONS]);
			setLocale(obj.data[LOCALE]);
			
			WeaveLangSharedObject = obj;
		}
		
		private static const LOCALIZATIONS:String = '_localizations';
		private static const LOCALE:String = '_locale';
		private var WeaveLangSharedObject:SharedObject = null;
		private function saveSharedObject():void
		{
			if (WeaveLangSharedObject)
			{
				// save translation data
				WeaveLangSharedObject.data[LOCALIZATIONS] = getAllLocalizations();
				WeaveLangSharedObject.data[LOCALE] = getLocale();
				WeaveLangSharedObject.flush();
			}
		}
		// END TEMPORARY SOLUTION
		
		
		private var _localizations:Object = {};
		private var _locale:String = null;
		private var _supportedLocales:Object = {};
		private var _gotLocaleChain:Boolean = false;
		
		/**
		 * This returns a list of all supported locales.
		 */
		public function getAllLocales():Array
		{
			var result:Array = [];
			var locale:String;
			for (locale in _supportedLocales)
				result.push(locale);
			
			if (!_gotLocaleChain)
			{
				// get initial list of locales
				var locales:Array = ResourceManager.getInstance().localeChain;
				for each (locale in locales)
					initializeLocale(locale);
				if (locales) // may be null
					_gotLocaleChain = true;
			}
			
			result.sort();
			return result;
		}
		
		/**
		 * This will return the two-dimensional lookup table of string localizations: (original_text -> (locale -> localized_text))
		 */
		public function getAllLocalizations():Object
		{
			return _localizations;
		}
		
		/**
		 * This will import a new set of localizations and merge with/replace existing localizations.
		 * @param localizationTable A 2-dimensional lookup table: (original_text -> (locale -> localized_text))
		 */		
		public function importLocalizations(newData:Object):void
		{
			for (var text:String in newData)
			{
				if (!_localizations.hasOwnProperty(text))
					_localizations[text] = {};
				
				var existingLookup:Object = _localizations[text];
				var newLookup:Object = newData[text];
				for (var locale:String in newLookup)
				{
					_supportedLocales[locale] = locale;
					existingLookup[locale] = newLookup[locale];
				}
			}
			saveSharedObject();
		}
		
		/**
		 * This will register a single translation for a piece of text.
		 * @param originalText
		 * @param locale
		 * @param localizedText
		 */
		public function registerTranslation(originalText:String, locale:String, localizedText:String):void
		{
			_supportedLocales[locale] = locale;
			if (originalText)
			{
				if (!_localizations.hasOwnProperty(originalText))
					_localizations[originalText] = {};
				
				if (StringUtil.trim(localizedText))
					_localizations[originalText][locale] = localizedText;
				else
					delete _localizations[originalText][locale];
				saveSharedObject();
			}
		}
		
		public function clearAllLocalizations():void
		{
			_localizations = {};
			WeaveLangSharedObject.clear();
		}
		/**
		 * This will get the active locale used by the localize() function.
		 */
		public function getLocale():String
		{
			if (!_locale)
				setLocale(ResourceManager.getInstance().localeChain[0]);
			return _locale;
		}
		
		/**
		 * This will set the default locale used by the localize() function.
		 * @param locale Specifies the locale.
		 */
		public function setLocale(locale:String):void
		{
			if (!locale)
				return;
			
			_supportedLocales[locale] = locale;
			_locale = locale;
			
			saveSharedObject();
		}
		
		/**
		 * This will set the default locale used by the localize() function.
		 * @param locale Specifies the locale.
		 */
		public function initializeLocale(locale:String):void
		{
			registerTranslation(null, locale, null);
		}
		
		/**
		 * This will look up the localized version of a piece of text.
		 * @param text The original text as specified by the developer.
		 * @param language The desired language.
		 * @return The text in the desired language, or the original text if no localization exists.
		 */
		public function localize(text:String, locale:String = null):String
		{
			// if locale is not specified, we should keep trying after failure
			var keepTrying:Boolean = (locale == null);
			
			if (!locale)
				locale = _locale;
			
			var result:String = null;
			if (_localizations.hasOwnProperty(text))
			{
				result = _localizations[text][locale] as String;
			}
			else
			{
				// make the original text appear in the lookup table even though there are no translations available yet.
				_localizations[text] = {};
			}
			
			if (result == null && keepTrying && locale != 'piglatin')
			{
				for each (locale in ResourceManager.getInstance().localeChain)
				{
					// since locale is specified, keepTrying will be false in recursive call
					result = localize(text, locale);
					// stop when we find a translation
					if (result != null)
						break;
				}
			}

			// if we couldn't find an alternate translation, just return the original text
			if (result == null && keepTrying)
			{
				// for testing
				if (locale == 'piglatin')
					return makePigLatins(text);
	
				result = text;
			}
			
			//trace('localize(',arguments,') = ',result);
			return result;
		}
		
		//-------------------------------------------------------------
		// for testing
		private function makePigLatins(words:String):String
		{
			var r:String = '';
			for each (var word:String in words.split(' '))
				r += ' ' + makePigLatin(word);
			return r.substr(1);
		}
		private function makePigLatin(word:String):String
		{
			var firstVowelPosition:int = word.length;
			var vowels:Array = ["a", "e", "i", "o", "u", "y"];
			for each (var l:String in vowels)
			{
				if (word.indexOf(l) < firstVowelPosition && word.indexOf(l) != -1)
					firstVowelPosition = word.indexOf(l);
			}
			return  word.substring(firstVowelPosition, word.length) +
				word.substring(0, firstVowelPosition) +
				"ay";
		}
	}
}

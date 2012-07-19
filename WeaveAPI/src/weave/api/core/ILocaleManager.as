/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.core
{
	/**
	 * @author adufilie
	 */
	public interface ILocaleManager
	{
		/**
		 * This returns a list of all supported locales.
		 */
		function getAllLocales():Array;
		
		/**
		 * This will return the two-dimensional lookup table of string localizations: (original_text -> (locale -> localized_text))
		 */
		function getAllLocalizations():Object;
		
		/**
		 * This will import a new set of localizations and merge with/replace existing localizations.
		 * @param localizationTable A 2-dimensional lookup table: (original_text -> (locale -> localized_text))
		 */		
		function importLocalizations(newData:Object):void;
		
		/**
		 * This will register a single translation for a piece of text.
		 * @param originalText
		 * @param locale
		 * @param localizedText
		 */
		function registerTranslation(originalText:String, locale:String, localizedText:String):void;
		
		function clearAllLocalizations():void;
		
		function removeEntry(originalText:String):void;
		
		/**
		 * This will get the active locale used by the localize() function.
		 */
		function getLocale():String;
		
		/**
		 * This will set the default locale used by the localize() function.
		 * @param locale Specifies the locale.
		 */
		function setLocale(locale:String):void;
		
		/**
		 * This will set the default locale used by the localize() function.
		 * @param locale Specifies the locale.
		 */
		function initializeLocale(locale:String):void;
		
		/**
		 * This will look up the localized version of a piece of text.
		 * @param text The original text as specified by the developer.
		 * @param language The desired language.
		 * @return The text in the desired language, or the original text if no localization exists.
		 */
		function localize(text:String, locale:String = null):String;
	}
}

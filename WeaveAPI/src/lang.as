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

package
{
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;

	/**
	 * This is a convenient global function for retrieving localized text.
	 * Sample syntax:
	 *     lang("hello world")
	 * 
	 * You can also specify a format string with parameters which will be passed to StringUtil.substitute():
	 *     lang("{0} and {1}", first, second)
	 * 
	 * @param text The original text or format string to translate.
	 * @param parameters Parameters to be passed to StringUtil.substitute() if the text is to be treated as a format string.
	 */
	public function lang(text:String, ...parameters):String
	{
		var newText:String = WeaveAPI.LocaleManager.localize(text);
		
		try
		{
			if (WeaveAPI.LocaleManager.getLocale() == 'developer')
			{
				parameters.unshift(text);
				return 'lang("' + parameters.join('", "') + '")';
			}
		}
		catch (e:Error)
		{
		}
		
		if (parameters.length)
		{
			parameters.unshift(newText);
			return StringUtil.substitute.apply(null, parameters);
		}
		
		return newText;
	}
}

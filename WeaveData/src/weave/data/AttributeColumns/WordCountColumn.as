/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.data.AttributeColumns
{
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.utils.WordProcessingUtils;
	
	/**
	 * This column is defined by two columns of Text-Based data: words and frequency.
	 * 
	 * @author jfallon
	 */
	public class WordCountColumn extends AbstractAttributeColumn implements IAttributeColumn
	{
		public function WordCountColumn()
		{
		}
		
		/**
		 * This is the data that defines the column.
		 * The data should be a text file.
		 */
		public const wordData:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		
		private var _wordToFreqMap:Object = null; // This maps a word (String) to a frequency.
		private var _words:Array = new Array(); // list of words (Strings)
		private var _keys:Array = new Array(); // list of IQualifiedKey objects
			
		/**
		 * This value is true when the data changed and the lookup tables need to be recreated.
		 */
		private var dirty:Boolean = true;
		
		/**
		 * This function gets called when Word Data changes.
		 */
		private function invalidate():void
		{
			dirty = true;
		}
		
		/**
		 * This function generates an array of all the words from the text, and a mapping showing word frequency.
		 */
		private function validate():void
		{
			// replace the previous _keyToIndexMap with a new empty one
			_wordToFreqMap = new Object();
			_words.length = 0;
			if( wordData.value != null )
				WordProcessingUtils.getWordFrequencies(wordData.value, _wordToFreqMap, _words);
			_keys = WeaveAPI.QKeyManager.getQKeys(STRING_KEY_TYPE, _words);
			
			dirty = false;	
		}
		
		/**
		 * This function returns the list of String values which are all the words in the given document.
		 */
		override public function get keys():Array
		{
			// refresh the data if necessary
			if (dirty)
				validate();
			
			return _keys;
		}
		
		public static const STRING_KEY_TYPE:String = 'String';
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(qkey:IQualifiedKey):Boolean
		{
			// refresh the data if necessary
			if (dirty)
				validate();
			
			if (qkey.keyType != STRING_KEY_TYPE)
				return false;

			var word:String = qkey.localName;
			return _wordToFreqMap[word] != undefined;
		}
		
		/**
		 * This function returns the corresponding numeric value for a given word.
		 */
		override public function getValueFromKey(qkey:IQualifiedKey, dataType:Class=null):*
		{
			// refresh the data if necessary
			if (dirty)
				validate();
			
			if (qkey.keyType != STRING_KEY_TYPE)
				return undefined;

			var word:String = qkey.localName;
			return _wordToFreqMap[word];
		}
	}
}

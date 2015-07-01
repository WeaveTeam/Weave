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

package weave.core
{
	/**
	 * LinkableBoolean, LinkableString and LinkableNumber contain simple, immutable data types.  LinkableXML
	 * is an exception because it contains an XML object that can be manipulated.  Changes to the internal
	 * XML object cannot be detected automatically, so a detectChanges() function is provided.  However, if
	 * two LinkableXML objects have the same internal XML object, modifying the internal XML of one object
	 * would inadvertently modify the internal XML of another.  To avoid this situation, LinkableXML creates
	 * a copy of the XML that you set as the session state.
	 * 
	 * @author adufilie
	 * @see weave.core.LinkableVariable
	 */
	public class LinkableXML extends LinkableVariable
	{
		public function LinkableXML()
		{
			super(String, verifyXMLString);
		}
		
		private function verifyXMLString(value:String):Boolean
		{
			if (value == null)
				return true;
			
			try {
				XML(value);
				return true;
			}
			catch (e:*) { }
			return false;
		}

		/**
		 * This function will run the callbacks attached to this LinkableXML if the session state has changed.
		 * This function should be called if the XML is modified without calling set value() or setSessionState().
		 */
		override public function detectChanges():void
		{
			value = value;
		}

		/**
		 * This is the sessioned XML value for this object.
		 */
		public function get value():XML
		{
			// validate local XML version of the session state String if necessary
			if (_prevTriggerCount != triggerCounter)
			{
				_prevTriggerCount = triggerCounter;
				_sessionStateXML = null;
				try
				{
					if (_sessionStateInternal) // false if empty string (prefer null over empty xml)
						_sessionStateXML = XML(_sessionStateInternal);
				}
				catch (e:Error)
				{
					// xml parsing failed, so keep null
				}
			}
			return _sessionStateXML;
		}
		/**
		 * This will save a COPY of the value passed in to prevent multiple LinkableXML objects from having the same internal XML object.
		 * @param value An XML to copy and save as the sessioned value for this object.
		 */		
		public function set value(value:XML):void
		{
			var str:String = value ? value.toXMLString() : null;
			setSessionState(str);
		}
		
		override public function setSessionState(value:Object):void
		{
			if (value && value.hasOwnProperty(XML_STRING))
				value = value[XML_STRING];
			if (value is XML)
				value = (value as XML).toXMLString();
			super.setSessionState(value);
		}
		
		override public function getSessionState():Object
		{
			// return an XMLString wrapper object for use with WeaveXMLEncoder.
			var result:Object = {};
			result[XML_STRING] = _sessionStateExternal || null;
			return result;
		}
		
		public static const XML_STRING:String = "XMLString";

		/**
		 * This is used to store an XML value, which is separate from the actual session state String.
		 */
		private var _sessionStateXML:XML = null;
		
		/**
		 * This is the trigger count at the time when _sessionStateXML was last updated.
		 */		
		private var _prevTriggerCount:uint = triggerCounter;
		
		/**
		 * Converts a session state object to XML the same way a LinkableXML object would.
		 */
		public static function xmlFromState(state:Object):XML
		{
			if (state && state.hasOwnProperty(XML_STRING))
				state = state[XML_STRING];
			if (!state)
				return null;
			return XML(state);
		}
	}
}

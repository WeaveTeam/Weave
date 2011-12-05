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
	import mx.utils.ObjectUtil;
	
	/**
	 * LinkableBoolean, LinkableString and LinkableNumber contain simple, immutable data types.  LinkableXML
	 * is an exception because it contains an XML object that can be manipulated.  Changes to the internal
	 * XML object cannot be detected automatically, so a detectChanges() function is provided.  However, if
	 * two LinkableXML objects have the same internal XML object, modifying the internal XML of one object
	 * would inadvertently modify the internal XML of another.  To avoid this situation, LinkableXML creates
	 * a copy of the XML that you set as the session state.
	 * 
	 * @author adufilie
	 */
	public class LinkableXML extends LinkableVariable
	{
		public function LinkableXML(allowNull:Boolean = true)
		{
			super(String, allowNull ? null : notNull);

//			if (defaultValue != null)
//			{
//				delayCallbacks();
//				value = defaultValue;
//				// Resume callbacks one frame later when we know it is possible for
//				// other classes to have a pointer to this object and retrieve the value.
//				StageUtils.callLater(this, resumeCallbacks, null, false);
//			}
		}
		
		private function notNull(value:Object):Boolean
		{
			return value != null;
		}

		/**
		 * This function will run the callbacks attached to this LinkableXML if the session state has changed.
		 * This function should be called if the XML is modified without calling set value() or setSessionState().
		 */
		public function detectChanges():void
		{
			value = _sessionStateXML;
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
				try
				{
					_sessionStateXML = XML(_sessionState);
				}
				catch (e:Error)
				{
					_sessionStateXML = null;
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
			setSessionState(value && value.toXMLString());
		}

		/**
		 * This is used to store an XML value, which is separate from the actual session state String.
		 */
		private var _sessionStateXML:XML = null;
		
		/**
		 * This is the trigger count at the time when _sessionStateXML was last updated.
		 */		
		private var _prevTriggerCount:int = triggerCounter;
	}
}

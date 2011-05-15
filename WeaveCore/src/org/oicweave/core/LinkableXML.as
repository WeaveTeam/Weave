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

package org.oicweave.core
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
		public function LinkableXML(defaultValue:XML = null, verifier:Function = null)
		{
			super(XML, verifier);
			addImmediateCallback(this, saveXMLString);

			if (defaultValue != null)
			{
				delayCallbacks();
				value = defaultValue;
				// Resume callbacks one frame later when we know it is possible for
				// other classes to have a pointer to this object and retrieve the value.
				StageUtils.callLater(this, resumeCallbacks, null, false);
			}
		}

		/**
		 * This function will run the callbacks attached to this LinkableXML if the session state has changed.
		 * This function should be called if the XML is modified without calling set value() or setSessionState().
		 */
		public function detectChanges():void
		{
			setSessionState(_sessionState);
		}

		/**
		 * This is the sessioned XML value for this object.
		 */
		public function get value():XML
		{
			return _sessionState;
		}
		/**
		 * This will save a COPY of the value passed in to prevent multiple LinkableXML objects from having the same internal XML object.
		 * @param value An XML to copy and save as the sessioned value for this object.
		 */		
		public function set value(value:XML):void
		{
			setSessionState(value);
		}

		/**
		 * This is used to store the result of toXMLString() on the session state whenever it changes.
		 * This value is used when comparing to other session states.
		 */
		private var _prevStateString:String = null;

		/**
		 * This function gets called as the first callback and saves the current XML as a String for later comparisons.
		 */		
		private function saveXMLString():void
		{
			_prevStateString = (_sessionState is XML) ? (_sessionState as XML).toXMLString() : null;
		}
		
		/**
		 * If this function receives a String, it will try to cast as an XML before saving it.
		 * If this function receives an XML, it will save a copy instead of the original.
		 * @param value The new sessioned XML value to copy.
		 */
		override public function setSessionState(value:Object):void
		{
			try
			{
				if (value is String)
					value = XML(value);
				else if (value is XML)
					value = (value as XML).copy(); // make a copy to prevent multiple LinkableXML objects from having the same internal XML object.
			}
			catch (e:Error) { } // do nothing if cast fails
			
			super.setSessionState(value);
		}

		/**
		 * @param otherSessionState Another session state to compare with the session state of this object.
		 * @return true if the other session state is equal to the session state previously set.
		 */
		override protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			if (_sessionState == null || otherSessionState == null)
				return _sessionState == otherSessionState;
			if ((_sessionState is XML) && (otherSessionState is XML))
				return _prevStateString == (otherSessionState as XML).toXMLString();
			return false;
		}
	}
}

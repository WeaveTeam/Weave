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


package weave.services.wms
{
	import flash.utils.Dictionary;

	/**
	 * This class is a collection of static objects and methods regarding the
	 * valid serivces provided for WMS layers.
	 * 
	 * @author kmonico
	 */
	public final class WMSProviders
	{
		{ /** BEGIN STATIC CODE BLOCK **/
			_providersToSRS[NASA] = OnEarthProvider.IMAGE_PROJECTION_SRS;
			_providersToSRS[BLUE_MARBLE_MAP] = ModestMapsWMS.IMAGE_PROJECTION_SRS;
			_providersToSRS[OPEN_STREET_MAP] = ModestMapsWMS.IMAGE_PROJECTION_SRS;
			_providersToSRS[MAPQUEST] = ModestMapsWMS.IMAGE_PROJECTION_SRS;
			_providersToSRS[MAPQUEST_AERIAL] = ModestMapsWMS.IMAGE_PROJECTION_SRS;
				
			/*_providersToSRS[MICROSOFT1] = ModestMapsWMS.IMAGE_PROJECTION_SRS;
			_providersToSRS[MICROSOFT2] = ModestMapsWMS.IMAGE_PROJECTION_SRS;
			_providersToSRS[MICROSOFT3] = ModestMapsWMS.IMAGE_PROJECTION_SRS;*/
		} /** END STATIC CODE BLOCK **/
		
		/**
		 * Gets the valid names of WMS Providers.
		 */
		public static function get providers():Array
		{
			var result:Array = [];

			for (var key:String in _providersToSRS)
				result.push(key);
			
			result.sort();
			return result;
		}
		
		/**
		 * This function will get the SRS code for the WMS provider.
		 */
		public static function getSRS(provider:String):String
		{
			var temp:String = _providersToSRS[provider] as String;
			
			// should not occur
			if (temp == null)
				return '';
						
			return temp;
		}

		public static const NASA:String = 'NASA OnEarth';
		public static const BLUE_MARBLE_MAP:String = 'Blue Marble Map';
		public static const OPEN_STREET_MAP:String = 'Open Street Map';
		public static const MAPQUEST:String = 'Open MapQuest';
		public static const MAPQUEST_AERIAL:String = 'Open MapQuest Aerial';
		
		/*public static const MICROSOFT1:String = 'Microsoft Aerial';
		public static const MICROSOFT2:String = 'Microsoft RoadMap';
		public static const MICROSOFT3:String = 'Microsoft Hybrid';*/
		private static const _providersToSRS:Dictionary = new Dictionary();

	}
}
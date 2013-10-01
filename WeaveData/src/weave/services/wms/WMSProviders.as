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
	public final class WMSProviders
	{
		public static const providers:Array = [
			OPEN_STREET_MAP,
			MAPQUEST,
			MAPQUEST_AERIAL,
			STAMEN_TONER,
			STAMEN_WATERCOLOR,
			BLUE_MARBLE_MAP,
			NASA,
			CUSTOM_MAP
		];
		
		public static const NASA:String = 'NASA OnEarth';
		public static const BLUE_MARBLE_MAP:String = 'Blue Marble Map';
		public static const OPEN_STREET_MAP:String = 'Open Street Map';
		public static const MAPQUEST:String = 'Open MapQuest';
		public static const MAPQUEST_AERIAL:String = 'Open MapQuest Aerial';
		public static const STAMEN_TONER:String = 'Stamen Toner';
		public static const STAMEN_TERRAIN:String = 'Stamen Terrain';
		public static const STAMEN_WATERCOLOR:String = 'Stamen Watercolor';
		public static const CUSTOM_MAP:String = 'Custom Map';
	}
}
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
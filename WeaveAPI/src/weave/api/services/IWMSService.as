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

package weave.api.services
{
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.primitives.IBounds2D;

	/**
	 * This is the interface for WMS services. We require each WMS service to provide
	 * at least two public functions. Any callbacks added to this service will run when
	 * a new image is downloaded.
	 * 
	 * @author kmonico
	 */
	public interface IWMSService extends ILinkableObject
	{
		/**
		 * This function will cancel all the pending requests.
		 */
		function cancelPendingRequests():void;

		/**
		 * This function will return the number of pending requests.
		 * 
		 * @return The number of pending requests for this service.
		 */ 
		function getNumPendingRequests():int;
			
		/**
		 * This function will make the requests for new images.
		 * 
		 * @param dataBounds The bounds of the data.
		 * @param screenBounds The bounds of the screen. This is required to determine the appropriate zoom level.
		 * @param preferLowerQuality A boolean indicating whether the service should request images which are one quality level lower.
		 * @param layerLowerQuality If true, all lower quality tiles will be returned in order in addition to the correct quality level.
		 * @return An array of downloaded images. The array is filled with lower quality images followed by
		 * the requested quality. These images may overlap.
		 */
		function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, preferLowerQuality:Boolean = false, layerLowerQuality:Boolean = false):Array;
		
		/**
		 * Outputs the bounds which contains all valid tile requests. If a tile request is
		 * not contained inside this bounds, the request is invalid.
		 */ 
		function getAllowedBounds(output:IBounds2D):void;
		
		/**
		 * This function will return the SRS code of the tile requests.
		 * 
		 * @return A string corresponding to a projection SRS code.
		 * eg) EPSG:4326
		 */
		function getProjectionSRS():String;
		
		/**
		 * This function will set the provider of the service.
		 *
		 * @param provider The name of the provider. 
		 */
		function setProvider(provider:String):void;
		
		/**
		 * Gets the provider object.
		 * 
		 * @return An IMapProvider object if there is one.
		 */
		function getProvider():*;

		/**
		 * Get a string which contains copyright information for the
		 * service.
		 * 
		 * @return A string which contains the copyright information 
		 * for the provider.
		 */ 
		function getCreditInfo():String;
	}
}
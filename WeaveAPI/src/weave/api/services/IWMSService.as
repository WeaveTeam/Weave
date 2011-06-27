/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package weave.api.services
{
	import weave.api.core.ICallbackCollection;
	import weave.api.primitives.IBounds2D;

	/**
	 * This is the interface for WMS services. We require each WMS service to provide
	 * at least two public functions. Any callbacks added to this service will run when
	 * a new image is downloaded.
	 * 
	 * @author kmonico
	 */
	public interface IWMSService extends ICallbackCollection
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
		 * @param screenBounds The bounds of the screen. This is required to determine
		 * the appropriate zoom level.
		 * @param lowerQuality A boolean indicating whether the service should request images
		 * which are one quality level lower.
		 * @return An array of downloaded images. The array is filled with lower quality images followed by
		 * the requested quality. These images may overlap.
		 */
		function requestImages(dataBounds:IBounds2D, screenBounds:IBounds2D, lowerQuality:Boolean = false):Array;
		
		/**
		 * Return the bounds which contains all valid tile requests.
		 * 
		 * @return A Bounds2D object which covers the entire bounds. If a tile request is 
		 * not contained inside this bounds, the request is invalid.
		 */ 
		function getAllowedBounds():IBounds2D;
		
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
		 * Reset the associated tiling index for this service.
		 */
		function clearTilingIndex():void;
			
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
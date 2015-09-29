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

package weave.api.data
{
	public interface IDataSourceWithAuthentication extends IDataSource
	{
		/**
		 * Check this to determine if authenticate() may be necessary.
		 * @return true if authenticate() may be necessary.
		 */
		function get authenticationSupported():Boolean;
		
		/**
		 * Check this to determine if authenticate() must be called.
		 * @return true if authenticate() should be called.
		 */
		function get authenticationRequired():Boolean;
		
		/**
		 * The username that has been successfully authenticated.
		 */
		function get authenticatedUser():String;
		
		/**
		 * Authenticates with the server.
		 * @param user
		 * @param pass
		 */
		function authenticate(user:String, pass:String):void;
	}
}

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

package weave.beans;

import java.io.*;

public class UploadFileFilter implements FileFilter {

	private String[] fileTypes;
	
	public UploadFileFilter(String... params)
	{
		fileTypes = new String[params.length];
		for( int i = 0; i < fileTypes.length; i++ )
			fileTypes[i] = params[i];
		
	}
	
	public boolean accept(File file)
	{
		for(String extension : fileTypes) {
			if( file.getName().toLowerCase().endsWith(extension.toLowerCase())) {
				return true;
			}
		}
		return false;
	}

}

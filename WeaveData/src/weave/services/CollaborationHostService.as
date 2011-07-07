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

package weave.services
{
	import com.hurlant.util.asn1.parser.integer;
	
	import flash.events.EventDispatcher;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	
	import org.igniterealtime.xiff.auth.*;
	import org.igniterealtime.xiff.bookmark.*;
	import org.igniterealtime.xiff.conference.*;
	import org.igniterealtime.xiff.core.*;
	import org.igniterealtime.xiff.data.*;
	import org.igniterealtime.xiff.data.register.RegisterExtension;
	import org.igniterealtime.xiff.events.*;
	import org.igniterealtime.xiff.exception.*;
	import org.igniterealtime.xiff.filter.*;
	import org.igniterealtime.xiff.im.*;
	import org.igniterealtime.xiff.privatedata.*;
	import org.igniterealtime.xiff.util.*;
	import org.igniterealtime.xiff.vcard.*;
	
	import weave.core.ErrorManager;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	
	/** 
	 * This class will define the service that the collaboration Host provides.
	 * That is to say the service of conflicting Diff resolution and sending collaboration
	 * room updates to room members, and anyone who joins the room.
	 **/
	public class CollaborationHostService extends CollaborationService
	{
		public function CollaborationHostService()
		{
		}	
	}
}
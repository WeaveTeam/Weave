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

package weave.resources
{
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
	
	import weave.api.core.ILinkableObject;
	import weave.api.setSessionState;
	import weave.core.WeaveXMLDecoder;

	public class _MobileDemo
	{
/*		
		[Embed(source="/weave/resources/sample.mp3")]
		public static var sndCls:Class;
		public static var snd:Sound = new sndCls() as Sound; 
		public static var sndChannel:SoundChannel;
		
		playSound();
		
		public static function playSound():void {
			sndChannel=snd.play();
		}   
		
		public static function stopSound():void {
			sndChannel.stop();
		}   
		
*/		
		
		
		
		
		
		
		
		
		public static function setXMLState(target:ILinkableObject, asset:Class):void
		{
			var instance:Object = new asset();
			var bytes:ByteArray = instance as ByteArray;
			var state:Object = new XML( bytes.readUTFBytes( bytes.length ) );
			state = WeaveXMLDecoder.decode(XML(state));
			setSessionState(target, state);
		}
		
		[Embed(source="/weave/resources/demoGlobalState.xml", mimeType="application/octet-stream")]
		public static const globalStateXML:Class;
		[Embed(source="/weave/resources/demoVisState.xml", mimeType="application/octet-stream")]
		public static const visStateXML:Class;
	}
}

/*
* Dispatched when a pod view state changes.
*/

package com.adobe.devnet.events
{
import com.adobe.devnet.view.Pod;

import flash.events.Event;

public class PodStateChangeEvent extends Event
{
	// Pod states
	public static var MINIMIZE:String = "minimize";
	public static var RESTORE:String = "restore";
	public static var MAXIMIZE:String = "maximize";
	public static var CLOSE:String = "close"; // added for Weave
	
	public function PodStateChangeEvent(type:String)
	{
		super(type, true, true);
	}
}
}
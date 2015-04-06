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

package weave.compiler
{
	import avmplus.DescribeType;
	
	import flash.debugger.enterDebugger;
	import flash.net.getClassByAlias;
	import flash.net.navigateToURL;
	import flash.net.registerClassAlias;
	import flash.net.sendToURL;
	import flash.profiler.profile;
	import flash.profiler.showRedrawRegions;
	import flash.sampler.clearSamples;
	import flash.sampler.getGetterInvocationCount;
	import flash.sampler.getInvocationCount;
	import flash.sampler.getMemberNames;
	import flash.sampler.getSampleCount;
	import flash.sampler.getSamples;
	import flash.sampler.getSetterInvocationCount;
	import flash.sampler.getSize;
	import flash.sampler.isGetterSetter;
	import flash.sampler.pauseSampling;
	import flash.sampler.startSampling;
	import flash.sampler.stopSampling;
	import flash.system.fscommand;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.describeType;
	import flash.utils.escapeMultiByte;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	import flash.utils.unescapeMultiByte;

	/**
	 * This provides a set of static functions for use with the Weave Compiler.
	 * 
	 * @author adufilie
	 */
	public class GlobalLib
	{
		public static const describeTypeJSON:Function = avmplus.DescribeType.getInfo;
		
		public static const enterDebugger:Function = flash.debugger.enterDebugger;
		
		public static const getClassByAlias:Function = flash.net.getClassByAlias;
		public static const navigateToURL:Function = flash.net.navigateToURL;
		public static const registerClassAlias:Function = flash.net.registerClassAlias;
		public static const sendToURL:Function = flash.net.sendToURL;
		
		public static const profile:Function = flash.profiler.profile;
		public static const showRedrawRegions:Function = flash.profiler.showRedrawRegions;

		public static const clearSamples:Function = flash.sampler.clearSamples;
		public static const getGetterInvocationCount:Function = flash.sampler.getGetterInvocationCount;
		public static const getInvocationCount:Function = flash.sampler.getInvocationCount;
		public static const getMemberNames:Function = flash.sampler.getMemberNames;
		public static const getSampleCount:Function = flash.sampler.getSampleCount;
		public static const getSamples:Function = flash.sampler.getSamples;
		public static const getSetterInvocationCount:Function = flash.sampler.getSetterInvocationCount;
		public static const getSize:Function = flash.sampler.getSize;
		public static const isGetterSetter:Function = flash.sampler.isGetterSetter;
		public static const pauseSampling:Function = flash.sampler.pauseSampling;
		public static const startSampling:Function = flash.sampler.startSampling;
		public static const stopSampling:Function = flash.sampler.stopSampling;

		public static const fscommand:Function = flash.system.fscommand;
		
		public static const clearInterval:Function = flash.utils.clearInterval;
		public static const clearTimeout:Function = flash.utils.clearTimeout;
		public static const describeType:Function = flash.utils.describeType;
		public static const escapeMultiByte:Function = flash.utils.escapeMultiByte;
		public static const getDefinitionByName:Function = flash.utils.getDefinitionByName;
		public static const getQualifiedClassName:Function = flash.utils.getQualifiedClassName;
		public static const getQualifiedSuperclassName:Function = flash.utils.getQualifiedSuperclassName;
		public static const getTimer:Function = flash.utils.getTimer;
		public static const setInterval:Function = flash.utils.setInterval;
		public static const setTimeout:Function = flash.utils.setTimeout;
		public static const unescapeMultiByte:Function = flash.utils.unescapeMultiByte;
	}
}

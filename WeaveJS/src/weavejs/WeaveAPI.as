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

package weavejs
{
	import weavejs.api.core.IClassRegistry;
	import weavejs.api.core.ILocaleManager;
	import weavejs.api.core.IProgressIndicator;
	import weavejs.api.core.IScheduler;
	import weavejs.api.core.ISessionManager;
	import weavejs.api.data.IAttributeColumnCache;
	import weavejs.api.data.ICSVParser;
	import weavejs.api.data.IProjectionManager;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.api.data.IStatisticsCache;
	import weavejs.api.service.IURLRequestUtils;
	import weavejs.api.ui.IEditorManager;
	import weavejs.core.ClassRegistryImpl;
	
	/**
	 * Static functions for managing implementations of Weave framework classes.
	 * 
	 * @author adufilie
	 */
	public class WeaveAPI
	{
		/**
		 * For use with StageUtils.startTask(); this priority is used for things that MUST be done before anything else.
		 * Tasks having this priority will take over the scheduler and prevent any other asynchronous task from running until it is completed.
		 */
		public static const TASK_PRIORITY_IMMEDIATE:uint = 0;
		/**
		 * For use with StageUtils.startTask().
		 */
		public static const TASK_PRIORITY_HIGH:uint = 1;
		/**
		 * For use with StageUtils.startTask().
		 */
		public static const TASK_PRIORITY_NORMAL:uint = 2;
		/**
		 * For use with StageUtils.startTask().
		 */
		public static const TASK_PRIORITY_LOW:uint = 3;
		
		/**
		 * Static instance of ClassRegistry
		 */
		private static var _classRegistry:ClassRegistryImpl = null;
		
		/**
		 * This is the singleton instance of the registered ISessionManager implementation.
		 */
		public static function get ClassRegistry():IClassRegistry
		{
			if (!_classRegistry)
				_classRegistry = new ClassRegistryImpl();
			return _classRegistry;
		}
		
		/**
		 * This is the singleton instance of the registered ISessionManager implementation.
		 */
		public static function get SessionManager():ISessionManager
		{
			return (_classRegistry || ClassRegistry).singletonInstances[ISessionManager]
				|| _classRegistry.getSingletonInstance(ISessionManager);
		}
		
		/**
		 * This is the singleton instance of the registered IScheduler implementation.
		 */
		public static function get Scheduler():IScheduler
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IScheduler]
				|| _classRegistry.getSingletonInstance(IScheduler);
		}
		
//		/**
//		 * This is the singleton instance of the registered IStageUtils implementation.
//		 */
//		public static function get StageUtils():IStageUtils
//		{
//			return (_classRegistry || ClassRegistry).singletonInstances[IStageUtils]
//				|| _classRegistry.getSingletonInstance(IStageUtils);
//		}

		/**
		 * This is the singleton instance of the registered IProgressIndicator implementation.
		 */
		public static function get ProgressIndicator():IProgressIndicator
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IProgressIndicator]
				|| _classRegistry.getSingletonInstance(IProgressIndicator);
		}
		
		/**
		 * This is the singleton instance of the registered IAttributeColumnCache implementation.
		 */
		public static function get AttributeColumnCache():IAttributeColumnCache
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IAttributeColumnCache]
				|| _classRegistry.getSingletonInstance(IAttributeColumnCache);
		}
		
		/**
		 * This is the singleton instance of the registered IStatisticsCache implementation.
		 */
		public static function get StatisticsCache():IStatisticsCache
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IStatisticsCache]
				|| _classRegistry.getSingletonInstance(IStatisticsCache);
		}
		
		/**
		 * This is the singleton instance of the registered IProjectionManager implementation.
		 */
		public static function get ProjectionManager():IProjectionManager
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IProjectionManager]
				|| _classRegistry.getSingletonInstance(IProjectionManager);
		}
		
		/**
		 * This is the singleton instance of the registered IQualifiedKeyManager implementation.
		 */
		public static function get QKeyManager():IQualifiedKeyManager
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IQualifiedKeyManager]
				|| _classRegistry.getSingletonInstance(IQualifiedKeyManager);
		}
		
		/**
		 * This is the singleton instance of the registered ICSVParser implementation.
		 */
		public static function get CSVParser():ICSVParser
		{
			return (_classRegistry || ClassRegistry).singletonInstances[ICSVParser]
				|| _classRegistry.getSingletonInstance(ICSVParser);
		}
		
		/**
		 * This is the singleton instance of the registered IURLRequestUtils implementation.
		 */
		public static function get URLRequestUtils():IURLRequestUtils
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IURLRequestUtils]
				|| _classRegistry.getSingletonInstance(IURLRequestUtils);
		}
		
		/**
		 * This is the singleton instance of the registered ILocaleManager implementation.
		 */
		public static function get LocaleManager():ILocaleManager
		{
			return (_classRegistry || ClassRegistry).singletonInstances[ILocaleManager]
				|| _classRegistry.getSingletonInstance(ILocaleManager);
		}
		/**
		 * This is the singleton instance of the registered IEditorManager implementation.
		 */
		public static function get EditorManager():IEditorManager
		{
			return (_classRegistry || ClassRegistry).singletonInstances[IEditorManager]
				|| _classRegistry.getSingletonInstance(IEditorManager);
		}
	}
}

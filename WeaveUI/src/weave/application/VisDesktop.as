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

package weave.application
{
	import mx.containers.Canvas;
	import mx.core.IVisualElement;
	
	import spark.components.Group;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.newLinkableChild;
	import weave.api.ui.ILinkableContainer;
	import weave.api.ui.ILinkableLayoutManager;
	import weave.core.UIUtils;
	import weave.ui.BasicLinkableLayoutManager;
	import weave.ui.CenteredImage;
	import weave.utils.DrawUtils;
	
	internal class VisDesktop extends Canvas implements ILinkableContainer, IDisposableObject
	{
		public function VisDesktop()
		{
		}
		
		internal function get workspace():Group
		{
			return manager as Group;
		}
		
		private var backgroundImage:CenteredImage = new CenteredImage();
		private var manager:ILinkableLayoutManager = null;
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			backgroundImage.source = Weave.WeaveBackgroundImage;
			backgroundImage.alpha = 0.1;
			backgroundImage.percentWidth = 100;
			backgroundImage.percentHeight = 100;
			addElement(backgroundImage);
			Weave.properties.showBackgroundImage.addImmediateCallback(this, toggleBackgroundImage);
			Weave.properties.dashboardMode.addImmediateCallback(this, toggleBackgroundImage, true);
			
			manager = newLinkableChild(this, BasicLinkableLayoutManager);
			//manager = newLinkableChild(this, WeavePodLayoutManager);
			addElement(manager as IVisualElement);
			
			UIUtils.linkLayoutManager(manager, getLinkableChildren());
		}
		
		private function toggleBackgroundImage():void
		{
			backgroundImage.visible = Weave.properties.showBackgroundImage.value && !Weave.properties.dashboardMode.value;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			// draw an empty rectangle so this can be the target of mouse events when no children are added.
			graphics.clear();
			DrawUtils.clearLineStyle(graphics);
			graphics.beginFill(0,0);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
		}
		
		public function getLinkableChildren():ILinkableHashMap
		{
			return WeaveAPI.globalHashMap;
		}
		
		public function dispose():void
		{
			UIUtils.unlinkLayoutManager(manager, getLinkableChildren());
		}
	}
}

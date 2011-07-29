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

package weave.primitives
{
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.SessionManager;
	
	/**
	 * This is a linkable version of a Bounds2D object.
	 * It supports two modes: center coordinates and absolute coordinates.
	 * 
	 * @author adufilie
	 */
	public class ZoomBounds implements ILinkableVariable
	{
		public function LinkableBounds2D()
		{
			useAbsoluteCoords();
		}
		
		public function getSessionState():Object
		{
			if (_useCenterCoords.value)
			{
				
			}
		}
		
		public const xMin:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yMin:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const xMax:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yMax:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public const xCenter:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yCenter:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const areaPerPixel:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		
		private const _dataBounds:IBounds2D = new Bounds2D();
		private const _screenBounds:IBounds2D = new Bounds2D();
		private const _useCenterCoords:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		private const _cc:ICallbackCollection = getCallbackCollection(this);
		
		/**
		 * This switches the session state to use absolute coordinates xMin,yMin,xMax,yMax.
		 */
		public function useAbsoluteCoords():void
		{
			_useCenterCoords.value = false; // this may trigger callbacks
		}
		
		/**
		 * This switches the session state to use center coordinates xCenter,yCenter,areaPerPixel.
		 */
		public function useCenterCoords():void
		{
			_useCenterCoords.value = true; // this may trigger callbacks
		}
		
		public function getDataBounds(outputDataBounds:IBounds2D):void
		{
			outputDataBounds.copyFrom(_dataBounds);
		}
		
		public function getScreenBounds(outputScreenBounds:IBounds2D):void
		{
			outputScreenBounds.copyFrom(_screenBounds);
		}
		
		public function setBounds(dataBounds:Bounds2D, screenBounds:IBounds2D, useCenterCoords:Boolean):void
		{
			_cc.delayCallbacks();
			if (!_dataBounds.equals(dataBounds) || (_useCenterCoords.value && !_screenBounds.equals(screenBounds)))
				_cc.triggerCallbacks();
			
			_dataBounds.copyFrom(dataBounds);
			_screenBounds.copyFrom(screenBounds);
			_useCenterCoords.value = useCenterCoords; // this may trigger callbacks
			
			_cc.resumeCallbacks();
		}
	}
}

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
	import weave.compiler.MathLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.SessionManager;
	
	/**
	 * This object defines the data bounds of a visualization, either directly with
	 * absolute coordinates or indirectly with center coordinates and a scale value.
	 * Screen coordinates are never directly specified in the session state.
	 * 
	 * @author adufilie
	 */
	public class ZoomBounds implements ILinkableVariable
	{
		public function ZoomBounds()
		{
		}
		
		private const _dataBounds:Bounds2D = new Bounds2D();
		private const _screenBounds:Bounds2D = new Bounds2D();
		private var _useCenterCoords:Boolean = false;
		
		/**
		 * The session state has two modes: absolute coordinates and center/scale coordinates.
		 * @return The current session state.
		 */		
		public function getSessionState():Object
		{
			return null;
			if (_useCenterCoords)
			{
				return {
					xMin: _dataBounds.getXMin(),
					yMin: _dataBounds.getYMin(),
					xMax: _dataBounds.getXMax(),
					yMax: _dataBounds.getYMax()
				};
			}
			else
			{
				return {
					xCenter: MathLib.roundSignificant(_dataBounds.getXCenter()),
					yCenter: MathLib.roundSignificant(_dataBounds.getXCenter()),
					areaPerPixel: MathLib.roundSignificant(_dataBounds.getArea() / _screenBounds.getArea())
				};
			}
		}
		
		/**
		 * The session state can be specified in two ways: absolute coordinates and center/scale coordinates.
		 * @param The new session state.
		 */		
		public function setSessionState(state:Object):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			if (state == null)
			{
				if (!_dataBounds.isUndefined())
					cc.triggerCallbacks();
				_dataBounds.reset();
			}
			else
			{
				var usedCenterCoords:Boolean = false;
				if (state.hasOwnProperty("xCenter"))
				{
					if (MathLib.roundSignificant(_dataBounds.getXCenter()) != state.xCenter)
					{
						_dataBounds.setXCenter(state.xCenter);
						cc.triggerCallbacks();
					}
					usedCenterCoords = true;
				}
				if (state.hasOwnProperty("yCenter"))
				{
					if (MathLib.roundSignificant(_dataBounds.getYCenter()) != state.yCenter)
					{
						_dataBounds.setYCenter(state.yCenter);
						cc.triggerCallbacks();
					}
					usedCenterCoords = true;
				}
				if (state.hasOwnProperty("areaPerPixel"))
				{
					if (MathLib.roundSignificant(_dataBounds.getArea() / _screenBounds.getArea()) != state.areaPerPixel)
					{
						var scale:Number = Math.sqrt(state.areaPerPixel);
						_dataBounds.centeredResize(_screenBounds.getXCoverage() * scale, _screenBounds.getYCoverage() * scale);
						cc.triggerCallbacks();
					}
					usedCenterCoords = true;
				}
				
				if (!usedCenterCoords)
				{
					var names:Array = ["xMin", "yMin", "xMax", "yMax"];
					for each (var name:String in names)
					{
						if (state.hasOwnProperty(name) && _dataBounds[name] != state[name])
						{
							_dataBounds[name] = state[name];
							cc.triggerCallbacks();
						}
					}
				}
			}
			
			cc.resumeCallbacks();
		}
		
		/**
		 * This function will copy the internal dataBounds to another IBounds2D.
		 * @param outputScreenBounds The destination.
		 */
		public function getDataBounds(outputDataBounds:IBounds2D):void
		{
			outputDataBounds.copyFrom(_dataBounds);
		}
		
		/**
		 * This function will copy the internal screenBounds to another IBounds2D.
		 * @param outputScreenBounds The destination.
		 */
		public function getScreenBounds(outputScreenBounds:IBounds2D):void
		{
			outputScreenBounds.copyFrom(_screenBounds);
		}
		
		/**
		 * This function will set all the information required to define the session state of the ZoomBounds.
		 * @param dataBounds The data range of a visualization.
		 * @param screenBounds The pixel range of a visualization.
		 * @param useCenterCoords If true, the session state will be defined by xCenter,yCenter,areaPerPixel.  If false, the session state will be defined by xMin,yMin,xMax,yMax.
		 */		
		public function setBounds(dataBounds:Bounds2D, screenBounds:IBounds2D, useCenterCoords:Boolean):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			if (_useCenterCoords != useCenterCoords || !_dataBounds.equals(dataBounds) || (useCenterCoords && !_screenBounds.equals(screenBounds)))
				cc.triggerCallbacks();
			
			_dataBounds.copyFrom(dataBounds);
			_screenBounds.copyFrom(screenBounds);
			_useCenterCoords = useCenterCoords;
			
			cc.resumeCallbacks();
		}
	}
}

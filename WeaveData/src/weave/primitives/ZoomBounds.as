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
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableVariable;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StandardLib;
	
	/**
	 * This object defines the data bounds of a visualization, either directly with
	 * absolute coordinates or indirectly with center coordinates and area.
	 * Screen coordinates are never directly specified in the session state.
	 * 
	 * @author adufilie
	 */
	public class ZoomBounds implements ILinkableVariable
	{
		public function ZoomBounds()
		{
		}
		
		private const _tempBounds:Bounds2D = new Bounds2D(); // reusable temporary object
		private const _dataBounds:Bounds2D = new Bounds2D();
		private const _screenBounds:Bounds2D = new Bounds2D();
		private var _useFixedAspectRatio:Boolean = false;
		
		/**
		 * The session state has two modes: absolute coordinates and centered area coordinates.
		 * @return The current session state.
		 */		
		public function getSessionState():Object
		{
			if (_useFixedAspectRatio)
			{
				return {
					xCenter: StandardLib.roundSignificant(_dataBounds.getXCenter()),
					yCenter: StandardLib.roundSignificant(_dataBounds.getYCenter()),
					area: StandardLib.roundSignificant(_dataBounds.getArea())
				};
			}
			else
			{
				return {
					xMin: _dataBounds.getXMin(),
					yMin: _dataBounds.getYMin(),
					xMax: _dataBounds.getXMax(),
					yMax: _dataBounds.getYMax()
				};
			}
		}
		
		/**
		 * The session state can be specified in two ways: absolute coordinates and centered area coordinates.
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
				var useFixedAspectRatio:Boolean = false;
				if (state.hasOwnProperty("xCenter"))
				{
					useFixedAspectRatio = true;
					if (StandardLib.roundSignificant(_dataBounds.getXCenter()) != state.xCenter)
					{
						_dataBounds.setXCenter(state.xCenter);
						cc.triggerCallbacks();
					}
				}
				if (state.hasOwnProperty("yCenter"))
				{
					useFixedAspectRatio = true;
					if (StandardLib.roundSignificant(_dataBounds.getYCenter()) != state.yCenter)
					{
						_dataBounds.setYCenter(state.yCenter);
						cc.triggerCallbacks();
					}
				}
				if (state.hasOwnProperty("area"))
				{
					useFixedAspectRatio = true;
					if (StandardLib.roundSignificant(_dataBounds.getArea()) != state.area)
					{
						// We can't change the screen area.  Adjust the dataBounds to match the specified area.
						/*
							Ad = Wd * Hd
							Wd/Hd = Ws/Hs
							Wd = Hd * Ws/Hs
							Ad = Hd^2 * Ws/Hs
							Hd^2 = Ad * Hs/Ws
							Hd = sqrt(Ad * Hs/Ws)
						*/
						
						var Ad:Number = state.area;
						var HsWsRatio:Number = _screenBounds.getYCoverage() / _screenBounds.getXCoverage();
						if (!isFinite(HsWsRatio)) // handle case if screenBounds is undefined
							HsWsRatio = 1;
						var Hd:Number = Math.sqrt(Ad * HsWsRatio);
						var Wd:Number = Ad / Hd;
						_dataBounds.centeredResize(Wd, Hd);
						cc.triggerCallbacks();
					}
				}
				
				if (!useFixedAspectRatio)
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
				
				_useFixedAspectRatio = useFixedAspectRatio;
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
		 * @param useFixedAspectRatio Set this to true if you want to maintain an identical x and y data-per-pixel ratio.
		 */		
		public function setBounds(dataBounds:IBounds2D, screenBounds:IBounds2D, useFixedAspectRatio:Boolean):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			if (_useFixedAspectRatio != useFixedAspectRatio || !_dataBounds.equals(dataBounds) || (useFixedAspectRatio && !_screenBounds.equals(screenBounds)))
				cc.triggerCallbacks();
			
			_dataBounds.copyFrom(dataBounds);
			_screenBounds.copyFrom(screenBounds);
			_useFixedAspectRatio = useFixedAspectRatio;
			_fixAspectRatio();
			
			cc.resumeCallbacks();
		}
		
		/**
		 * This function will zoom to the specified dataBounds and fix the aspect ratio if necessary.
		 * @param dataBounds The bounds to zoom to.
		 * @param zoomOutIfNecessary Set this to true if you are using a fixed aspect ratio and you want the resulting fixed bounds to be expanded to include the specified dataBounds.
		 */
		public function setDataBounds(dataBounds:IBounds2D, zoomOutIfNecessary:Boolean = false):void
		{
			if (_dataBounds.equals(dataBounds))
				return;
			
			_dataBounds.copyFrom(dataBounds);
			_fixAspectRatio(zoomOutIfNecessary);
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * This function will update the screenBounds and fix the aspect ratio of the dataBounds if necessary.
		 * @param screenBounds The new screenBounds.
		 * @param useFixedAspectRatio Set this to true if you want to maintain an identical x and y data-per-pixel ratio.
		 */
		public function setScreenBounds(screenBounds:IBounds2D, useFixedAspectRatio:Boolean):void
		{
			if (_useFixedAspectRatio == useFixedAspectRatio && _screenBounds.equals(screenBounds))
				return;
			
			_useFixedAspectRatio = useFixedAspectRatio;
			_screenBounds.copyFrom(screenBounds);
			_fixAspectRatio();
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		private function _fixAspectRatio(zoomOutIfNecessary:Boolean = false):void
		{
			if (_useFixedAspectRatio)
			{
				var xScale:Number = _dataBounds.getXCoverage() / _screenBounds.getXCoverage();
				var yScale:Number = _dataBounds.getYCoverage() / _screenBounds.getYCoverage();
				if (xScale != yScale)
				{
					var scale:Number = zoomOutIfNecessary ? Math.max(xScale, yScale) : Math.sqrt(xScale * yScale);
					_dataBounds.centeredResize(_screenBounds.getXCoverage() * scale, _screenBounds.getYCoverage() * scale);
				}
			}
		}
		
		/**
		 * A scale of N means there is an N:1 correspondance of pixels to data coordinates.
		 */		
		public function getXScale():Number
		{
			return _screenBounds.getXCoverage() / _dataBounds.getXCoverage();
		}
		
		/**
		 * A scale of N means there is an N:1 correspondance of pixels to data coordinates.
		 */		
		public function getYScale():Number
		{
			return _screenBounds.getYCoverage() / _dataBounds.getYCoverage();
		}
	}
}

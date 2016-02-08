/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	public class WeavePathUI extends WeavePathData
	{
		public function WeavePathUI(weave:Weave, basePath:Array)
		{
			super(weave, basePath);
		}
		
		/**
		 * This is a shortcut for pushing the path to a plotter from the current path, which should reference a visualization tool.
		 * @param plotterName (Optional) The name of an existing or new plotter.
		 *                    If omitted and the current path points to a LayerSettings object, the corresponding plotter will be used.
		 *                    Otherwise if omitted the default plotter name ("plot") will be used.
		 * @param plotterType (Optional) The type of plotter to request if it doesn't exist yet.
		 * @return A new WeavePath object which remembers the current WeavePath as its parent.
		 */
		public function pushPlotter(plotterName:String, plotterType:Object = null):WeavePath
		{
//			var tool:WeavePath = this.weave.path(this._path[0]);
//			if (!(tool.getObject() is SimpleVisTool))
//				this._failMessage('pushPlotter', "Not a compatible visualization tool", this._path);
			
//			if (!plotterName)
//				plotterName = checkType(this, 'LayerSettings') ? this._path[this._path.length - 1] : 'plot';
			
			var tool:WeavePath = this;
			var result:WeavePath = tool.push('children', 'visualization', 'plotManager', 'plotters', plotterName);
//			result._parent = this;
			if (plotterType)
				result.request(plotterType);
			return result;
		}
	}
}

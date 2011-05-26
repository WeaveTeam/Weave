package weave.utils
{
	import weave.api.core.ILinkableObject;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndexImplementation;
	import weave.visualization.plotters.DynamicPlotter;
	import weave.visualization.plotters.GeometryPlotter;

	/**
	 * This is a static Factory for creating the implementation spatial index for a specific
	 * type of plotter.
	 * 
	 * @author kmonico
	 */
	public class SpatialIndexFactory
	{
		// TODO: make into a Singleton
		
		/**
		 * This function will return the ISpatialIndexImplementation object which implements
		 * a spatial index for a particular type of plotter.
		 * 
		 * @param plotter The IPlotter for which to get an implementation.
		 * @return An ISpatialIndexImplementation object which implements the spatial index.
		 */
		public static function getImplementation(plotter:IPlotter):ISpatialIndexImplementation
		{
			if (plotter is DynamicPlotter)
			{
				var internalObject:ILinkableObject = (plotter as DynamicPlotter).internalObject;
				if (internalObject is GeometryPlotter)
					return new GeometrySpatialIndex(internalObject);
				else 
					return new RefinedSpatialIndex(internalObject);
			}
			
			return new RefinedSpatialIndex(plotter);
		}
	}
}
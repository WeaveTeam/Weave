package weave.beans;


public class PGGeom {
	/**
	 * Bean class intended to store a row of PostGIS geometries. 
	 */

	public int gid;
	public int type;
	public double[] points;

	public PGGeom()
	{
	}
	
	// convenience constructor. variables are public. 
	public PGGeom(int numPoints, int type)
	{
		this.type = type;
		this.points = new double[numPoints*2];
	}
	
}

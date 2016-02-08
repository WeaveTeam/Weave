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

package weave.geometrystream;

import java.io.IOException;
import java.net.URL;
import java.util.List;

import org.geotools.data.FeatureReader;
import org.geotools.data.Query;
import org.geotools.data.shapefile.ShapefileDataStore;
import org.geotools.data.shapefile.ShapefileUtilities;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.AttributeDescriptor;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import com.vividsolutions.jts.geom.Geometry;

/**
 * Static functions for converting SHP files using a GeometryStreamConverter.
 * 
 * @author adufilie
 */
public class SHPGeometryStreamUtils
{
	public static void convertShapefile(GeometryStreamConverter converter, String filename, List<String> attributes) throws Exception
	{
		boolean debugTime = true;
		long startTime = System.currentTimeMillis();
		
		ShapefileDataStore dataStore = new ShapefileDataStore(new URL("file:///"+filename));
		
		try
		{
			convertFeatures(converter, dataStore, attributes);
		}
		finally
		{
			dataStore.dispose();
		}
		
		long endTime = System.currentTimeMillis();
		if (debugTime)
			System.out.println(String.format("file parsing took %s ms for %s", endTime - startTime, filename));
	}

	/**
	 * @param dataStore A ShapeFileDataStore containing geometries to convert.
	 * @param keyAttributes The names of attributes to be concatenated to generate record keys.
	 * @throws Exception
	 */
	public static void convertFeatures(GeometryStreamConverter converter, ShapefileDataStore dataStore, List<String> keyAttributes) throws Exception
	{
		SimpleFeatureType schema = dataStore.getSchema();
		int numFeatures = dataStore.getCount(Query.ALL);
		FeatureReader<SimpleFeatureType, SimpleFeature> reader = null;
		try
		{
			List<AttributeDescriptor> attrDesc = schema.getAttributeDescriptors();
			String header = "\"the_geom_id\", \"the_geom_key\"";
			for (int i = 1; i < attrDesc.size(); i++)
			{
				String colName = attrDesc.get(i).getLocalName();
				if (GeometryStreamConverter.debugDBF)
					header += ", \"" + colName + '"';
				// if any specified attribute matches colName, case insensitive, overwrite specified attribute name with name having correct case
				for (int j = 0; j < keyAttributes.size(); j++)
					if (keyAttributes.get(j).equalsIgnoreCase(colName))
						keyAttributes.set(j, colName);
			}
			// debug: read schema and print it out
			if (GeometryStreamConverter.debugDBF)
				System.out.println(header);
			
			// loop through features and parse them
			long startTime = System.currentTimeMillis(), endTime = startTime, debugInterval = 60000, nextDebugTime = startTime + debugInterval;
			int featureCount = 0;

			reader = dataStore.getFeatureReader();
			CoordinateReferenceSystem projection = schema.getCoordinateReferenceSystem(); // may be null
			String projectionWKT = projection == null ? null : projection.toWKT();
			
			while (reader.hasNext())
			{
				endTime = System.currentTimeMillis();
				if (GeometryStreamConverter.debugTime && endTime > nextDebugTime)
				{
					System.out.println(String.format("Processing %s/%s features, %s minutes elapsed", featureCount, numFeatures, (endTime - startTime)/60000.0));
					while (endTime > nextDebugTime)
						nextDebugTime += debugInterval;
				}
				convertFeature(converter, reader.next(), keyAttributes, projectionWKT);
				featureCount++;
			}
			
			if (GeometryStreamConverter.debugTime && endTime-startTime > debugInterval)
				System.out.println(String.format("Processing %s features completed in %s minutes", numFeatures, (endTime - startTime)/60000.0));
		}
		catch (OutOfMemoryError e)
		{
			e.printStackTrace();
			throw e;
		}
		finally
		{
			try {
				if (reader != null)
					reader.close();
			} catch (IOException e) { }
		}
	}
	
	private static void convertFeature(GeometryStreamConverter converter, SimpleFeature feature, List<String> keyAttributes, String projectionWKT) throws Exception
	{
		int shapeType = GeometryStreamUtils.getShapeTypeFromGeometryType(feature.getType().getType(0).getName().toString());
		// get shape key by concatenating specified attributes
		String shapeKey = "";
		for (int attrIndex = 0; attrIndex < keyAttributes.size(); attrIndex++)
		{
			Object attributeObject = feature.getAttribute(keyAttributes.get(attrIndex));
			shapeKey += ShapefileUtilities.forAttribute(attributeObject, String.class);
		}
		IFeatureGeometryStream geomStream = new JTSFeatureGeometryStream((Geometry)feature.getDefaultGeometry());
		converter.convertFeature(geomStream, shapeType, shapeKey, projectionWKT);

		/*
		if (debugDBF)
		{
			// debug: print data
			String attrs = geometryMetadata.shapeID + ", " + "\"" + shapeKey + '"';
			for (int i = 1; i < feature.getAttributeCount(); i++)
				attrs += ", \"" + feature.getAttribute(i) + '"';
			System.out.println(attrs);
		}
		if (debugCounts)
		{
			System.out.println(String.format("%s (geom %s) has %s vertices", shapeKey, i, coords.length));
		}
		*/
	}
}

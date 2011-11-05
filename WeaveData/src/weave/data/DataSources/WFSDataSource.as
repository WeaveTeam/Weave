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

package weave.data.DataSources
{
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
	import weave.core.ErrorManager;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WFSServlet;
	import weave.utils.BLGTreeUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	/**
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class WFSDataSource extends AbstractDataSource
	{
		public function WFSDataSource()
		{
			url.addImmediateCallback(this, handleURLChange);
		}
		
		public var wfsDataService:WFSServlet = null;
		
		private function handleURLChange():void
		{
			if (url.value == null)
				url.value = '/geoserver/wfs';
			wfsDataService = new WFSServlet(url.value);
		}
		
		override protected function initialize():void
		{
			// backwards compatibility
			if(_attributeHierarchy.value != null)
			{
				for each (var tag:XML in _attributeHierarchy.value.descendants("attribute"))
				{
					if (String(tag.@featureTypeName) == '')
					{
						tag.@featureTypeName = tag.@featureType;
						delete tag["@featureType"];
						tag.@dataType = _convertOldDataType(tag.@dataType);
					}
				}
			}
			
			super.initialize();
		}
		private function _convertOldDataType(value:String):String
		{
			if (value == 'Geometry')
				return DataTypes.GEOMETRY;
			if (value == 'String')
				return DataTypes.STRING;
			if (value == 'Number')
				return DataTypes.NUMBER;
			return value;
		}
		
		/**
		 * @param layerName Layer you want to query
		 * @param queryPoint Point around which to perform radius query.
		 * @param distance Value of radius
		 */
		public function radiusSearch(layerName:String, queryPoint:Point,distance:Number):AsyncToken
		{
			var filterQuery:String = "<Filter><DWithin><PropertyName>the_geom</PropertyName><Point><coordinates>" + queryPoint.y + "," + queryPoint.x + "</coordinates></Point><Distance>" + distance + "</Distance></DWithin></Filter>";
			var asyncToken:AsyncToken = wfsDataService.getFilteredQueryResult(layerName, ["STATE_FIPS"], filterQuery);
			
			return asyncToken;
		}

		/**
		 * @param subtreeNode Specifies a subtree in the hierarchy to download.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML=null):void
		{
			var query:AsyncToken;
			
			if (subtreeNode == null) // download top-level hierarchy 
			{
				query = wfsDataService.getCapabilties();

				DelayedAsyncResponder.addResponder(query, handleGetCapabilities, handleGetCapabilitiesError);
			}
			else // download a list of properties for a given featureTypeName
			{
				var dataTableName:String = subtreeNode.attribute("name").toString();
				
				query = wfsDataService.describeFeatureType(dataTableName);
				
				DelayedAsyncResponder.addResponder(query, handleDescribeFeature, handleDescribeFeatureError, subtreeNode);
			}
		}
		
		/**
		 * @param event
		 */
		private function handleGetCapabilities(event:ResultEvent, token:Object = null):void
		{
			var owsNS:String = 'http://www.opengis.net/ows';
			var wfsNS:String = 'http://www.opengis.net/wfs';
			var owsProviderName:QName = new QName(owsNS, 'ProviderName');
			var wfsFeatureTypeName:QName = new QName(wfsNS, 'FeatureType');
			var wfsDefaultSRS:QName = new QName(wfsNS, 'DefaultSRS');
			var wfsName:QName = new QName(wfsNS, 'Name');
			var wfsTitle:QName = new QName(wfsNS, 'Title');
			
			var xml:XML;
			try
			{
				xml = XML(event.result);
				var rootTitle:String = xml.descendants(owsProviderName).text().toXMLString();
				var root:XML = <hierarchy name={ rootTitle }/>;
				var featureTypeNames:XMLList = xml.descendants(wfsFeatureTypeName);
				for (var i:int = 0; i < featureTypeNames.length(); i++)
				{
					var type:XML = featureTypeNames[i];
					var defaultSRS:String = type.child(wfsDefaultSRS).text().toXMLString();
					var categoryName:String = type.child(wfsName).text().toXMLString();
					var categoryTitle:String = type.child(wfsTitle).text().toXMLString();
					var category:XML = <category name={ categoryName } title={ categoryTitle } defaultSRS={ defaultSRS }/>;
					root.appendChild(category);
				}
				_attributeHierarchy.value = root;
			}
			catch (e:Error)
			{
				reportError("Received invalid XML from WFS service at "+url.value);
				if (xml)
					trace(xml.toXMLString());
				return;
			}
		}
		
		/**
		 * @param event
		 */
		private function handleGetCapabilitiesError(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
		}
		
		/**
		 * @param event
		 * @param token This is the subtreeNode XML.
		 */
		private function handleDescribeFeature(event:ResultEvent, token:Object = null):void
		{
			var result:XML = new XML(event.result);

			var XMLSchema:String = "http://www.w3.org/2001/XMLSchema";
			// get a list of feature properties
			var rootQName:QName = new QName(XMLSchema, "complexType");
			var propertiesQName:QName = new QName(XMLSchema, "element");
			var propertiesList:XMLList = result.descendants(rootQName).descendants(propertiesQName);
			
			// define the hierarchy
			var node:XML = token as XML;

			var featureTypeName:String = node.attribute("name").toString();

			for(var i:int = 0; i < propertiesList.length(); i++)
			{
				//trace(i,propertiesList[i].toXMLString());
				var propertyName:String = propertiesList[i].attribute("name");
				var propertyType:String = propertiesList[i].attribute("type");
				// handle case for   <xs:simpleType><xs:restriction base="xs:string"><xs:maxLength value="2"/></xs:restriction></xs:simpleType>
				// convert missing propertyType to string
				if (propertyType == '')
					propertyType = "xs:string";
				var dataType:String;
				switch (propertyType)
				{
					case "gml:MultiSurfacePropertyType":
					case "gml:MultiLineStringPropertyType":
					case "gml:MultiCurvePropertyType":
					case "gml:PointPropertyType":
						dataType = DataTypes.GEOMETRY;
						break;
					case "xsd:string":
					case "xs:string":
						dataType = DataTypes.STRING;
						break;
					default:
						dataType = DataTypes.NUMBER;
				}
				/**
				 * 'keyType' is used to differentiate this feature from others.
				 * 'featureTypeName' corresponds to the feature in WFS to get data for. 
				 * 'name' corresponds to the name of a column in the WFS feature data.
				 */
				var attrNode:XML = <attribute
						dataType={ dataType }
						keyType={ featureTypeName }
						title={ propertyName }
						name={ propertyName }
						featureTypeName={ featureTypeName }
					/>;
				if (dataType == DataTypes.GEOMETRY)
				{
					var defaultSRS:String = node.@defaultSRS;
					var array:Array = defaultSRS.split(':');
					var prevToken:String = '';
					while (array.length > 2)
						prevToken = array.shift();
					var proj:String = array.join(':');
					var altProj:String = prevToken;
					if (array.length > 1)
						altProj += ':' + array[1];
					if (!WeaveAPI.ProjectionManager.projectionExists(proj) && WeaveAPI.ProjectionManager.projectionExists(altProj))
						proj = altProj;
					attrNode['@'+AttributeColumnMetadata.PROJECTION_SRS] = proj;
				}
				node.appendChild(attrNode);
			}
			_attributeHierarchy.detectChanges();
		}
		
		/**
		 * 
		 */
		private function handleDescribeFeatureError(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
		}

		/**
		 * Makes a WFS request to get a column of data specified by a hierarchy path.
		 * @param columnReference An object that contains all the information required to request the column from this IDataSource. 
		 * @param A ProxyColumn object that will be updated when the column data is ready.
		 */
		override protected function requestColumnFromSource(columnReference:IColumnReference, proxyColumn:ProxyColumn):void
		{
			var hierarchyRef:HierarchyColumnReference = columnReference as HierarchyColumnReference;
			if (!hierarchyRef)
				return handleUnsupportedColumnReference(columnReference, proxyColumn);
			
			var pathInHierarchy:XML = hierarchyRef.hierarchyPath.value;
			
			var query:AsyncToken;
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			proxyColumn.setMetadata(leafNode);
			
			var featureTypeName:String = leafNode.attribute("featureTypeName");
			var propertyNamesArray:Array = [];
			var propertyName:String = leafNode.attribute("name");
			propertyNamesArray.push(propertyName);
			query = wfsDataService.getFeature(featureTypeName, propertyNamesArray);
			var token:ColumnRequestToken = new ColumnRequestToken(pathInHierarchy, proxyColumn);
			DelayedAsyncResponder.addResponder(query, handleColumnDownload, handleColumnDownloadFail, token);
		}
		
		private function getQName(xmlContainingNamespaceInfo:XML, qname:String):QName
		{
			var array:Array = String(qname).split(":");
			if (array.length != 2)
				return null;
			var prefix:String = array[0];
			var localName:String = array[1];
			var uri:String = xmlContainingNamespaceInfo.namespace(prefix).uri;
			return new QName(uri, localName);
		}

		
		/**
		 * @param event
		 * @param token
		 */
		private function handleColumnDownload(event:ResultEvent, token:Object = null):void
		{
			var request:ColumnRequestToken = token as ColumnRequestToken;
			var hierarchyPath:XML = request.pathInHierarchy;
			var proxyColumn:ProxyColumn = request.proxyColumn;
			
			if (proxyColumn.wasDisposed)
				return;
			
			var result:XML = null;
			var i:int;
			try
			{
				var hierarchyNode:XML = HierarchyUtils.getLeafNodeFromPath(hierarchyPath);
				if (hierarchyNode == null)
				{
					trace("WARNING! Discarding downloaded column data because the path no longer exists in the hierarchy: " + hierarchyPath.toXMLString());
					return;
				}
	
				try
				{
					result = new XML(event.result);
				}
				catch (e:Error)
				{
					trace(e.getStackTrace());
				}
	
				if (result == null || result.localName().toString() == 'ExceptionReport')
					throw new Error("An invalid XML result was received from the WFS service at "+this.url.value);
	
				var featureTypeName:String = hierarchyNode.@featureTypeName; // typeName was previously stored here
				var propertyName:String = hierarchyNode.@name; // propertyName was previously stored here
				var dataType:String = hierarchyNode.@dataType;
				var keyType:String = hierarchyNode.@keyType;
	
				//trace("WFSDataSource.handleColumnDownload(): typeName=" + featureTypeName + ", propertyName=" + propertyName);
				
				var gmlURI:String = "http://www.opengis.net/gml";
	
				// get QName for record id and data XML tags
				// The typeName string is something like topp:states, where topp is the namespace and states is the layer name
				// this QName refers the nodes having the gml:id attribute
				var keyQName:QName = getQName(result, featureTypeName);
				if (keyQName == null)
				{
					trace('handleColumnDownload(): Unable to continue because featureTypeName does not have a namespace: "'+featureTypeName+'"');
					return;
				}
				var dataQName:QName = new QName(keyQName.uri, propertyName); // use same namespace as keyQName
	
				// get keys and data
				var keysList:XMLList = result.descendants(keyQName);
				var dataList:XMLList = result.descendants(dataQName);
	
				// process keys into a vector
				var keysVector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>(keysList.length());
				for(i = 0; i < keysList.length(); i++)
				{
					keysVector[i] = WeaveAPI.QKeyManager.getQKey(keyType, keysList[i].attributes());
					//trace(keysList[i].attributes() + " --> "+ dataList[i].toString());
				}
				
				// determine the data type, and create the appropriate type of IAttributeColumn
				var newColumn:IAttributeColumn;
				if (ObjectUtil.stringCompare(dataType, DataTypes.GEOMETRY, true) == 0)
				{
					newColumn = new GeometryColumn(hierarchyNode);
					var geomVector:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
					var features:XMLList = result.descendants(keyQName);
					var firstFeatureData:XML = features[0].descendants(dataQName)[0];
					var geomType:String = firstFeatureData.children()[0].name().toString();
					if (geomType == (gmlURI + "::Point"))
						geomType = GeneralizedGeometry.GEOM_TYPE_POINT;
					else if (geomType.indexOf(gmlURI + "::") == 0 && (geomType.indexOf('LineString') >= 0 || geomType.indexOf('Curve') >= 0))
						geomType = GeneralizedGeometry.GEOM_TYPE_LINE;
					else
						geomType = GeneralizedGeometry.GEOM_TYPE_POLYGON;
					var gmlPos:QName = new QName(gmlURI, geomType == GeneralizedGeometry.GEOM_TYPE_POINT ? 'pos' : 'posList');

					for (var geometryIndex:int = 0; geometryIndex < keysVector.length; geometryIndex++)
					{
						var gmlPosXMLList:XMLList = dataList[geometryIndex].descendants(gmlPos);
						var coordStr:String = '';
						for (i = 0; i < gmlPosXMLList.length(); i++)
						{
							if (i > 0)
								coordStr += ' ';
							coordStr += gmlPosXMLList[i].toString();
						}
						var coordinates:Array = coordStr.split(' ');
						
						// swap order (y,x to x,y)
						for (i = 0; i < coordinates.length; i += 2)
						{
							var temp:Number = coordinates[i+1];
							coordinates[i+1] = coordinates[i];
							coordinates[i] = temp;
						}
						
						var geometry:GeneralizedGeometry = new GeneralizedGeometry(geomType);
						
						geometry.setCoordinates(coordinates, BLGTreeUtils.METHOD_SAMPLE);
						geomVector[geometryIndex] = geometry;
					}
					(newColumn as GeometryColumn).setGeometries(keysVector, geomVector);
				}
				else if (ObjectUtil.stringCompare(dataType, DataTypes.NUMBER, true) == 0)
				{
					newColumn = new NumberColumn(hierarchyNode);
					(newColumn as NumberColumn).setRecords(keysVector, VectorUtils.copyXMLListToVector(dataList, new Vector.<Number>()));
				}
				else
				{
					newColumn = new StringColumn(hierarchyNode);
					(newColumn as StringColumn).setRecords(keysVector, VectorUtils.copyXMLListToVector(dataList, new Vector.<String>()));
				}
				// save pointer to new column inside the matching proxy column
				proxyColumn.internalColumn = newColumn;
			}
			catch (e:Error)
			{
				//var detail:String = ObjectUtil.toString(request.request) + '\n\nResult: ' + (result && result.toXMLString());
				reportError(e);
			}

		}
		
		/**
		 * handleColumnDownloadFail
		 * 
		 */
		private function handleColumnDownloadFail(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
		}
	}
}

import flash.net.URLRequest;

import weave.data.AttributeColumns.ProxyColumn;

/**
 * This object is used as a token in an AsyncResponder.
 */
internal class ColumnRequestToken
{
	public function ColumnRequestToken(pathInHierarchy:XML, proxyColumn:ProxyColumn, request:URLRequest = null)
	{
		this.pathInHierarchy = pathInHierarchy;
		this.proxyColumn = proxyColumn;
		this.request = request;
	}
	public var pathInHierarchy:XML;
	public var proxyColumn:ProxyColumn;
	public var request:URLRequest;
	public var subtreeNode:XML;
}

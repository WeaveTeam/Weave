/*
  Copyright (c) 2007-2009 Regents of the University of California.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  3.  Neither the name of the University nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGE.
*/

/* Alterations for use in Weave are (C) 2014 Philip Kovac */

package flare.data.converters
{   
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    /**
     * Converts data between GraphML markup and flare DataSet instances.
     * <a href="http://graphml.graphdrawing.org/">GraphML</a> is a
     * standardized XML format supporting graph structure and typed data
     * schemas for both nodes and edges.
     */
    public class GraphMLConverter
    {    
        // -- reader ----------------------------------------------------------
        
        public static function read(str:String):Object
        {
          var xmlnsPattern:RegExp = new RegExp("xmlns=[^\"]*\"[^\"]*\"", "gi");

          return parse(XML(str.replace(xmlnsPattern, "")));
        }
        
        /**
         * Parses a GraphML XML object into a DataSet instance.
         * @param graphml the XML object containing GraphML markup
         * @param schema a DataSchema (typically null, as GraphML contains
         *  schema information)
         * @return the parsed DataSet instance
         */
        public static function parse(graphml:XML):Object
        {
            var nodeIdLookup:Object = {};
            var nodeIdCounter:int = 0;
            var edgeIdLookup:Object = {};
            var edgeIdCounter:int = 0;
            var nodes:Array = [], n:Object;
            var edges:Array = [], e:Object;
            var id:String, sid:String, tid:String;
            var def:Object, type:int;
            var group:String, attrName:String, attrType:String;
            
            var nodeSchema:Object = {};
            var nodeKeys:Array = [];
            var edgeSchema:Object = {};
            var edgeKeys:Array = [];
            var isDirected:Boolean = DIRECTED == graphml.graph.@edgedefault;

            var schema:Object;
            var keys:Array;
            
            // set schema defaults

            nodeSchema[ID] = {name: ID, type: ATTRTYPE_STRING};

            edgeSchema[ID] = {name: ID, type: ATTRTYPE_STRING};
            edgeSchema[SOURCE] = {name: SOURCE, type: ATTRTYPE_STRING};
            edgeSchema[TARGET] = {name: TARGET, type: ATTRTYPE_STRING};
            edgeSchema[DIRECTED] = {name: DIRECTED, type: ATTRTYPE_BOOLEAN, def: isDirected};

            nodeKeys.push(ID);

            edgeKeys.push(ID);
            edgeKeys.push(SOURCE);
            edgeKeys.push(TARGET);
            edgeKeys.push(DIRECTED);
            
            // parse data schema
            for each (var key:XML in graphml..key) {
                id       = key.@[ID].toString();
                group    = key.@[FOR].toString();
                attrName = key.@[ATTRNAME].toString();
                attrType = key.@[ATTRTYPE].toString();
                def = key[DEFAULT].toString();
                def = def != null && def.length > 0
                    ? def : null;

                schema = (group==EDGE ? edgeSchema : nodeSchema);
                keys = (group==EDGE ? edgeKeys : nodeKeys);

                schema[id] = {name: attrName, type: attrType, def: def};
                keys.push(id);
            }
            
            // parse nodes
            for each (var node:XML in graphml..node) {
                id = node.@[ID].toString();

                while (!id || nodeIdLookup[id])
                {
                	id = String(nodeIdCounter++);
                }

                nodeIdLookup[id] = (n = parseData(node));
                n.id = id;
                nodes.push(n);
            }
            
            // parse edges
            for each (var edge:XML in graphml..edge) {
                id  = edge.@[ID].toString();
                sid = edge.@[SOURCE].toString();
                tid = edge.@[TARGET].toString();

				while (!id || edgeIdLookup[id])
                {
                	id = String(edgeIdCounter++);
                }
                
                // error checking
                if (!nodeIdLookup.hasOwnProperty(sid))
                    error("Edge "+id+" references unknown node: "+sid);
                if (!nodeIdLookup.hasOwnProperty(tid))
                    error("Edge "+id+" references unknown node: "+tid);
                
                edgeIdLookup[id] = (e = parseData(edge));                
                e.id = id;
                edges.push(e);
            }
            var result:Object = {};

            result.nodeSchema = nodeSchema;
            result.edgeSchema = edgeSchema;

            result.nodeKeys = nodeKeys;
            result.edgeKeys = edgeKeys;

            result.nodes = nodes;
            result.edges = edges;

            return result;
        }
        
        private static function parseData(node:XML):Object {
            var n:Object = {};
            var name:String, value:Object;
            
            // get attribute values
            for each (var attr:XML in node.@*) {
                name = attr.name().toString();
                n[name] = attr[0].toString();
            }
            
            // get data values in XML; do not convert using schema.
            for each (var data:XML in node.data) {
                name = data.@[KEY].toString();
                n[name] = data[0].toString();
            }
            
            return n;
        }
           
        // -- static helpers --------------------------------------------------        
        
        private static function error(msg:String):void {
            throw new Error(msg);
        }
        
        // -- constants -------------------------------------------------------
        
        public static const GRAPHML:String    = "graphml";
        public static const ID:String         = "id";
        public static const GRAPH:String      = "graph";
        public static const EDGEDEF:String    = "edgedefault";
        public static const DIRECTED:String   = "directed";
        public static const UNDIRECTED:String = "undirected";
        
        public static const KEY:String        = "key";
        public static const FOR:String        = "for";
        public static const ALL:String        = "all";
        public static const ATTRNAME:String   = "attr.name";
        public static const ATTRTYPE:String   = "attr.type";

        public static const ATTRTYPE_BOOLEAN:String  = "boolean";
        public static const ATTRTYPE_INT:String      = "int";
        public static const ATTRTYPE_LONG:String     = "long";
        public static const ATTRTYPE_FLOAT:String    = "float";
        public static const ATTRTYPE_DOUBLE:String   = "double";
        public static const ATTRTYPE_STRING:String   = "string";

        public static const DEFAULT:String    = "default";
        
        public static const NODE:String   = "node";
        public static const EDGE:String   = "edge";
        public static const SOURCE:String = "source";
        public static const TARGET:String = "target";
        public static const DATA:String   = "data";
        public static const TYPE:String   = "type";
        
    } // end of class GraphMLConverter
}
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
            var idx:int = str.indexOf(GRAPHML);
            if (idx > 0) {
                str = str.substr(0, idx+GRAPHML.length) + 
                    str.substring(str.indexOf(">", idx));
            }
            return parse(XML(str));
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
            var lookup:Object = {};
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
            nodeSchema[ID] = ID;
            edgeSchema[ID] = ID;
            edgeSchema[SOURCE] = SOURCE;
            edgeSchema[TARGET] = TARGET;
            edgeSchema[DIRECTED] = DIRECTED;
            
            // parse data schema
            for each (var key:XML in graphml..key) {
                id       = key.@[ID].toString();
                group    = key.@[FOR].toString();
                attrName = key.@[ATTRNAME].toString();
                def = key[DEFAULT].toString();
                def = def != null && def.length > 0
                    ? def : null;
                
                schema = (group==EDGE ? edgeSchema : nodeSchema);
                keys = (group==EDGE ? edgeKeys : nodeKeys);
                schema[id] = attrName;
                keys.push(attrName);
            }
            
            // parse nodes
            for each (var node:XML in graphml..node) {
                id = node.@[ID].toString();
                lookup[id] = (n = parseData(node, nodeSchema));
                nodes.push(n);
            }
            
            // parse edges
            for each (var edge:XML in graphml..edge) {
                id  = edge.@[ID].toString();
                sid = edge.@[SOURCE].toString();
                tid = edge.@[TARGET].toString();
                
                // error checking
                if (!lookup.hasOwnProperty(sid))
                    error("Edge "+id+" references unknown node: "+sid);
                if (!lookup.hasOwnProperty(tid))
                    error("Edge "+id+" references unknown node: "+tid);
                                
                edges.push(e = parseData(edge, edgeSchema));
            }
            var result:Object = {};

            nodeKeys.push(ID);

            edgeKeys.push(ID);
            edgeKeys.push(SOURCE);
            edgeKeys.push(TARGET);
            edgeKeys.push(DIRECTED);

            result.nodeKeys = nodeKeys;
            result.edgeKeys = edgeKeys;
            result.nodes = nodes;
            result.edges = edges;

            return result;
        }
        
        private static function parseData(node:XML, schema:Object):Object {
            var n:Object = {};
            var name:String, value:Object;
            
            // get attribute values
            for each (var attr:XML in node.@*) {
                name = attr.name().toString();
                n[name] = attr[0].toString();
            }
            
            // get data values in XML
            for each (var data:XML in node.data) {
                name = schema[data.@[KEY].toString()];
                n[name] = data[0].toString();
            }
            
            return n;
        }
           
        // -- static helpers --------------------------------------------------        
        
        private static function error(msg:String):void {
            throw new Error(msg);
        }
        
        // -- constants -------------------------------------------------------
        
        private static const GRAPHML_HEADER:String = "<graphml/>";
        //  "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"" 
        //    +" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""
        //    +" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns"
        //    +" http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">"
        //    +"</graphml>";
        
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
        public static const DEFAULT:String    = "default";
        
        public static const NODE:String   = "node";
        public static const EDGE:String   = "edge";
        public static const SOURCE:String = "source";
        public static const TARGET:String = "target";
        public static const DATA:String   = "data";
        public static const TYPE:String   = "type";
        
    } // end of class GraphMLConverter
}
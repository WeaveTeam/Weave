function weaveExternalInit()
{
	// parse window.name as configuration data with properties: id, path
    var config = JSON.parse(window.name);
    
    // get a pointer to the Weave that opened this window
    var weave = opener.document.getElementById(config.id);
    
    // assert that the path refers to an ExternalTool object
    return weave.path(config.path).request("ExternalTool");
}

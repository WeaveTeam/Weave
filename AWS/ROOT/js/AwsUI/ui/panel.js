// requires jquery ui
// requires jquery

/**
 * Portlet constructor
 * 
 * @param {string} title the title of the portlet. 
 * @param {Number} id The id of the portlet, to be used to identify the portlet.
 * @param {Object} content the content of the portlet. Dynamic content. Can be optional
 * 
 * @return {Portlet} HTML content of a portlet
 * 
 */

function portlet (title, id, content) {
	
	var _portlet = '<div class="portlet"> \
						<div class ="portlet-header">' + title + '</div> \
						<div class="portlet-content" id="' + id + '"> '+ content +'</div> \
						</div>';
	
	return _portlet;
	
}

/**
 * This function append content to the existing content of the portlet.
 * 
 * @param {Object} portlet
 * @param {Object} content
 * 
 * @return void
 */
function addContent (portlet, content) {
	
	
	

}

/**
 * This function updates the content of the portlet. It will override the existing content.
 * 
 * @param {Object} portlet
 * @param {Object} content
 * 
 */

function updateContent (portlet, content) {
	


}

/**
 * This function updates the content of the portlet. It will override the existing content.
 * 
 * @param {Object} portlet
 * @param {Object} content
 * 
 */
function updateTitle (portlet, title) {

	


}


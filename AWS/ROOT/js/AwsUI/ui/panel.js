// requires jquery ui
// requires jquery
// requires css for porlet

/**
 * Portlet Template/generator.
 * 
 * @param {string} title the title of the portlet. 
 * @param {Number} id The id of the portlet, to be used to identify the portlet.
 * @param {Object} HTML content the content of the portlet. Dynamic content. Can be optional
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
 * @param {string} id The id of the portlet to be edited
 * @param {Object} HTML content
 * 
 * @return void
 */
function addContent (id, content) {

	$('#'+id).append(content);

	return;
}

/**
 * This function updates the content of the portlet. It will override the existing content.
 * 
 * @param {String} id The id of the portlet to be edited
 * @param {Object} content
 * 
 */

function updateContent (id, content) {
	
	$('#'+id).html(content);
	
	return;
}

/**
 * This function updates the title of the portlet. It will override the existing title.
 * 
 * @param {String} id
 * @param {Object} content
 * 
 */
function updateTitle (portlet, title) {

	// TODO select the portlet by the id of the content and go up one div in the tree.

}


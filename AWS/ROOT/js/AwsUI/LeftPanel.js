// This is the left panel accordion
// requires jquery
// requires jquery UI
// requires css for accordion

/**
 * This is the leftPanel accordion template
 * 
 * @param {String} id The accordion id. So that we can access it in the DOM using jQuery for example.
 * 
 * @return {Object} HTML content for the accordion
 */
function leftPanel (id) {
	
	// The first version of this should will have a predefined number of sections. But it could easily 
    // be expandable using a for loop and parameters if desired.
	
	// The section in question are Analysis Builder, Calculation, Weave
	var _leftPanel = '<div id="' + id + '"> \
						<h3>Analysis Builder</h3> \
						<div id="analysisBuilderContent"> \
						</div> \
						<h3>Calculation</h3> \
						<div id="calculationContent"> \
						</div> \
						<h3>Weave</h3> \
						<div id="weaveContent"> \
					  </div>';
	return _leftPanel;
}

/**
 * This function will use jQuery to setup the accordion UI and add events.
 * 
 * @param {String} id The id of the panel
 * @return {void}
 * 
 */
function initializeLeftPanel(id) {
	var icons = {
	     header: "ui-icon-circle-arrow-e",
	     activeHeader: "ui-icon-circle-arrow-s"
	           };
	$( "#"+id).accordion({
	     icons: icons
	 });

}


// These functions replicate the functionality of addContent and updateContent in panel.js
// May be we can just use the same functions and move them to a common location

/**
 * This function will append content to one of the section of the accordion
 * 
 * @param {string} sectionId The id of the section to which we desire to add content
 * @param {Object} content HTML content to be added to the section.
 *
 * @return {void}
 */
function addContentToSection(sectionId, content) {

	$("#"+sectionId).append(content);

}

/**
 * This function will replace existing content to one of the section of the accordion
 * 
 * @param {string} sectionId The id of the section to which we desire to change the content
 * @param {Object} content HTML content to be used to replace existing content.
 * 
 * @return {void}
 */
function updateContentToSection(sectionId, content) {
	
	$("#"+sectionId).html(content);
}


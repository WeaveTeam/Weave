/**
 * RequireJS.org
 * 
 * We are using this to load our various scripts and avoid a monolith of code in
 * the AWS.
 */

/*
 * require(["helper/util"], function(util) { //This function is called when
 * scripts/helper/util.js is loaded. //If util.js calls define(), then this
 * function is not fired until //util's dependencies have loaded, and the util
 * argument will hold //the module value for "helper/util". });
 */

require.config({
	paths : {
		 'jquery' : 'js/jquery-1.9.1',
		 'jquery-ui': 'jquery-ui-1.10.3.custom',
	},
	shim: {
		'jquery.jlayout':['jlayout.border','jlayout.grid','jquery.sizes'],
								'jquery.sizes':['jquery'],
		'jquery-ui':['jquery']
	}
});

require(
		[ 
		  "text!../src/GenericPanel.html!strip", 
		  "jquery-ui",
		  "jquery.jlayout" ],
		function( html, $, jLayout) {

			// JLayout script
			jQuery(function($) {
				var i = $('#panel1');
				i.append(html);
				
				var container = $('.layout');

				function borderLayout() {
					container.layout({
						resize : false,
						type : 'border',
						vgap : 8,
						hgap : 8
					});
				}

				function gridLayout() {
					$('.center').layout({
						type : 'grid',
						resize : false,
						columns : 2,
						rows: 4,
						fill : 'horizontal',
						//vgap : 4,
						//hgap : 4
					});
					var pan = $(".varPanel");
						pan.find("span.ui-icon-minusthick").remove();
						pan.addClass(
									"ui-widget ui-widget-content ui-helper-clearfix ui-corner-all")
							.find(".varPanel-header")
							.addClass("ui-widget-header ui-corner-all")
							.prepend(
									"<span class='ui-icon ui-icon-minusthick' style='float:left'></span>")
							.end().find(".varPanel-content");
					$(".varPanel-header .ui-icon").click(
							function() {
								$(this).toggleClass("ui-icon-minusthick")
										.toggleClass("ui-icon-plusthick");
								$(this).parents(".varPanel:first").find(
										".varPanel-content").toggle();
							});
				}

				$('.north').resizable({
					handles : 's',
					stop : borderLayout,
					resize : borderLayout
				});

				$('.south').resizable({
					handles : 'n',
					stop : borderLayout,
					resize : borderLayout
				});

				/*
				 * $('.east').resizable({ handles : 'w', stop : borderLayout,
				 * resize : borderLayout });
				 */

				$('.west').resizable({
					handles : 'e',
					stop : borderLayout,
					resize : borderLayout
				});
				/*$('.varPanel').draggable({
					connectToSortable : "#east",
				});*/
				gridLayout();

				/*
				 * $('#panel5').panel({ // 'draggable' : false, 'stackable' :
				 * false, 'collapseType' : 'slide-right' });
				 */

				$(window).resize(borderLayout);

				borderLayout();
				borderLayout();
				$('.sortable').sortable();
				/*$("#center>.sortable").sortable({
					connectWith : '#east>.sortable'
				});
				$("#east>.sortable").sortable({
					connectWith : '#center>.sortable'
				});*/
				$(".sortable").disableSelection();

				gridLayout();
			});

			// Panel Contents
			jQuery(function($) {
				$(document).ready(
						function() {
							
							var countryCombobox = $('#countryCombobox');
							countryCombobox.append($("<option/>").val('').text(
									"Select one..."));
							countryCombobox.append($("<option/>").val('US')
									.text("United States"));

							var stateCombobox = $('#stateCombobox');
							stateCombobox.append($("<option/>").val('')
									.text(""));
							stateCombobox.append($("<option/>").val('MA').text(
									"Massachussetts"));
							stateCombobox.append($("<option/>").val('RI').text(
									"Rhode Island"));
							stateCombobox.append($("<option/>").val('CO').text(
									"Connecticut"));
							stateCombobox.append($("<option/>").val('TX').text(
									"Texas"));
							stateCombobox.append($("<option/>").val('WA').text(
									"Washington"));
							stateCombobox.append($("<option/>").val('OR').text(
									"Oregon"));
							stateCombobox.append($("<option/>").val('IL').text(
									"Illinois"));

							var countyCombobox = $('#countyCombobox');
							countyCombobox.append($("<option/>").val('').text(
									""));
							countyCombobox.append($("<option/>").val(
									'Worcester').text("Worcester"));
							countyCombobox.append($("<option/>").val(
									'Middlesex').text("Middlesex"));
							countyCombobox.append($("<option/>").val('Suffolk')
									.text("Suffolk"));
							countyCombobox.append($("<option/>")
									.val('Plymouth').text("Plymouth"));

							var cityCombobox = $('#cityCombobox');
							cityCombobox
									.append($("<option/>").val('').text(""));
							cityCombobox.append($("<option/>").val('Lowell')
									.text("Lowell"));

							var startYearCombobox = $('#startYearCombobox');
							startYearCombobox.append($("<option/>").val('2010')
									.text("2010"));

							var EndYearCombobox = $('#EndYearCombobox');
							EndYearCombobox.append($("<option/>").val('2012')
									.text("2012"));
							EndYearCombobox.append($("<option/>").val('2013')
									.text("2013"));

							var timeTypeCombobox = $('#timeTypeCombobox');
							timeTypeCombobox.append($("<option/>").val(
									'byQuarter').text("By Quarter"));
							timeTypeCombobox.append($("<option/>")
									.val('byYear').text("By Year"));

							$('#panel2SubmitButton').button().click(function() {
								console.log('function 2 called');
							});

							$('#panel2MapButton').button().click(function() {
								console.log('function 3 called');
							});

							$('#panel3SubmitButton').button().click(function() {
								console.log('function called');
							});

							$('#panel4SubmitButton').button().click(function() {
								console.log('function called');
							});

							$('#panel5SubmitButton').button().click(function() {
								testServerQuery('getRResult');
							});

							$('#panel6ImportButton').button().click(function() {
								console.log('function called');
							});

							$('#panel6SaveButton').button().click(function() {
								console.log('function called');
							});

							$('#panel6EditButton').button().click(function() {
								console.log('function called');
							});
							$(".box").sortable({
								connectWith : ".box"
							});

						});// end of panel contents
			});
		});

/*require([ "jquery", "text!../src/GenericPanel.html!strip" ], function($, html) {
	var i = $('#panel1');
	i.append(html);

});*/
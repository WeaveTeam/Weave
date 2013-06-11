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
		//'jquery' : 'js/jquery-1.4.2.min',
		'swfobject' : 'swfobject'
	}
});

require([ "js/jquery-1.4.2.min.js", "js/jquery.cookie.js", "js/jquery.sizes.js",
		"js/jlayout.border.js", "swfobject", "js/jquery-ui-1.8.custom.min.js",
		"js/jquery.jlayout.js", "js/ui.panel.js" ], function($) {
	
	// JLayout script
	jQuery(function($) {
		var container = $('.layout');

		function layout() {
			container.layout({
				resize : false,
				type : 'border',
				vgap : 8,
				hgap : 8
			});
		}

		$('.north').resizable({
			handles : 's',
			stop : layout,
			resize : layout
		});

		$('.south').resizable({
			handles : 'n',
			stop : layout,
			resize : layout
		});

		$('.east').resizable({
			handles : 'w',
			stop : layout,
			resize : layout
		});

		$('.west').resizable({
			handles : 'e',
			stop : layout,
			resize : layout
		});
		$('#panel1').panel({
			// 'draggable' : true,
			'collapsible' : true,
			'collapsed' : true
		});
		$('#panel2').panel({
			// 'draggable' : true,
			'collapsible' : true,
			'collapsed' : true
		});
		$('#panel3').panel({
			// 'draggable' : true,
			'collapsible' : true,
			'collapsed' : true
		});
		$('#panel4').panel({
			// 'draggable' : true,
			'collapsible' : true,
			'collapsed' : true
		});
		$('#panel5').panel({
			// 'draggable' : false,
			'stackable' : false,
			'collapseType' : 'slide-right'
		});
		$('#panel6').panel({
			// 'draggable' : true,
			'collapsible' : true,
			'collapsed' : true
		});

		$(window).resize(layout);

		layout();
		layout();
		
		$("#sortable").sortable();
		$("#sortable").disableSelection();
	});
	
	/*$(function($) {
		
	});*/

	// Panel Contents
	jQuery(function($){
		$(document)
		.ready(
			function() {
				var combobox1 = $('#combobox1');
				combobox1.append($("<option/>").val('').text(
						"Select one..."));
				combobox1.append($("<option/>").val('CSVDataSource1')
						.text("CSVDataSource1"));
				combobox1.append($("<option/>").val('CSVDataSource1')
						.text("Obesity"));
				combobox1.append($("<option/>").val('database').text(
						"(Data from server)"));

				var countryCombobox = $('#countryCombobox');
				countryCombobox.append($("<option/>").val('').text(
						"Select one..."));
				countryCombobox.append($("<option/>").val('US').text(
						"United States"));

				var stateCombobox = $('#stateCombobox');
				stateCombobox.append($("<option/>").val('').text(""));
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
				countyCombobox.append($("<option/>").val('').text(""));
				countyCombobox.append($("<option/>").val('Worcester')
						.text("Worcester"));
				countyCombobox.append($("<option/>").val('Middlesex')
						.text("Middlesex"));
				countyCombobox.append($("<option/>").val('Suffolk')
						.text("Suffolk"));
				countyCombobox.append($("<option/>").val('Plymouth')
						.text("Plymouth"));

				var cityCombobox = $('#cityCombobox');
				cityCombobox.append($("<option/>").val('').text(""));
				cityCombobox.append($("<option/>").val('Lowell').text(
						"Lowell"));

				var startYearCombobox = $('#startYearCombobox');
				startYearCombobox.append($("<option/>").val('2010')
						.text("2010"));

				var EndYearCombobox = $('#EndYearCombobox');
				EndYearCombobox.append($("<option/>").val('2012').text(
						"2012"));
				EndYearCombobox.append($("<option/>").val('2013').text(
						"2013"));

				var timeTypeCombobox = $('#timeTypeCombobox');
				timeTypeCombobox.append($("<option/>").val('byQuarter')
						.text("By Quarter"));
				timeTypeCombobox.append($("<option/>").val('byYear')
						.text("By Year"));

				$('#centerPanel').panel({
					width : '83.10%',
				});

				$('#panel1SubmitButton').button().click(function() {
					console.log('function called');
				});

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
				$('#Weave').panel({
					width : '83.10%',
					draggable : true,
				});
			});//end of panel contents
	});
});

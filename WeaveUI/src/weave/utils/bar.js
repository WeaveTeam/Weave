var data = [{y: 0.5, color: "red"}, {y: 1.2, color: "blue"}, {y: 1.3, color: "steelblue"}];

var xticks = [0,1,2,3,4,5,6,7,8,9,10];
var xMin = 0;
var xMax = 10;

var yticks = [0.5, 1.2, 1.3];
var yMax = 2;
var yMin = 0;

var marginTop = 20;
var marginBottom = 40;
var marginLeft = 40;
var marginRight = 40;

var width = 500;
var height = 400;

var axisThickness = 10;

var title="Bar Chart";
var xTitle="x";
var yTitle="y";

var svg = null;

function setData(array, max, min) {
	data = array;
	yMax = max;
	yMin = min;
}

function setWidthAndHeight(w, h) {
	width = w;
	height = h; 
}

function setMargins(top, left, bottom, right) {
	marginTop = top; 
	marginLeft = left;
	marginBottom = bottom;
	marginRight = right;
}

function setTitles(str, ystr, xstr) {
	title = str;
	yTitle = ystr;
	xTitle = xstr;
}

function setXgrid(array, max, min) {
	xticks = array;
	xMax = max; 
	xMin = min;
}

function setYgrid(array, max, min) {
	yticks = array;
	yMax = max; 
	yMin = min;
}

function draw() {
	var y = d3.scale.linear().domain([yMax, yMin]).range([0, height]),
	x = d3.scale.ordinal().domain(d3.range(data.length)).rangeBands([0, width], 1/(data.length));

	var xgrid = d3.scale.linear().domain([xMin, xMax]).range([0, width]);
	var ygrid = d3.scale.linear().domain([yMax, yMin]).range([0, height]);
	
	alert("hello");
	svg = d3.select("body")
	.append("svg:svg");
	
//	svg = $("#chart-canvas").html();
	
	var vis = svg.attr("shape-rendering","crispEdges")
	.attr("font-size", "10px")
	.attr("font-family", "Helvetica")
	.attr("width", width + marginLeft + marginRight)
	.attr("height", height + marginTop + marginBottom)
	.append("svg:g")
	.attr( "transform", "translate(" + marginLeft + "," + marginTop+")");
	
	// y axis
	vis.insert("svg:rect")
	.attr("x", -axisThickness)
	.attr("y", 0)
	.attr("width", axisThickness)
	.attr("height", height+axisThickness)
	.attr("fill", "darkgrey");
	
	// x axis
	vis.insert("svg:rect")
	.attr("x", 0)
	.attr("y", height)
	.attr("width", width)
	.attr("height", axisThickness)
	.attr("fill", "darkgrey");
	
	//	y axis grid lines
	var rules = vis.selectAll("g.rule")
	.data(yticks)
	.enter().append("svg:g")
	.attr("class", "rule")
	.attr("transform", function(d) { return "translate(0," + ygrid(d) + ")"; });
	
	rules.append("svg:line")
	.attr("x1", -axisThickness)
	.attr("x2", width)
	.attr("stroke", "lightgrey");
	
	//	y axis tick labels 
	rules.append("svg:text")
	.attr("text-anchor", "end")
	.attr("x", -axisThickness)
	.attr("dy", ".35em")
	.text( function(d) { return d; } );
	
	// x axis grid lines
	vis.selectAll("line.xgrid")
	.data(xticks)
	.enter().append("svg:line")
	.attr("x1", function(d) { return xgrid(d.num); })
	.attr("x2", function(d) { return xgrid(d.num); })
	.attr("y1", 0)
	.attr("y2", height+axisThickness)
	.attr("stroke", "lightgrey");
	
	//	x axis tick label
	vis.selectAll("text.xAxis")
	.data(xticks)
	.enter().append("svg:text")
	.attr("x", function(d) { return xgrid(d.num); })
	.attr("y", height)
	.attr("text-anchor", "end")
	.text(function(d) { return ((d.str) ? d.str : d.num); })
	.attr("transform", function(d) { return "translate(0, 18)rotate(-45,"+xgrid(d.num)+","+height+")";})
	.attr("class", "yAxis");

	// y axis title
	vis.append("svg:text")
	.attr("x", 0-marginLeft)
	.attr("y", height/2)
	.attr("text-anchor", "middle")
	.attr("dy", ".90em")
	.text(yTitle)
	.attr("transform", "rotate(-90,"+(0-marginLeft)+","+(height/2)+")");
	
	// x axis title
	vis.append("svg:text")
	.attr("x", width/2)
	.attr("y", height+marginBottom)
	.attr("text-anchor", "middle")
	.attr("dy", "-.90em")
	.text(xTitle);
	
	// bar chart title
	vis.append("svg:text")
	.attr("x", width/2)
	.attr("y", 0-marginTop/2)
	.attr("text-anchor", "middle")
	.attr("dy", ".35em")
	.text(title);	
	
	//	draw bars last
	var bars = vis.selectAll("g.bar")
	.data(data)
	.enter().append("svg:g")
	.attr("class", "bar")    
	
	bars.append("svg:rect")
	.attr("fill", function(d) { return d.color; }) 
	.attr("x", function(d, i) { return x(i); })
	.attr("y", function(d) { return y(d.y); })
	.attr("stroke", "black")
	.attr("stroke-width", .5)
	.attr("stroke-opacity", .5)
	.attr("width", x.rangeBand())
	.attr("height", function(d, i) { return y(yMax-d.y); });
	
//	var b64 = Base64.encode(svg);

	//open("data:image/svg+xml," + encodeURIComponent(svg));
	
	// Works in recent Webkit(Chrome)
	//$("body").append($("<img src='data:image/svg+xml;base64,\n"+b64+"' alt='file.svg'/>"));

	// Works in Firefox 3.6 and Webit and possibly any browser which supports the data-uri
	//$("body").append($("<a href-lang='image/svg+xml' href='data:image/svg+xml;base64,\n"+b64+"' title='file.svg'>Download</a>"));
	alert(d3.select("body"));	
}

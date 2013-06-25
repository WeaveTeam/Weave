function unusedFunction(node) {
  alert(node['title']);
}

function displayNodeTitle(node) {
  alert(node['title']);
}

var flowerNode = {};
flowerNode['title'] = "Flowers";
displayNodeTitle(flowerNode);
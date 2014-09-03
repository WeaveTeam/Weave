# This is a simple addtion script in python

def addition(input_data):
	new_row = []
	
	for i in range(13):
		new_row.append(input_data[0][i] + input_data[1][i])
		
	input_data.append(new_row)
	
	return input_data
	
result = addition(input_data)
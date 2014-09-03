#This script will categorize a probeset based on its expression levels
'''
def clusterExpression(dataset):
	record_classifier = []

	for i in range(len(dataset)):
		if ((dataset[1][i] >= dataset[2][i]) &
        	(dataset[2][i] >= dataset[3][i])):
        		record_classifier.append(dataset[i][0])
        		record_classifier.append('1')

        if ((dataset[1][i] >= dataset[2][i]) &
            (dataset[2][i] <= dataset[3][i])):
        		record_classifier.append(dataset[i][0])
        		record_classifier.append('2')

        if ((dataset[1][i] <= dataset[2][i]) &
            (dataset[2][i] >= dataset[3][i])):
        		record_classifier.append(dataset[i][0])
        		record_classifier.append('3')


        if ((dataset[1][i] <= dataset[2][i]) &
            (dataset[2][i] <= dataset[3][i])):
        		record_classifier.append(dataset[i][0])
        		record_classifier.append('4')
        		
	dataset.append(record_classifier)
	return dataset
	
result = clusterExpression(dataset)
'''
# This is a simple addtion script in python

def addition(dataset):
	new_row = []
	
	for i in range(13):
		new_row.append(dataset[0][i] + dataset[1][i])
		
	dataset.append(new_row)
	
	return dataset
	
result = addition(dataset)

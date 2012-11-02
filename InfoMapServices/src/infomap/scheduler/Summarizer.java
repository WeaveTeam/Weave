package infomap.scheduler;
import java.util.Dictionary;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.Set;

import opennlp.tools.sentdetect.SentenceDetectorME;
import opennlp.tools.sentdetect.SentenceModel;
import opennlp.tools.tokenize.Tokenizer;
import opennlp.tools.tokenize.TokenizerME;
import opennlp.tools.tokenize.TokenizerModel;
public class Summarizer {

	/**
	 * @param args
	 */

	// Calculate the normalized TF value of a document
	public static Dictionary<String, Double> NormalizedTFCalculator(
			String input, TokenizerModel tokeModel,
			Dictionary<String, Integer> stopWords) {
		Dictionary<String, Integer> TF = new Hashtable<String, Integer>();
		Dictionary<String, Double> normalizedTF = new Hashtable<String, Double>();

		// Calculate the raw frequency
		Tokenizer tokenizer = new TokenizerME(tokeModel);
		String tokens[] = tokenizer.tokenize(input.toLowerCase());
		int numOfTokens = tokens.length;
		int frequency;
		for (int i = 0; i < numOfTokens; i++) {
			if (TF.get(tokens[i]) != null) {
				frequency = TF.get(tokens[i]);
				TF.remove(tokens[i]);
				TF.put(tokens[i], frequency + 1);
			} else {
				TF.put(tokens[i], 1);
			}
		}

		// Find the maximum raw frequency
		int maximumFrequency = 0;
		String mostCommonWord = null;
		for (Enumeration keys = TF.keys(); keys.hasMoreElements();) {
			String nextElement = (String) keys.nextElement();
			frequency = TF.get(nextElement);
			if (frequency > maximumFrequency
					&& stopWords.get(nextElement) == null) {
				maximumFrequency = frequency;
				mostCommonWord = nextElement;
			}
		}
		// System.out.println("Maximum frequency is: " + maximumFrequency);
		// System.out.println("Most Common Word is: " + mostCommonWord);

		// Calculate the normalized TF
		for (Enumeration keys = TF.keys(), values = TF.elements(); keys
				.hasMoreElements() && values.hasMoreElements();) {
			String keyOfNormalizedTF = (String) keys.nextElement();
			double valueOfNormalizedTF = ((Integer) values.nextElement())
					/ (1.0) / maximumFrequency;
			normalizedTF.put(keyOfNormalizedTF, valueOfNormalizedTF);
			// System.out.println("Key: " + keyOfNormalizedTF + " Value: " +
			// valueOfNormalizedTF);
		}

		return normalizedTF;
	}

	// Calculate the weight of a sentence using average normalizedTF values
	public static double WeightOfSentence(String input,
			TokenizerModel tokeModel,
			Dictionary<String, Double> NormalizedTFValues,
			Dictionary<String, Integer> stopWords) {
		double weight = 0.0;
		int numOfNoneStopWords = 0;

		Tokenizer tokenizer = new TokenizerME(tokeModel);
		String tokensOfSentence[] = tokenizer.tokenize(input.toLowerCase());

		for (int i = 0; i < tokensOfSentence.length; i++) {
			if (stopWords.get(tokensOfSentence[i]) == null) {
				weight += NormalizedTFValues.get(tokensOfSentence[i]);
				numOfNoneStopWords++;
			}
		}
		weight /= numOfNoneStopWords;
		return weight;
	}

	// Calculate the weight of each term in each documents
	public static Dictionary<String, Double>[] WeightOfTerms(
			String[] documents, TokenizerModel tokeModel,
			Dictionary<String, Integer> stopWords) {
		Dictionary<String, Double> normalizedIDF = NormalizedIDFCalculator(
				documents, tokeModel, stopWords);
		int numOfDocuments = documents.length;
		Dictionary<String, Double>[] normTFs = (Dictionary<String, Double>[]) new Dictionary[numOfDocuments];
		Dictionary<String, Double>[] weightOfTerms = (Dictionary<String, Double>[]) new Dictionary[numOfDocuments];
		for (int i = 0; i < numOfDocuments; i++) {
			normTFs[i] = NormalizedTFCalculator(documents[i], tokeModel,
					stopWords);
			weightOfTerms[i] = new Hashtable<String, Double>();
		}
		String element = null;
		double tfValue = 0.0;
		double idfValue = 0.0;
		double weight = 0.0;
		for (int i = 0; i < numOfDocuments; i++) {
			for (Enumeration keys = normTFs[i].keys(), values = normTFs[i]
					.elements(); keys.hasMoreElements()
					&& values.hasMoreElements();) {
				element = (String) keys.nextElement();
				tfValue = (Double) values.nextElement();
				idfValue = normalizedIDF.get(element);
				weight = tfValue * idfValue;
				// System.out.println("Weight: " + weight);
				// System.out.println("Element: " + element);
				weightOfTerms[i].put(element, weight);
			}
		}

		return weightOfTerms;
	}

	// Return an array of all the sentences in one document
	public static String[] Sentences(String input, SentenceModel senModel) {
		SentenceDetectorME sentenceDetector = new SentenceDetectorME(senModel);
		String sentences[] = sentenceDetector.sentDetect(input);
		return sentences;
	}

	// Calculate the log IDF value of a bunch of documents
	public static Dictionary<String, Double> NormalizedIDFCalculator(
			String[] documents, TokenizerModel tokeModel,
			Dictionary<String, Integer> stopWords) {
		int numOfDocuments = documents.length;
		Dictionary<String, Double>[] normTFs = (Dictionary<String, Double>[]) new Dictionary[numOfDocuments];
		Dictionary<String, Integer> IDF = new Hashtable<String, Integer>();
		Dictionary<String, Double> logIDF = new Hashtable<String, Double>();
		for (int i = 0; i < numOfDocuments; i++) {
			normTFs[i] = NormalizedTFCalculator(documents[i], tokeModel,
					stopWords);

		}
		int numOfDocumentsHasThisTerm = 0;
		for (int i = 0; i < normTFs.length; i++) {
			for (Enumeration keys = normTFs[i].keys(); keys.hasMoreElements();) {
				String element = (String) keys.nextElement();
				if (IDF.get(element) != null) {
					numOfDocumentsHasThisTerm = IDF.get(element);
					IDF.remove(element);
					IDF.put(element, numOfDocumentsHasThisTerm + 1);
				} else {
					IDF.put(element, 1);
				}
			}
		}
		for (Enumeration keys = IDF.keys(), values = IDF.elements(); keys
				.hasMoreElements() && values.hasMoreElements();) {
			String element = (String) keys.nextElement();
			int frequenceValue = (Integer) values.nextElement();
			double logValue = numOfDocuments / (1.0) / frequenceValue;// this is
																		// the
																		// definition
																		// of
																		// idf
			// double logValue = Math.log(numOfDocuments/(1.0)/frequenceValue);
			// //this is the logValue
			// double logValue = Math.log((numOfDocuments +
			// 1)/(1.0)/frequenceValue); //this is the logValue in which deal
			// with log(1), where one term appears in every documents
			logIDF.put(element, logValue);
		}
		return logIDF;
	}

	// Calculate the weighted cosine similarity of two sentences or documents
	public static double CosineSimilarityCalculator(String input1,
			String input2, Dictionary<String, Double> normTF1,
			Dictionary<String, Double> normTF2,
			Dictionary<String, Double> normIDF, TokenizerModel tokeModel,
			Dictionary<String, Integer> stopWords) {
		double numerator = 0.0; // fenzi
		double demominator = 0.0; // fenmu
		double similarity = 0.0;
		double tfi = 0.0;// tf value of term i
		double idfi = 0.0;// idf value of temr i
		double tfi1 = 0.0;// tf value of term i in input1
		double tfi2 = 0.0;// tf value of term i in input2

		Dictionary<String, Integer> commonTerms = new Hashtable<String, Integer>();
		Tokenizer tokenizer = new TokenizerME(tokeModel);
		String tokensOfInput1[] = tokenizer.tokenize(input1.toLowerCase());
		String tokensOfInput2[] = tokenizer.tokenize(input2.toLowerCase());
		for (int i = 0; i < tokensOfInput1.length; i++) {
			for (int j = 0; j < tokensOfInput2.length; j++) {
				if (tokensOfInput1[i].equalsIgnoreCase(tokensOfInput2[j])) {
					commonTerms.put(tokensOfInput1[i], 1);
				}
			}
		}
		for (Enumeration keys = commonTerms.keys(); keys.hasMoreElements();) {
			String key = (String) keys.nextElement();
			if (stopWords.get(key) == null) {
				tfi1 = normTF1.get(key);
				tfi2 = normTF2.get(key);
				idfi = normIDF.get(key);
				// System.out.println("tfi1: " + tfi1);
				// System.out.println("tfi2: " + tfi2);
				// System.out.println("idfi: " + idfi);
				numerator += tfi1 * tfi2 * Math.pow(idfi, 2);
			}
		}

		double sumOfTFIDFValueOfInput1 = 0.0;
		double sumOfTFIDFValueOfInput2 = 0.0;
		double sqrtOfSumOfTFIDFValueOfInput1 = 0.0;
		double sqrtOfSumOfTFIDFValueOfInput2 = 0.0;
		for (int i = 0; i < tokensOfInput1.length; i++) {
			tfi = normTF1.get(tokensOfInput1[i]);
			idfi = normIDF.get(tokensOfInput1[i]);
			if (stopWords.get(tokensOfInput1[i]) == null) {
				sumOfTFIDFValueOfInput1 += Math.pow(tfi * idfi, 2);
			}
		}
		for (int i = 0; i < tokensOfInput2.length; i++) {
			tfi = normTF2.get(tokensOfInput2[i]);
			idfi = normIDF.get(tokensOfInput2[i]);
			// System.out.println("idfi: " + idfi);
			if (stopWords.get(tokensOfInput2[i]) == null) {
				sumOfTFIDFValueOfInput2 += Math.pow(tfi * idfi, 2);
			}
		}
		sqrtOfSumOfTFIDFValueOfInput1 = Math.sqrt(sumOfTFIDFValueOfInput1);
		sqrtOfSumOfTFIDFValueOfInput2 = Math.sqrt(sumOfTFIDFValueOfInput2);
		demominator = sqrtOfSumOfTFIDFValueOfInput1
				* sqrtOfSumOfTFIDFValueOfInput2;
		// System.out.println("sqrtOfSumOfTFIDFValueOfInput1: " +
		// sqrtOfSumOfTFIDFValueOfInput1);
		// System.out.println("sqrtOfSumOfTFIDFValueOfInput2: " +
		// sqrtOfSumOfTFIDFValueOfInput2);

		similarity = numerator / demominator;
		// System.out.println("numerator: " + numerator);
		// System.out.println("demominator: " + demominator);

		return similarity;
	}

	// Get the summary of specific length(numberOfSentenceInSummary) of input
	public static String SingleDocumentSummaryCalculator(String input,
			int numberOfSentenceInSummary, SentenceModel senModel,
			TokenizerModel tokeModel, Dictionary<String, Integer> stopWords) {
		String[] sentences = Sentences(input, senModel);
		int numOfSentences = sentences.length;
		if (numOfSentences < numberOfSentenceInSummary) {
			numberOfSentenceInSummary = numOfSentences;
		}
		Dictionary<String, Double> normTF = NormalizedTFCalculator(input,
				tokeModel, stopWords);
		int[] rank = new int[numOfSentences];
		double[] weight = new double[numOfSentences];
		String summary = "";
		for (int i = 0; i < numOfSentences; i++) {
			rank[i] = 0;
			weight[i] = 0.0;
		}
		for (int i = 0; i < numOfSentences; i++) {
			weight[i] = WeightOfSentence(sentences[i], tokeModel, normTF,
					stopWords);
		}
		// rank the sentences by their weight
		double tempWeight = 0.0;
		int tempIndex = 0;
		for (int i = 0; i < numOfSentences; i++) {
			for (int j = 0; j < numOfSentences; j++) {
				if (weight[j] > tempWeight) {
					tempWeight = weight[j];
					tempIndex = j;
				}
			}
			weight[tempIndex] = -1.0;
			rank[i] = tempIndex;
			tempWeight = 0.0;
			tempIndex = 0;
		}

		int[] orderOfSentences = new int[numberOfSentenceInSummary];
		for (int i = 0; i < numberOfSentenceInSummary; i++) {
			orderOfSentences[i] = rank[i];
		}
		int tempIndexOfMinimumValue = 0;
		for (int i = 0; i < numberOfSentenceInSummary; i++) {
			for (int j = i; j < numberOfSentenceInSummary; j++) {
				if (orderOfSentences[i] > orderOfSentences[j]) {
					tempIndexOfMinimumValue = orderOfSentences[i];
					orderOfSentences[i] = orderOfSentences[j];
					orderOfSentences[j] = tempIndexOfMinimumValue;
				}
			}
			// System.out.println("Order: " + orderOfSentences[i]);
		}

		for (int i = 0; i < numberOfSentenceInSummary; i++) {
			summary += (" " + sentences[orderOfSentences[i]]);
		}
		return summary;
	}

	// TODO testing!!!
	public static String[][] GroupCalculator(String[] documents,
			int maxNumberOfGroups, Dictionary<String, Double> normIDF,
			SentenceModel senModel, TokenizerModel tokeModel,
			Dictionary<String, Integer> stopWords) {
		int numOfDocuments = documents.length;
		double similarityMatrix[][] = new double[numOfDocuments][numOfDocuments];
		double tempSimilarity = 0.0;
		Dictionary<String, Double>[] normTFs = (Dictionary<String, Double>[]) new Dictionary[numOfDocuments];
		for (int i = 0; i < numOfDocuments; i++) {
			normTFs[i] = NormalizedTFCalculator(documents[i], tokeModel,
					stopWords);
		}
		for (int i = 0; i < numOfDocuments; i++) {
			for (int j = i; j < numOfDocuments; j++) {
				if (j == i) {
					similarityMatrix[i][j] = -1.0; // use -1.0 to identify the
													// similarity between two
													// identical documents
				} else {
					tempSimilarity = CosineSimilarityCalculator(documents[i],
							documents[j], normTFs[i], normTFs[j], normIDF,
							tokeModel, stopWords);
					similarityMatrix[i][j] = tempSimilarity;
					similarityMatrix[j][i] = tempSimilarity;
				}
			}
		}
		int numOfGroups = maxNumberOfGroups; // need to change it to dynamic
		Set[] clusterResults = HierarchicalClustering(numOfGroups,
				similarityMatrix);
		int returnedNumOfGroups = clusterResults.length;
		int[] groupSizes = new int[returnedNumOfGroups];
		for (int i = 0; i < returnedNumOfGroups; i++) {
			groupSizes[i] = clusterResults[i].size();
		}
		String[] groups = new String[returnedNumOfGroups];
		String[][] summarys = new String[returnedNumOfGroups][2];
		for (int i = 0; i < returnedNumOfGroups; i++) {
			groups[i] = "";
		}
		for (int i = 0; i < returnedNumOfGroups; i++) {
			Iterator it = clusterResults[i].iterator();
			while (it.hasNext()) {
				groups[i] += (documents[(Integer) it.next()] + " ");
			}
		}
		for (int i = 0; i < returnedNumOfGroups; i++) {
			summarys[i][0] = Integer.toString(groupSizes[i]);
			summarys[i][1] = SingleDocumentSummaryCalculator(groups[i], 2,
					senModel, tokeModel, stopWords);
		}
		return summarys;
	}

	// TODO testing
	public static Set[] HierarchicalClustering(int numOfClusters,
			double[][] similarityMatrix) {
		int numbOfClusters = numOfClusters;
		double[][] distMatrix = similarityMatrix;
		int numOfDocuments = distMatrix[0].length;
		Set[] set = null;
		if (numOfDocuments <= numbOfClusters) {
			numbOfClusters = numOfDocuments;
			set = new HashSet[numbOfClusters];
			for (int i = 0; i < numbOfClusters; i++) {
				set[i] = new HashSet();
			}
			for (int i = 0; i < numbOfClusters; i++) {
				set[i].add(i);
			}
			return set;
		}
		set = new HashSet[numbOfClusters];
		for (int i = 0; i < numbOfClusters; i++) {
			set[i] = new HashSet();
		}
		int numOfPairs = numOfDocuments * (numOfDocuments - 1) / 2;
		int[][] rankedPair = new int[numOfPairs][2];
		double tempDistance = -1.0;
		int tempj = 0;
		int tempk = 0;
		int tempvalue = 0;
		for (int i = 0; i < numOfPairs; i++) {
			for (int j = 0; j < numOfDocuments - 1; j++) {
				for (int k = j + 1; k < numOfDocuments; k++) {
					if (tempDistance < distMatrix[j][k]) {
						tempDistance = distMatrix[j][k];
						tempj = j;
						tempk = k;
					}
				}
			}
			rankedPair[i][0] = tempj;
			rankedPair[i][1] = tempk;
			distMatrix[tempj][tempk] = -2.0; // use -2.0 to identify those added
												// to the ranked list
			tempDistance = -1.0;
			tempj = 0;
			tempk = 0;
			System.out.println("j... " + rankedPair[i][0] + " k... "
					+ rankedPair[i][1]);
		}

		int[] groups = new int[numOfDocuments];
		for (int i = 0; i < numOfDocuments; i++) {
			groups[i] = i;
		}

		int count = numOfDocuments - numbOfClusters;
		for (int i = 0; i < numOfPairs; i++) {
			if (count > 0) {
				tempj = rankedPair[i][0];
				tempk = rankedPair[i][1];
				tempvalue = groups[tempk];
				if (groups[tempj] != groups[tempk]) {
					for (int j = 0; j < numOfDocuments; j++) {
						if (groups[j] == tempvalue) {
							groups[j] = groups[tempj];
						}
					}
					count--;
				}
			}
		}
		
		// //////testing
		for (int i = 0; i < numOfDocuments; i++) {
			System.out.println("Groups..." + groups[i]);
		}
		// /////end testing
		
		int[] tempSetIdentifier = new int[numbOfClusters];
		for (int i = 0; i < numbOfClusters; i++) {
			tempSetIdentifier[i] = 0;
		}

		int tempGroups[] = new int[numOfDocuments];
		for(int i = 0; i < numOfDocuments; i++){
			tempGroups[i] = groups[i];
		}
		int counter = 0;
		for (int i = 0; i < numOfDocuments; i++) {
			if (tempGroups[i] != -1) {
				tempSetIdentifier[counter] = tempGroups[i];
				System.out.println("counter..." + counter + " group number ..."
						+ i);
				tempGroups[i] = -1;
				for (int j = 0; j < numOfDocuments; j++) {
					if (tempGroups[j] == tempSetIdentifier[counter]) {
						tempGroups[j] = -1;
					}
				}
				counter++;
			}
		}
		
		// //////testing
		for (int i = 0; i < numbOfClusters; i++) {
			System.out.println("tempSetIdentifier..." + tempSetIdentifier[i]);
		}
		// /////end testing
		
		for (int i = 0; i < numOfDocuments; i++) {
			for (int j = 0; j < numbOfClusters; j++) {
				System.out.println("Groups " + groups[i] + " tempSetIdentifier " + tempSetIdentifier[j] + " eaual " + (groups[i] == tempSetIdentifier[j]));
				if (groups[i] == tempSetIdentifier[j]) {
					set[j].add(i);
					System.out.println("adding...");
				}
			}
		}
		
		// //////testing
		for (int i = 0; i < numbOfClusters; i++) {
			Iterator iter = set[i].iterator();
			while(iter.hasNext()){
				System.out.println("Set " + i + " is " + iter.next());
			}
		}
		// /////end testing
		return set;
	}

	// TODO multi-documents summary
	//
}

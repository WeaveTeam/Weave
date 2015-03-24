package weave.servlets.documentmap;

import java.nio.file.Path;
import java.util.Map;

public abstract class DocumentProcessor
{
	/**
	 * Build any directories or database schemata necessary for storing this 
	 * information for a given collection.
	 * @param collection Absolute path to the collection. The last element is used as the collection name.
	 */
	public void init(Path collection);

	/**
	 * Perform the processing task on a document.
	 * @param collection Absolute path to the collection. The last element is used as the collection name.
	 * @param document   Relative path to the document.
	 */
	public void process(Path collection, Path document);

	/**
	 * Test whether the output has been generated for a given document.
	 * @param  collection Absolute path to the collection. The last element is used as the collection name.
	 * @param  document   Relative path to the document.
	 * @return            Whether or not the processing task for this document is up to date.
	 */
	public boolean needsProcessing(Path collection, Path document);
	
	/**
	 * Retrieve the data produced by this processor.
	 * @param  collection Absolute path to the collection. The last element is used as the collection name.
	 * @param  document   Relative path to the document.
	 * @return            The output data for the document, or null if it does not exist yet.
	 */
	public Object getData(Path collection, Path document);

	public Path[] getDocuments(Path collection);

	/**
	 * Retrieve all the data produced by this processor.
	 * @param  collection Absolute path to the collection. The last element is used as the collection name.
	 * @return            A map of the document relative paths to the corresponding output data.
	 */
	public Map<Path,Object> getData(Path collection)
	{
		Map<Path,Object> results;
		for (Path entry : getDocuments()) 
		{

		}
	}

	/** 
	 * Used by other DocumentProcessors to locate the output of this DocumentProcessor, if applicable. 
	 * May return null if, eg, the information is stored in a database.
	 * This should only be used if accessing the file directly is more efficient than retrieving with getData.
	 * @param  collection Absolute path to the collection. The last element is used as the collection name.
	 * @param  document   Relative path to the document.
	 * @return            The expected relative output path of the data that a dependent process will need to perform its task.
	 */

	public Path getOutputName(Path collection, Path document) throws UnsupportedOperationException;

	/**
	 * Set the processor for a given dependency.
	 * @param processors A Map from the dependency names requested to the processors responsible for them.
	 */
	
	public void setDependency(Map<String,DocumentProcessor> processor);

	/**
	 * Set the parameters for this task. 
	 * This should return 
	 * @param params A map of parameter names.
	 */
	public void setParams(Map<String,Object> params) throws IllegalArgumentException;
}
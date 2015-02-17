package weave.servlets.documentmap;
import weave.utils.Strings;

import weave.servlets.PathUtils;

import java.nio.charset.Charset;
import java.lang.Math;
import java.util.*;
import java.util.zip.*;
import java.util.regex.Pattern;
import java.io.*;
import java.nio.file.*;
import java.nio.channels.FileChannel;
import java.nio.file.attribute.*;
import java.net.URI;
import org.apache.commons.io.input.ReaderInputStream;
import java.awt.geom.Point2D;

/* Dependencies for PDF Rendering */
import java.nio.ByteBuffer;
import com.sun.pdfview.*;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.awt.Rectangle;
import javax.imageio.ImageIO;

/* MALLET */
import cc.mallet.util.*;
import cc.mallet.types.*;
import cc.mallet.pipe.*;
import cc.mallet.pipe.iterator.*;
import cc.mallet.topics.*;

/* PDF text extraction */
import org.apache.tika.Tika;

/* Dependencies for PDF title extraction */
import org.docear.pdf.*;

public class DocumentCollection
{
	private static final String UPLOAD_PATH = "uploads";
	private static final String MALLET_PATH = "mallet";
	private static final String MALLET_TOPIC_MODEL = "topics.model";
	private static final String MALLET_DB = "content.mallet";
	private static final String DOCUMENT_PATH = "documents";
	private static final String THUMBNAIL_PATH = "thumbnails";
	private static final String TXT_PATH = "txt";
	private static final String META_PATH = "meta";

	private Path path;
	public DocumentCollection(Path path)
	{
		this.path = path;
	}

	public boolean exists()
	{
		return Files.exists(path);
	}

	public int addZip(String fileName, InputStream stream) throws IOException, ZipException, IllegalStateException
	{
		int file_count = 0;
		Path zipPath = path.resolve(UPLOAD_PATH).resolve(fileName);
		Files.copy(stream, zipPath);
		ZipFile zip = new ZipFile(zipPath.toFile());
		try
		{
			for (Enumeration<? extends ZipEntry> e = zip.entries(); e.hasMoreElements();)
			{
				ZipEntry entry = e.nextElement();
				Path entryPath = Paths.get(entry.getName());
				if (entry.isDirectory())
				{
					Files.createDirectories(path.resolve(DOCUMENT_PATH).resolve(entryPath));
				}
				else
				{
					addDocument(entryPath, zip.getInputStream(entry));
				}
			}
		}
		finally
		{
			zip.close();
		}
		return file_count;
	}

	public void addDocument(String fileName, InputStream stream) throws IOException
	{
		addDocument(Paths.get(fileName), stream);
	}
	public void addDocument(Path file, InputStream stream) throws IOException
	{
		Path filePath = path.resolve(DOCUMENT_PATH).resolve(file);
		Files.copy(stream, filePath);
	}

	public void create() throws IOException
	{
		if (!PathUtils.filenameIsLegal(path.getFileName().toString())) throw new IOException("Filename contains unsafe or invalid characters.");
		if (Files.exists(path)) throw new IOException("Collection by that name already exists.");

		Files.createDirectories(path.resolve(UPLOAD_PATH));
		Files.createDirectories(path.resolve(MALLET_PATH));
		Files.createDirectories(path.resolve(DOCUMENT_PATH));
		Files.createDirectories(path.resolve(TXT_PATH));
		Files.createDirectories(path.resolve(META_PATH));
	}

	public void remove() throws IOException
	{
			if (!PathUtils.filenameIsLegal(path.getFileName().toString())) throw new IOException("Filename contains unsafe or invalid characters.");
			if (!Files.exists(path)) throw new FileNotFoundException();
			Files.walkFileTree(path, new SimpleFileVisitor<Path>() {
				@Override
				public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
				{
					Files.delete(file);
					return FileVisitResult.CONTINUE;
				}
				@Override
				public FileVisitResult postVisitDirectory(Path dir, IOException e) throws IOException
				{
					if (e == null) {
					    Files.delete(dir);
					    return FileVisitResult.CONTINUE;
					} else {
					    // directory iteration failed
					    throw e;
					}
				}
			});
	}

/* TIKA text extraction */
	public static Tika tika = null;

	public void extractText(Path document, boolean overwrite) throws IOException
	{		
		Path inputPath = path.resolve(DOCUMENT_PATH).resolve(document);
		Path outputPath = PathUtils.replaceExtension(path.resolve(TXT_PATH).resolve(document), "txt");
		if (overwrite || !Files.exists(outputPath))
		{
			if (tika == null) tika = new Tika();
			Reader reader = tika.parse(inputPath.toFile());
			Files.createDirectories(outputPath.getParent());
			Files.deleteIfExists(outputPath);
			Files.copy(new ReaderInputStream(reader, Charset.defaultCharset()), outputPath);
		}
	}

	public void extractText(final boolean overwrite) throws IOException
	{

		Files.walkFileTree(path.resolve(DOCUMENT_PATH), new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				extractText(path.resolve(DOCUMENT_PATH).relativize(file), overwrite);
				return FileVisitResult.CONTINUE;
			}
		});
	}

/* PDF-Renderer thumbnailing */
	public static PDFRenderer renderer = null;

	public void renderThumbnail(Path document, boolean overwrite) throws IOException, FileNotFoundException
	{
		Path inputPath = path.resolve(DOCUMENT_PATH).resolve(document);
		Path outputPath = PathUtils.replaceExtension(path.resolve(THUMBNAIL_PATH).resolve(document), "jpg");
		if (overwrite || !Files.exists(outputPath))
		{
			/* http://www.coderanch.com/how-to/content/pdfrenderer-examples.html */
			RandomAccessFile raf = new RandomAccessFile(inputPath.toFile(), "r");
			FileChannel channel = raf.getChannel();
			ByteBuffer buf = channel.map(FileChannel.MapMode.READ_ONLY, 0, channel.size());
			PDFFile file = new PDFFile(buf);
			PDFPage page = file.getPage(0);
			Rectangle rect = new Rectangle(0,0,(int)page.getBBox().getWidth(), (int)page.getBBox().getHeight());
			Image full_image = page.getImage(
                rect.width, rect.height, //width & height
                rect, // clip rect
                null, // null for the ImageObserver
                true, // fill background with white
                true  // block until drawing is done
                );

			int scaled_width = 200;
			int scaled_height = (int)(((float)rect.height / (float)rect.width) * (float)scaled_width);
			
			Image small_image = full_image.getScaledInstance(scaled_width, scaled_height, Image.SCALE_DEFAULT);
			ImageIO.write((BufferedImage)small_image, "jpg" , outputPath.toFile());
		}
	}
	public void renderThumbnails(final boolean overwrite) throws IOException
	{
		Files.walkFileTree(path.resolve(DOCUMENT_PATH), new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				try {
					renderThumbnail(path.resolve(DOCUMENT_PATH).relativize(file), overwrite);
				}
				catch (IOException e)
				{
					System.err.println("Failed to render PDF: " + e.toString());
				}
				return FileVisitResult.CONTINUE;
			}
		});
	}

/* docears heuristic metadata extraction. */
/* TODO: This belongs in a database. */
	public Map<String,String> getTitles() throws IOException
	{
	
		final Map<String,String> titles = new HashMap<String,String>();
		Files.walkFileTree(path.resolve(DOCUMENT_PATH), new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				try {
					Path relativePath = path.resolve(DOCUMENT_PATH).relativize(file);
					Path metaPath = PathUtils.replaceExtension(
						path.resolve(META_PATH).resolve(relativePath),
						"txt");
					List<String> lines = Files.readAllLines(metaPath, Charset.defaultCharset());
					String title = Strings.join("\n", lines);
					titles.put(relativePath.toString(), title);
				}
				catch (Exception e)
				{
					System.err.println("Failed to extract title from PDF: " + e.toString());
				}
				return FileVisitResult.CONTINUE;
			}
		});
		return titles;
	}

	public void extractMeta(Path document, boolean overwrite) throws IOException
	{
		Path inputPath = path.resolve(DOCUMENT_PATH).resolve(document);
		Path outputPath = PathUtils.replaceExtension(path.resolve(META_PATH).resolve(document), "txt");
		PdfDataExtractor pdfExtractor = new PdfDataExtractor(inputPath.toFile());
		String title = pdfExtractor.extractTitle();
		Files.write(outputPath, title.getBytes(), StandardOpenOption.CREATE);
		return;
	}

	public void extractMeta(final boolean overwrite) throws IOException
	{
		Files.walkFileTree(path.resolve(DOCUMENT_PATH), new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				try {
					extractMeta(path.resolve(DOCUMENT_PATH).relativize(file), overwrite);
				}
				catch (Exception e)
				{
					System.err.println("Failed to extract title from PDF: " + e.toString());
				}
				return FileVisitResult.CONTINUE;
			}
		});
	}

/* MALLET topic modelling and weighting */

	public void updateMalletDb(boolean new_db) throws IOException
	{
		Path dbPath = path.resolve(MALLET_PATH).resolve(MALLET_DB);
		Path txtPath = path.resolve(TXT_PATH);

		InstanceList instances;
		ArrayList<Pipe> pipeList = new ArrayList<Pipe>();
		final Set<File> alreadyAdded = new HashSet<File>();

		if (!new_db)
		{
			instances = InstanceList.load(dbPath.toFile());
			for (Instance instance : instances)
			{
				Object obj_name = instance.getName();
				if (obj_name instanceof File)
				{
					File name = (File)obj_name;
					alreadyAdded.add(name);
				}
				else
				{
					throw new IOException("Instance did not have a File name.");
				}
			}
		}
		else
		{
			instances = new InstanceList();
		}

		// Pipes: lowercase, tokenize, remove stopwords, map to features
        pipeList.add( new CharSequenceLowercase() );
        pipeList.add( new CharSequence2TokenSequence(Pattern.compile("\\p{L}[\\p{L}\\p{P}]+\\p{L}")) );
        pipeList.add( new TokenSequenceRemoveStopwords(new File("stoplists/en.txt"), "UTF-8", false, false, false) );
        pipeList.add( new TokenSequence2FeatureSequence() );

        instances.setPipe(new SerialPipes(pipeList));

		class AddedFilter implements FileFilter {
			public boolean accept(File file)
			{
				return !alreadyAdded.contains(file);
			}
		}

		FileIterator iterator = new FileIterator(new File[] {txtPath.toFile()}, new AddedFilter(), FileIterator.ALL_DIRECTORIES);
		instances.addThruPipe(iterator);

		ObjectOutputStream oos;
		oos = new ObjectOutputStream(new FileOutputStream(dbPath.toFile()));
		oos.writeObject(instances);
		oos.close();
	}

	public void buildTopicModel(int numTopics) throws IOException
	{
		Path dbPath = path.resolve(MALLET_PATH).resolve(MALLET_DB);
		Path modelPath = path.resolve(MALLET_PATH).resolve(MALLET_TOPIC_MODEL);

		InstanceList instances = InstanceList.load(dbPath.toFile());

		ParallelTopicModel model = new ParallelTopicModel(numTopics, 1.0, 0.01);
		model.addInstances(instances);

		model.setNumThreads(4);
		model.setNumIterations(1000);
		model.setOptimizeInterval(10);
		model.estimate();

		ObjectOutputStream oos;
		oos = new ObjectOutputStream(new FileOutputStream(modelPath.toFile()));
		oos.writeObject(model);
		oos.close();
	}

	public Map<String,List<String>> getTopics(int wordCount) throws Exception
	{
		Path modelPath = path.resolve(MALLET_PATH).resolve(MALLET_TOPIC_MODEL);
		ParallelTopicModel model = ParallelTopicModel.read(modelPath.toFile());
		Object[][] topWords = model.getTopWords(wordCount);
		Map<String,List<String>> topics = new HashMap<String,List<String>>();
		for (int topic_idx = 0; topic_idx < topWords.length; topic_idx++)
		{
			String topicName = "T"+Integer.toString(topic_idx);
			List<String> topWordsForTopic = new ArrayList<String>(wordCount);

			for (int word_idx = 0; word_idx < wordCount; word_idx++)
			{
				String word = (String)topWords[topic_idx][word_idx];
				topWordsForTopic.add(word);
			}

			topics.put(topicName, topWordsForTopic);
		}
		return topics;
	}

	public Map<String, Map<String,Double>> getTopicWeights() throws Exception
	{
		Path dbPath = path.resolve(MALLET_PATH).resolve(MALLET_DB);
		Path modelPath = path.resolve(MALLET_PATH).resolve(MALLET_TOPIC_MODEL);
		ParallelTopicModel model = ParallelTopicModel.read(modelPath.toFile());

		Map<String, Map<String,Double>> result = new HashMap<String,Map<String,Double>>();
		/* TODO: Infer for documents which are not in the model. */
		for (TopicAssignment assignment : model.getData())
		{
			Instance instance = assignment.instance;
			LabelSequence topics = assignment.topicSequence;
			String name = (String)instance.getName();
			double[] probabilities = model.getTopicProbabilities(topics);
			Map<String,Double> topicWeights = new HashMap<String,Double>();
			for (int topic_idx = 0; topic_idx < probabilities.length; topic_idx++)
			{
				topicWeights.put("T"+Integer.toString(topic_idx), probabilities[topic_idx]);
			}
			name = PathUtils.replaceExtension(Paths.get(new URI(name)).relativize(path.resolve(TXT_PATH)), "pdf").toString();

			result.put(name, topicWeights);
		}
		return result;
	}
}
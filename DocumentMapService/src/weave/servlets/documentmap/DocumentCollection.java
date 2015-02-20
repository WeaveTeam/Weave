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
import java.awt.Graphics2D;
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

import javax.servlet.*;
import javax.servlet.http.*;
import weave.servlets.WeaveServlet;
import weave.servlets.WeaveServlet.ServletRequestInfo;

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
	private Path servletPath;
	public DocumentCollection(Path basePath, String name, Path servletPath) throws IOException
	{
		if (!PathUtils.filenameIsLegal(name)) throw new IOException("Collection name contains unsafe or invalid characters.");
		this.path = basePath.resolve(name);
		this.servletPath = servletPath;
	}

	public boolean exists()
	{
		return Files.exists(path);
	}
/*TODO: only walk filetree once and cache list of documents */
	public void addZip(String fileName, InputStream stream) throws IOException, ZipException, IllegalStateException
	{
		int file_count = 0;
		Path zipPath = path.resolve(UPLOAD_PATH).resolve(fileName);
		if (!PathUtils.filenameIsLegal(fileName) || !PathUtils.isChildOf(path.resolve(UPLOAD_PATH), zipPath))
			throw new IOException("Filename contains unsafe or invalid characters or path elements.");
		if (stream != null) Files.copy(stream, zipPath); /* For the case where it's a local zip file. */
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
		return;
	}

	public void addDocument(String fileName, InputStream stream) throws IOException
	{
		addDocument(Paths.get(fileName), stream);
	}
	public void addDocument(Path file, InputStream stream) throws IOException
	{
		Path filePath = path.resolve(DOCUMENT_PATH).resolve(file);
		if (!PathUtils.isChildOf(path.resolve(DOCUMENT_PATH), filePath))
			throw new IOException("File path "+filePath.toString()+" refers to a location above the parent directory.");
		Files.copy(stream, filePath);
	}

	public void create() throws IOException
	{
		if (Files.exists(path)) throw new IOException("Collection by that name already exists.");

		Files.createDirectories(path.resolve(UPLOAD_PATH));
		Files.createDirectories(path.resolve(MALLET_PATH));
		Files.createDirectories(path.resolve(DOCUMENT_PATH));
		Files.createDirectories(path.resolve(TXT_PATH));
		Files.createDirectories(path.resolve(META_PATH));
		Files.createDirectories(path.resolve(THUMBNAIL_PATH));
	}

	public void remove() throws IOException
	{
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

			Image small_image = full_image.getScaledInstance(scaled_width, scaled_height, Image.SCALE_SMOOTH);
			/* http://stackoverflow.com/questions/13605248/java-converting-image-to-bufferedimage */
			BufferedImage bimage = new BufferedImage(small_image.getWidth(null), small_image.getHeight(null), BufferedImage.TYPE_3BYTE_BGR);

		    // Draw the image on to the buffered image
		    Graphics2D bGr = bimage.createGraphics();
		    bGr.drawImage(small_image, 0, 0, null);
		    bGr.dispose();
		    Files.createDirectories(outputPath.getParent());
		    System.err.println("Rendering to " + outputPath.toString());
			ImageIO.write(bimage, "jpg" , outputPath.toFile());
		}
	}
	public void renderThumbnails(final boolean overwrite) throws IOException
	{
		Files.walkFileTree(path.resolve(DOCUMENT_PATH), new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				try {
					System.err.println("Rendering " + path.resolve(DOCUMENT_PATH).relativize(file).toString());
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

	private final int STREAM_CHUNK_SIZE = 2048;
	private int copyStream(InputStream in, OutputStream out) throws IOException
	{
		byte b[] = new byte[STREAM_CHUNK_SIZE];
		int total_length = 0;
		int read_length = -1;
		while ((read_length = in.read(b, 0, STREAM_CHUNK_SIZE)) != -1)
		{
			out.write(b, 0, read_length);
			total_length += read_length;
		}
		return total_length;
	}

/* Thumbnail and document column requests */
/* TODO: verify that document does not walk outside the collection folder. */

	private void serveFile(Path inputPath, String mime, ServletRequestInfo info) throws IOException
	{
		ServletOutputStream outputStream = info.getOutputStream();
		HttpServletResponse response = info.response;
		response.setContentType(mime);		
		InputStream inputStream = Files.newInputStream(inputPath);
		int length = copyStream(inputStream, outputStream);
		response.setContentLength(length);
		inputStream.close();
		outputStream.flush();
	}

	public void getThumbnail(Path document, ServletRequestInfo info) throws IOException
	{	
		Path inputPath = PathUtils.replaceExtension(path.resolve(THUMBNAIL_PATH).resolve(document), "jpg");
		serveFile(inputPath, "image/jpeg", info);
		return;
	}

	public void getDocument(Path document, ServletRequestInfo info) throws IOException
	{
		Path inputPath = path.resolve(DOCUMENT_PATH).resolve(document);
		serveFile(inputPath, "application/pdf", info);
		return;
	}

/* docears heuristic metadata extraction. */
/* TODO: This belongs in a database. */
	public Map<String,String> getModifiedTimes() throws IOException
	{
		final Map<String,String> times = new HashMap<String,String>();
		Files.walkFileTree(path.resolve(DOCUMENT_PATH), new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				try {
					Path relativePath = path.resolve(DOCUMENT_PATH).relativize(file);
					FileTime time = Files.getLastModifiedTime(file);
					times.put(relativePath.toString(), time.toString());
				}
				catch (Exception e)
				{
					System.err.println("Failed to retrieve modification datestamp: " + e.toString());
				}
				return FileVisitResult.CONTINUE;
			}
		});
		return times;
	}
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
					System.err.println("Failed to retrieve stored metadata: " + e.toString());
				}
				return FileVisitResult.CONTINUE;
			}
		});
		return titles;
	}

	public void extractMeta(Path document, boolean overwrite) throws IOException
	{
		/* TODO check if it already exists when overwrite is false before doing the extraction */
		Path inputPath = path.resolve(DOCUMENT_PATH).resolve(document);
		Path outputPath = PathUtils.replaceExtension(path.resolve(META_PATH).resolve(document), "txt");

		if (!overwrite && Files.exists(outputPath)) return;

		PdfDataExtractor pdfExtractor = new PdfDataExtractor(inputPath.toFile());
		String title = pdfExtractor.extractTitle();

		Files.createDirectories(outputPath.getParent());
		Files.deleteIfExists(outputPath);
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

		if (new_db || !Files.exists(dbPath))
		{
			instances = new InstanceList();	
		}
		else
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
		// Read from file
		pipeList.add( new Input2CharSequence("UTF-8") );
		// Pipes: lowercase, tokenize, remove stopwords, map to features
		pipeList.add( new CharSequence2TokenSequence(Pattern.compile("\\p{L}[\\p{L}\\p{P}]+\\p{L}")) );
        pipeList.add( new TokenSequenceLowercase() );
        pipeList.add( new TokenSequenceRemoveStopwords(servletPath.resolve("static").resolve("en.txt").toFile(), "UTF-8", false, false, false) );
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
			URI name = (URI)instance.getName();
			double[] probabilities = model.getTopicProbabilities(topics);
			Map<String,Double> topicWeights = new HashMap<String,Double>();
			for (int topic_idx = 0; topic_idx < probabilities.length; topic_idx++)
			{
				topicWeights.put("T"+Integer.toString(topic_idx), probabilities[topic_idx]);
			}
			/* Hackery to deal with the fact the result from Paths.get(URI) is not the same Filesystem as everything else. */
			Path localPath = Paths.get(Paths.get(name).toString());
			Path relativePath = path.resolve(TXT_PATH).toAbsolutePath().relativize(localPath);

			String str_name = PathUtils.replaceExtension(relativePath, "pdf").toString();

			result.put(str_name, topicWeights);
		}
		return result;
	}
}
package weave.servlets.documentmap;

import weave.servlets.PathUtils;
import org.apache.tika.Tika;
import java.nio.charset.Charset;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.zip.*;
import java.io.*;
import org.apache.commons.io.input.ReaderInputStream;
import java.awt.geom.Point2D;
import com.sun.pdfview.PDFRenderer;

public class DocumentCollection
{
	private static final String UPLOAD_PATH = "uploads";
	private static final String MALLET_MODEL_PATH = "mallet";
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

	public boolean addZip(String fileName, InputStream stream) throws IOException, ZipException, IllegalStateException
	{
		int file_count = 0;
		zipPath = path.resolve(UPLOAD_PATH).resolve(fileName);
		Files.copy(zipStream, zipPath);
		ZipFile zip = new ZipFile(zipPath.toFile());
		try
		{
			for (ZipEntry entry: zip.entries())
			{
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
	}

	public void addDocument(String fileName, InputStream stream) throws IOException
	{
		if (!PathUtils.filenameIsLegal(fileName)) return false;
		return addDocument(Paths.get(fileName), stream);
	}
	public void addDocument(Path file, InputStream stream) throws IOException
	{
		Path filePath = path.resolve(DOCUMENT_PATH).resolve(file);
		Files.copy(stream, filePath);
	}

	public boolean create()
	{
		if (!PathUtils.filenameIsLegal(path.getFileName())) return false;
		if (Files.exists(path)) return false;

		Files.createDirectories(path.resolve(UPLOAD_PATH));
		Files.createDirectories(path.resolve(MALLET_MODEL_PATH));
		Files.createDirectories(path.resolve(DOCUMENT_PATH));
		Files.createDirectories(path.resolve(TXT_PATH));
		Files.createDirectories(path.resolve(META_PATH));

		return true;
	}

	public boolean remove()
	{
			if (!filenameIsLegal(path.getFileName())) return false;
			if (!Files.exists(path)) return false;
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
	private static final Charset UTF8 = new Charset("UTF-8", null);
	public static Tika tika;

	public boolean extractText(Path document, boolean overwrite) throws IOException
	{		
		Path inputPath = path.resolve(DOCUMENT_PATH).resolve(document);
		Path outputPath = path.resolve(TXT_PATH).resolve(document);
		if (overwrite || !Files.exists(outputPath))
		{
			if (tika == null) tika = new Tika();
			Reader reader = tika.parse(inputPath.toFile());
			Files.createDirectories(textPath.getParent());
			Files.deleteIfExists(textPath);
			Files.copy(new ReaderInputStream(reader, utf8), outputPath)
		}
	}

	public boolean extractText(boolean overwrite) throws IOException
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
	public static PDFRenderer renderer;


	public boolean renderThumbnail(Path document, boolean overwrite)
	{
		
	}
	public boolean renderThumbnails(boolean overwrite)
	{

	}

/* docears heuristic metadata extraction. */

	public boolean extractMeta(Path document, boolean overwrite)
	{

	}

	public boolean extractMeta(boolean overwrite)
	{

	}

/* MALLET topic modelling and weighting */

	public boolean buildTopicModel(int num_topics)
	{

	}

	public boolean buildTopicWeights(boolean overwrite)
	{

	}

	public Map<String, Vector<double>> getTopicWeights()
	{

	}

/* R/qgraph force-directed layout */

	public boolean buildLayout(Map<String, Point2D.Double> initial, Set<String> overridden)
	{

	}

	public Map<String, Point2D.Double> getLayout()
	{

	}
 


}
package weave.servlets.documentmap;

import weave.servlets.PathUtils;
import org.apache.tika.Tika;
import java.nio.charset.Charset;
import java.lang.Math;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Vector;
import java.util.Set;
import java.util.zip.*;
import java.util.Enumeration;
import java.io.*;
import java.nio.file.*;
import java.nio.channels.*;
import java.nio.file.attribute.*;
import org.apache.commons.io.input.ReaderInputStream;
import java.awt.geom.Point2D;

/* Dependencies for PDF Rendering */
import java.nio.ByteBuffer;
import com.sun.pdfview.*;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.awt.Rectangle;
import javax.imageio.ImageIO;


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
		Files.createDirectories(path.resolve(MALLET_MODEL_PATH));
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
		Path outputPath = path.resolve(TXT_PATH).resolve(document);
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
					System.err.println("Failed to render PDF.");
				}
				return FileVisitResult.CONTINUE;
			}
		});

	}

/* docears heuristic metadata extraction. */

	public void extractMeta(Path document, boolean overwrite)
	{

	}

	public void extractMeta(boolean overwrite)
	{

	}

/* MALLET topic modelling and weighting */

	public void buildTopicModel(int num_topics)
	{

	}

	public void buildTopicWeights(boolean overwrite)
	{

	}

	public Map<String, List<Double>> getTopicWeights()
	{
		return null;
	}

/* R/qgraph force-directed layout */

	public void buildLayout(Map<String, Point2D.Double> initial, Set<String> overridden)
	{

	}

	public Map<String, Point2D.Double> getLayout()
	{
		return null;
	}
 


}
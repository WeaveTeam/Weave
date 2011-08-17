package weave.servlets;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * Represents an R object that is not converted to Java types when returned.
 * The object is cached in the R environment.
 */
public class JRIOpaque {

	/** Name of the cache variable. */
	public static final String name = "mycache";
	private static AtomicInteger counter = new AtomicInteger();
	private int id;

	/** Creates opaque with unique id. */
	JRIOpaque() {
		id = counter.incrementAndGet();
	}

	public String toString() {
		return name + "[[" + id + "]]";
	}

}

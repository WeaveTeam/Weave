import java.io.File;
import java.io.PrintWriter;
import java.net.URL;

import com.google.template.soy.SoyFileSet;
import com.google.template.soy.tofu.SoyTofu;


public class HelloWorld
{
	public static HelloWorld inst;
	
	public static void main(String[] args)
	{
		try{
			inst = new HelloWorld();
			URL soyFile = inst.getClass().getResource("input/hello-world.soy");
			
			// Bundle the Soy files for your project into a SoyFileSet.
		    SoyFileSet sfs = new SoyFileSet.Builder().add(new File(soyFile.getFile())).build();
	
		    // Compile the template into a SoyTofu object.
		    SoyTofu tofu = sfs.compileToTofu();
	
		    // SoyTofu's newRenderer method returns an object that can render any template in the file set.
		    String outputHTML = tofu.newRenderer("weave.samples.helloWorld").render();
		    
		    //write the output to a file
		    URL outputDir = inst.getClass().getResource("/output");
		    PrintWriter out = new PrintWriter(outputDir.getPath()+"/hello-world.html");
		    out.print(outputHTML);
		    out.close();
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}
}
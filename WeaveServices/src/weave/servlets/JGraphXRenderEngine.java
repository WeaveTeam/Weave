package weave.servlets;

import java.util.Map;
import java.util.HashMap;

import java.rmi.RemoteException;
import com.mxgraph.view.mxGraph;
import com.mxgraph.util.mxCellRenderer;
import java.awt.image.BufferedImage;
import java.awt.Color;
import javax.imageio.ImageIO;
import weave.servlets.RenderService.RenderContext;
import weave.servlets.DataService.FilteredColumnRequest;
import weave.beans.WeaveRecordList;
import weave.beans.QualifiedKey;
import java.io.ByteArrayOutputStream;
public class JGraphXRenderEngine extends RenderContext
{
    private mxGraph graph = null;
    BufferedImage imageBuffer = null;
    public JGraphXRenderEngine(RenderService parent)
    {
        super(parent);
    }
    public boolean render()
    {
        imageBuffer = mxCellRenderer.createBufferedImage(graph, null, 1, Color.WHITE, false, null); 
        return true;
    }
    public boolean setParams(Map<String,String> params)
    {
        return false;
    }
    private static void addNodes(mxGraph g, WeaveRecordList nodes)
    {
        int i;
        int wrl_len;
        wrl_len = nodes.recordKeys.length;
        for (i = 0; i < wrl_len; i++)
        {
            int label_idx = 0;
            String key = nodes.recordKeys[i];   

            Object label_id = nodes.recordData[label_idx][i]; 
            System.out.println(String.format("node %s %s", key, (String)label_id));
        }
        return;
    }
    private static void addEdges(mxGraph g, WeaveRecordList edges)
    {
        int i;
        int wrl_len;
        wrl_len = edges.recordKeys.length; 
        for (i = 0; i < wrl_len; i++)
        {
            int src_idx = 0;
            int dest_idx = 1;
            int label_idx = 2;
            String key = edges.recordKeys[i];

            Object src_id = edges.recordData[src_idx][i];
            Object dest_id = edges.recordData[dest_idx][i];
            System.out.println(String.format("edge %s %s %s", key,(String)src_id, (String)dest_id));
        }
        return;
    }
    private static mxGraph buildGraphFromRecords(WeaveRecordList nodes, WeaveRecordList edges) throws RemoteException
    {
        mxGraph g = new mxGraph();
        addNodes(g, nodes);
        addEdges(g, edges);
        return g;
    }
    public boolean setData(Map<String,String> columns) throws RemoteException
    {
        int nodeLabelId;
        int edgeSrcId;
        int edgeDestId;
        try 
        {
            nodeLabelId = Integer.parseInt(columns.get("nodeLabels"));
            edgeSrcId = Integer.parseInt(columns.get("edgeSrc"));
            edgeDestId = Integer.parseInt(columns.get("edgeDestId"));
        }
        catch (Exception e)
        {
            return false;
            /* Needed column identifiers not specified. */
        }
        FilteredColumnRequest[] filteredColumnRequest = new FilteredColumnRequest[1];
        filteredColumnRequest[0] = new FilteredColumnRequest();
        filteredColumnRequest[0].id = nodeLabelId;
        WeaveRecordList wrl_nodes = DataService.getFilteredRows(filteredColumnRequest, null);
        filteredColumnRequest = new FilteredColumnRequest[2];
        filteredColumnRequest[0] = new FilteredColumnRequest();
        filteredColumnRequest[0].id = edgeSrcId;
        filteredColumnRequest[1] = new FilteredColumnRequest();
        filteredColumnRequest[1].id = edgeDestId;
        WeaveRecordList wrl_edges = DataService.getFilteredRows(filteredColumnRequest, null);
        graph = buildGraphFromRecords(wrl_nodes, wrl_edges);
        return true;
    }
    public String getImage()
    {
        /* With no arguments, retrieve the full image. */ 
        int width, height;
        width = imageBuffer.getWidth();
        height = imageBuffer.getHeight();
        return getImage(0,0,width,height);
    }
    public String getImage(int x1, int y1, int x2, int y2)
    {
        /* Retrieve a sub-image */
        int width,height;
        width = x2-x1;
        height = y2-y1;
        BufferedImage subImage = imageBuffer.getSubimage(x1, y1, width, height);
        ByteArrayOutputStream ostream = new ByteArrayOutputStream();
        try 
        {
            ImageIO.write(subImage, "png", ostream);
            ostream.close();
        }
        catch (Exception e)
        {
            return "";
        }
        return ostream.toString();
    }
    public QualifiedKey probe(int x, int y)
    {
        return null;
    }
}

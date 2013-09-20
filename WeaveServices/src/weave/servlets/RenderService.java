package weave.servlets;


import static weave.config.WeaveConfig.getConnectionConfig;
import static weave.config.WeaveConfig.getDataConfig;
import static weave.config.WeaveConfig.getDocrootPath;
import static weave.config.WeaveConfig.getUploadPath;
import static weave.config.WeaveConfig.initWeaveConfig;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;
import java.util.UUID;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.UploadFileFilter;
import weave.beans.UploadedFile;
import weave.beans.WeaveFileInfo;
import weave.config.ConnectionConfig;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.ConnectionConfig.DatabaseConfigInfo;
import weave.config.DataConfig;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityWithChildren;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.EntityHierarchyInfo;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;
import weave.config.WeaveConfig;
import weave.config.WeaveContextParams;
import weave.geometrystream.GeometryStreamConverter;
import weave.geometrystream.SHPGeometryStreamUtils;
import weave.geometrystream.SQLGeometryStreamDestination;
import weave.utils.BulkSQLLoader;
import weave.utils.CSVParser;
import weave.utils.DBFUtils;
import weave.utils.FileUtils;
import weave.utils.ListUtils;
import weave.utils.ProgressManager.ProgressPrinter;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;

public class RenderService extends GenericServlet
{
    private Map<UUID,RenderContext> contexts;
    public RenderService()
    {
        contexts = new HashMap<UUID,RenderContext>();
    }
    public void init(ServletConfig config) throws ServletException
    {
        super.init(config);
    }
    
    public String getRenderContext(String backendType) throws RemoteException
    {
        UUID id = UUID.randomUUID();
        contexts.put(id, new JGraphXRenderEngine(this));
        return id.toString();
    }
    public boolean destroyRenderContext(String contextUuid) throws RemoteException
    {
        UUID id = UUID.fromString(contextUuid);
        contexts.remove(id);
        return true;
    }
    public boolean setData(String contextUuid, Map<String,Integer> columns) throws RemoteException
    {
        UUID id = UUID.fromString(contextUuid);
        RenderContext ctx = contexts.get(id);
        return ctx.setData(columns);
    }
    public boolean setParams(String contextUuid, Map<String,String> params) throws RemoteException
    {
        UUID id = UUID.fromString(contextUuid);
        RenderContext ctx = contexts.get(id);
        return ctx.setParams(params);
    }
    public String getImage(String contextUuid, int x1, int y1, int x2, int y2, int width, int height) throws RemoteException/* width and height are scaling params */
    {
        UUID id = UUID.fromString(contextUuid); 
        RenderContext ctx = contexts.get(id);
        String imgData = ctx.getImage(x1,y1,x2,y2);
        return imgData;
    }
    public boolean render(String contextUuid) throws RemoteException
    {
        UUID id = UUID.fromString(contextUuid);
        RenderContext ctx = contexts.get(id);
        return ctx.render();
    }
    public QualifiedKey probe(String contextUuid, int x, int y)
    {
        UUID id =UUID.fromString(contextUuid);
        RenderContext ctx = contexts.get(id);
        return ctx.probe(x,y);
    }
    public static class QualifiedKey
    {
        public String keyType;
        public String keyValue;
        public QualifiedKey(String newKeyType, String newKeyValue)
        {
            keyType = newKeyType;
            keyValue = newKeyValue;
        }
    }
    public static abstract class RenderContext
    {
        private RenderService parent;

        public RenderContext(RenderService parent)
        {
            this.parent = parent;
        }
        abstract public boolean render() throws RemoteException;
        abstract public boolean setParams(Map<String,String> params) throws RemoteException;
        abstract public boolean setData(Map<String,Integer> columns) throws RemoteException;
        abstract public String getImage(int x1, int y1, int x2, int y2) throws RemoteException;
        abstract public QualifiedKey probe(int x, int y) throws RemoteException;
    }
}

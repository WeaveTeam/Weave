// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2004 The jTDS Project
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

package net.sourceforge.jtds.test;

import java.sql.*;
import java.math.BigDecimal;
import junit.framework.TestSuite;
import java.io.*;

import net.sourceforge.jtds.util.Logger;

/**
 *
 * @author Alin Sinpalean
 * @version $Id: CSUnitTest.java,v 1.12.6.2 2009-11-06 08:24:24 ickzon Exp $
 */
public class CSUnitTest extends DatabaseTestCase {
    public CSUnitTest(String name) {
        super(name);

        if (output == null)
            try {
                output = new PrintStream(new FileOutputStream("nul"));
            } catch (FileNotFoundException ex) {
                throw new RuntimeException("could not create device nul");
            }
    }

    static PrintStream output = null;

    public static void main(String args[]) {
        Logger.setActive(true);

        if (args.length > 0) {
            output = System.out;
            junit.framework.TestSuite s = new TestSuite();

            for (int i = 0; i < args.length; i++) {
                s.addTest(new CSUnitTest(args[i]));
            }

            junit.textui.TestRunner.run(s);
        } else {
            junit.textui.TestRunner.run(CSUnitTest.class);
        }
    }


    public void testMaxRows0003() throws Exception {
        dropTable("#t0003");
        Statement stmt = con.createStatement();

        stmt.executeUpdate("create table #t0003           "
                         + "  (i  integer not null)       ");
        stmt.close();

        PreparedStatement  pstmt = con.prepareStatement(
                "insert into #t0003 values (?)");

        final int rowsToAdd = 100;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            count += pstmt.executeUpdate();
        }

        assertEquals("count: " + count + " rowsToAdd: " + rowsToAdd, rowsToAdd, count);
        pstmt.close();
        pstmt = con.prepareStatement("select i from #t0003 order by i");
        int rowLimit = 32;
        pstmt.setMaxRows(rowLimit);

        assertTrue(pstmt.getMaxRows() == rowLimit);
        ResultSet  rs = pstmt.executeQuery();
        count = 0;

        while (rs.next()) {
            count++;
            assertEquals(rs.getInt("i"), count);
        }
        pstmt.close();

        assertEquals(rowLimit, count);
    }



    public void testGetAsciiStream0018() throws Exception {
        Statement stmt = con.createStatement();
        ResultSet rs;

        String bigtext1 =
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "abcdefghijklmnop" +
        "";
        String bigimage1 = "0x" +
                           "0123456789abcdef" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "fedcba9876543210" +
                           "";
        dropTable("#t0018");
        String sql =
        "create table #t0018 (                                  " +
        " mybinary                   binary(5) not null,       " +
        " myvarbinary                varbinary(4) not null,    " +
        " mychar                     char(10) not null,        " +
        " myvarchar                  varchar(8) not null,      " +
        " mytext                     text not null,            " +
        " myimage                    image not null,           " +
        " mynullbinary               binary(3) null,           " +
        " mynullvarbinary            varbinary(6) null,        " +
        " mynullchar                 char(10) null,            " +
        " mynullvarchar              varchar(40) null,         " +
        " mynulltext                 text null,                " +
        " mynullimage                image null)               ";

        assertEquals(stmt.executeUpdate(sql), 0);
        // Insert a row without nulls via a Statement
        sql =
        "insert into #t0018(       " +
        " mybinary,               " +
        " myvarbinary,            " +
        " mychar,                 " +
        " myvarchar,              " +
        " mytext,                 " +
        " myimage,                " +
        " mynullbinary,           " +
        " mynullvarbinary,        " +
        " mynullchar,             " +
        " mynullvarchar,          " +
        " mynulltext,             " +
        " mynullimage             " +
        ")                        " +
        "values(                  " +
        " 0xffeeddccbb,           " +  // mybinary
        " 0x78,                   " +  // myvarbinary
        " 'Z',                    " +  // mychar
        " '',                     " +  // myvarchar
        " '" + bigtext1 + "',     " +  // mytext
        " " + bigimage1 + ",      " +  // myimage
        " null,                   " +  // mynullbinary
        " null,                   " +  // mynullvarbinary
        " null,                   " +  // mynullchar
        " null,                   " +  // mynullvarchar
        " null,                   " +  // mynulltext
        " null                    " +  // mynullimage
        ")";


        assertEquals(stmt.executeUpdate(sql), 1);

        sql = "select * from #t0018";
        rs = stmt.executeQuery(sql);
        if (!rs.next()) {
            fail("should get Result");
        } else {
            output.println("Getting the results");
            output.println("mybinary is " + rs.getObject("mybinary"));
            output.println("myvarbinary is " + rs.getObject("myvarbinary"));
            output.println("mychar is " + rs.getObject("mychar"));
            output.println("myvarchar is " + rs.getObject("myvarchar"));
            output.println("mytext is " + rs.getObject("mytext"));
            output.println("myimage is " + rs.getObject("myimage"));
            output.println("mynullbinary is " + rs.getObject("mynullbinary"));
            output.println("mynullvarbinary is " + rs.getObject("mynullvarbinary"));
            output.println("mynullchar is " + rs.getObject("mynullchar"));
            output.println("mynullvarchar is " + rs.getObject("mynullvarchar"));
            output.println("mynulltext is " + rs.getObject("mynulltext"));
            output.println("mynullimage is " + rs.getObject("mynullimage"));
        }
        stmt.close();
    }


    public void testMoneyHandling0019() throws Exception {
        java.sql.Statement  stmt;
        int                 i;
        BigDecimal          money[] = {
            new BigDecimal("922337203685477.5807"),
            new BigDecimal("-922337203685477.5807"),
            new BigDecimal("1.0000"),
            new BigDecimal("0.0000"),
            new BigDecimal("-1.0000")
        };
        BigDecimal          smallmoney[] = {
            new BigDecimal("214748.3647"),
            new BigDecimal("-214748.3648"),
            new BigDecimal("1.0000"),
            new BigDecimal("0.0000"),
            new BigDecimal("-1.0000")
        };

        if (smallmoney.length != money.length) {
            throw new SQLException("Must have same number of elements in " +
                                   "money and smallmoney");
        }

        stmt = con.createStatement();

        dropTable("#t0019");


        stmt.executeUpdate("create table #t0019 (                     " +
                           "  i               integer primary key,   " +
                           "  mymoney         money not null,        " +
                           "  mysmallmoney    smallmoney not null)   " +
                           "");

        for (i=0; i<money.length; i++) {
            stmt.executeUpdate("insert into #t0019 values (" +
                               i + ", " + money[i] + ",   " +
                               smallmoney[i] + ")         ");
        }


        // long l = System.currentTimeMillis();
        // while (l + 500 > System.currentTimeMillis()) ;
        ResultSet rs = stmt.executeQuery("select * from #t0019 order by i");

        for (i=0; rs.next(); i++) {
            BigDecimal  m;
            BigDecimal  sm;

            m = (BigDecimal)rs.getObject("mymoney");
            sm = (BigDecimal)rs.getObject("mysmallmoney");

            assertEquals(m, money[i]);
            assertEquals(sm, smallmoney[i]);

            output.println(m + ", " + sm);
        }
        stmt.close();
    }

    /*
    public void testBooleanAndCompute0026() throws Exception {
      Statement   stmt = con.createStatement();
      dropTable("#t0026");
      int count = stmt.executeUpdate("create table #t0026             " +
      "  (i      integer,             " +
      "   b      bit,                 " +
      "   s      char(5),             " +
      "   f      float)               ");
      output.println("Creating table affected " + count + " rows");

      stmt.executeUpdate("insert into #t0026 values(0, 0, 'false', 0.0)");
      stmt.executeUpdate("insert into #t0026 values(0, 0, 'N', 10)");
      stmt.executeUpdate("insert into #t0026 values(1, 1, 'true', 7.0)");
      stmt.executeUpdate("insert into #t0026 values(2, 1, 'Y', -5.0)");

      ResultSet  rs = stmt.executeQuery(
      "select * from #t0026 order by i compute sum(f) by i");

      assertTrue(rs.next());

      assertTrue(!(rs.getBoolean("i")
      || rs.getBoolean("b")
      || rs.getBoolean("s")
      || rs.getBoolean("f")));

      assertTrue(rs.next());

      assertTrue(!(rs.getBoolean("i")
      || rs.getBoolean("b")
      || rs.getBoolean("s")
      || rs.getBoolean("f")));
      assertTrue(rs.next());

      assertTrue(rs.getBoolean("i")
      && rs.getBoolean("b")
      && rs.getBoolean("s")
      && rs.getBoolean("f"));
      assertTrue(rs.next());

      assertTrue(rs.getBoolean("i")
      && rs.getBoolean("b")
      && rs.getBoolean("s")
      && rs.getBoolean("f"));

      ResultSet  rs = stmt.executeQuery(
         "select * from #t0026 order by i compute sum(f) by i");



      if (!rs.next())
      {
         throw new SQLException("Failed");
      }
      passed = passed && (! (rs.getBoolean("i")
                             || rs.getBoolean("b")
                             || rs.getBoolean("s")
                             || rs.getBoolean("f")));


      if (!rs.next())
      {
         throw new SQLException("Failed");
      }
      passed = passed && (! (rs.getBoolean("i")
                             || rs.getBoolean("b")
                             || rs.getBoolean("s")
                             || rs.getBoolean("f")));


      if (!rs.next())
      {
         throw new SQLException("Failed");
      }
      passed = passed && (rs.getBoolean("i")
                          && rs.getBoolean("b")
                          && rs.getBoolean("s")
                          && rs.getBoolean("f"));

      if (!rs.next())
      {
         throw new SQLException("Failed");
      }
      passed = passed && (rs.getBoolean("i")
                          && rs.getBoolean("b")
                          && rs.getBoolean("s")
                          && rs.getBoolean("f"));

     assertTrue(passed);
    }
    */

    public void testDataTypes0027() throws Exception {
        output.println("Test all the SQLServer datatypes in Statement\n"
                       + "and PreparedStatement using the preferred getXXX()\n"
                       + "instead of getObject like #t0017.java does.");
        output.println("!!!Note- This test is not fully implemented yet!!!");
        Statement   stmt = con.createStatement();
        ResultSet   rs;
        stmt.execute("set dateformat ymd");
        dropTable("#t0027");
        String sql =
        "create table #t0027 (                                  " +
        " mybinary                   binary(5) not null,       " +
        " myvarbinary                varbinary(4) not null,    " +
        " mychar                     char(10) not null,        " +
        " myvarchar                  varchar(8) not null,      " +
        " mydatetime                 datetime not null,        " +
        " mysmalldatetime            smalldatetime not null,   " +
        " mydecimal10_3              decimal(10,3) not null,   " +
        " mynumeric5_4               numeric (5,4) not null,   " +
        " myfloat6                   float(6) not null,        " +
        " myfloat14                  float(6) not null,        " +
        " myreal                     real not null,            " +
        " myint                      int not null,             " +
        " mysmallint                 smallint not null,        " +
        " mytinyint                  tinyint not null,         " +
        " mymoney                    money not null,           " +
        " mysmallmoney               smallmoney not null,      " +
        " mybit                      bit not null,             " +
        " mytimestamp                timestamp not null,       " +
        " mytext                     text not null,            " +
        " myimage                    image not null,           " +
        " mynullbinary               binary(3) null,          " +
        " mynullvarbinary            varbinary(6) null,       " +
        " mynullchar                 char(10) null,            " +
        " mynullvarchar              varchar(40) null,         " +
        " mynulldatetime             datetime null,            " +
        " mynullsmalldatetime        smalldatetime null,       " +
        " mynulldecimal10_3          decimal(10,3) null,       " +
        " mynullnumeric15_10         numeric(15,10) null,      " +
        " mynullfloat6               float(6) null,            " +
        " mynullfloat14              float(14) null,           " +
        " mynullreal                 real null,                " +
        " mynullint                  int null,                 " +
        " mynullsmallint             smallint null,            " +
        " mynulltinyint              tinyint null,             " +
        " mynullmoney                money null,               " +
        " mynullsmallmoney           smallmoney null,          " +
        " mynulltext                 text null,                " +
        " mynullimage                image null)               ";

        assertEquals(stmt.executeUpdate(sql), 0);


        // Insert a row without nulls via a Statement
        sql =
        "insert into #t0027               " +
        "  (mybinary,                    " +
        "   myvarbinary,                 " +
        "   mychar,                      " +
        "   myvarchar,                   " +
        "   mydatetime,                  " +
        "   mysmalldatetime,             " +
        "   mydecimal10_3,               " +
        "   mynumeric5_4,              " +
        "   myfloat6,                    " +
        "   myfloat14,                   " +
        "   myreal,                      " +
        "   myint,                       " +
        "   mysmallint,                  " +
        "   mytinyint,                   " +
        "   mymoney,                     " +
        "   mysmallmoney,                " +
        "   mybit,                       " +
        "   mytimestamp,                 " +
        "   mytext,                      " +
        "   myimage,                     " +
        "   mynullbinary,                " +
        "   mynullvarbinary,             " +
        "   mynullchar,                  " +
        "   mynullvarchar,               " +
        "   mynulldatetime,              " +
        "   mynullsmalldatetime,         " +
        "   mynulldecimal10_3,           " +
        "   mynullnumeric15_10,          " +
        "   mynullfloat6,                " +
        "   mynullfloat14,               " +
        "   mynullreal,                  " +
        "   mynullint,                   " +
        "   mynullsmallint,              " +
        "   mynulltinyint,               " +
        "   mynullmoney,                 " +
        "   mynullsmallmoney,            " +
        "   mynulltext,                  " +
        "   mynullimage)                 " +
        " values                         " +
        "   (0x1213141516,               " + //   mybinary,
        "    0x1718191A,                 " + //   myvarbinary
        "    '1234567890',               " + //   mychar
        "    '12345678',                 " + //   myvarchar
        "    '19991015 21:29:59.01',     " + //   mydatetime
        "    '19991015 20:45',           " + //   mysmalldatetime
        "    1234567.089,                " + //   mydecimal10_3
        "    1.2345,                     " + //   mynumeric5_4
        "    65.4321,                    " + //   myfloat6
        "    1.123456789,                " + //   myfloat14
        "    987654321.0,                " + //   myreal
        "    4097,                       " + //   myint
        "    4094,                       " + //   mysmallint
        "    200,                        " + //   mytinyint
        "    19.95,                      " + //   mymoney
        "    9.97,                       " + //   mysmallmoney
        "    1,                          " + //   mybit
        "    null,                       " + //   mytimestamp
        "    'abcdefg',                  " + //   mytext
        "    0x0AAABB,                   " + //   myimage
        "    0x123456,                   " + //   mynullbinary
        "    0xAB,                       " + //   mynullvarbinary
        "    'z',                        " + //   mynullchar
        "    'zyx',                      " + //   mynullvarchar
        "    '1976-07-04 12:00:00.04',   " + //   mynulldatetime
        "    '2000-02-29 13:46',         " + //   mynullsmalldatetime
        "     1.23,                      " + //   mynulldecimal10_3
        "     7.1234567891,              " + //   mynullnumeric15_10
        "     987654,                    " + //   mynullfloat6
        "     0,                         " + //   mynullfloat14
        "     -1.1,                      " + //   mynullreal
        "     -10,                       " + //   mynullint
        "     126,                       " + //   mynullsmallint
        "     7,                         " + //   mynulltinyint
        "     -19999.00,                 " + //   mynullmoney
        "     -9.97,                     " + //   mynullsmallmoney
        "     '1234',                    " + //   mynulltext
        "     0x1200340056)              " + //   mynullimage)
        "";

        assertEquals(stmt.executeUpdate(sql), 1);

        sql = "select * from #t0027";
        rs = stmt.executeQuery(sql);
        assertTrue(rs.next());
        output.println("mybinary is " + rs.getObject("mybinary"));
        output.println("myvarbinary is " + rs.getObject("myvarbinary"));
        output.println("mychar is " + rs.getString("mychar"));
        output.println("myvarchar is " + rs.getString("myvarchar"));
        output.println("mydatetime is " + rs.getTimestamp("mydatetime"));
        output.println("mysmalldatetime is " + rs.getTimestamp("mysmalldatetime"));
        output.println("mydecimal10_3 is " + rs.getObject("mydecimal10_3"));
        output.println("mynumeric5_4 is " + rs.getObject("mynumeric5_4"));
        output.println("myfloat6 is " + rs.getDouble("myfloat6"));
        output.println("myfloat14 is " + rs.getDouble("myfloat14"));
        output.println("myreal is " + rs.getDouble("myreal"));
        output.println("myint is " + rs.getInt("myint"));
        output.println("mysmallint is " + rs.getShort("mysmallint"));
        output.println("mytinyint is " + rs.getShort("mytinyint"));
        output.println("mymoney is " + rs.getObject("mymoney"));
        output.println("mysmallmoney is " + rs.getObject("mysmallmoney"));
        output.println("mybit is " + rs.getObject("mybit"));
        output.println("mytimestamp is " + rs.getObject("mytimestamp"));
        output.println("mytext is " + rs.getObject("mytext"));
        output.println("myimage is " + rs.getObject("myimage"));
        output.println("mynullbinary is " + rs.getObject("mynullbinary"));
        output.println("mynullvarbinary is " + rs.getObject("mynullvarbinary"));
        output.println("mynullchar is " + rs.getString("mynullchar"));
        output.println("mynullvarchar is " + rs.getString("mynullvarchar"));
        output.println("mynulldatetime is " + rs.getTimestamp("mynulldatetime"));
        output.println("mynullsmalldatetime is " + rs.getTimestamp("mynullsmalldatetime"));
        output.println("mynulldecimal10_3 is " + rs.getObject("mynulldecimal10_3"));
        output.println("mynullnumeric15_10 is " + rs.getObject("mynullnumeric15_10"));
        output.println("mynullfloat6 is " + rs.getDouble("mynullfloat6"));
        output.println("mynullfloat14 is " + rs.getDouble("mynullfloat14"));
        output.println("mynullreal is " + rs.getDouble("mynullreal"));
        output.println("mynullint is " + rs.getInt("mynullint"));
        output.println("mynullsmallint is " + rs.getShort("mynullsmallint"));
        output.println("mynulltinyint is " + rs.getByte("mynulltinyint"));
        output.println("mynullmoney is " + rs.getObject("mynullmoney"));
        output.println("mynullsmallmoney is " + rs.getObject("mynullsmallmoney"));
        output.println("mynulltext is " + rs.getObject("mynulltext"));
        output.println("mynullimage is " + rs.getObject("mynullimage"));
        stmt.close();
    }
    public void testCallStoredProcedures0028() throws Exception {
        Statement   stmt = con.createStatement();
        ResultSet   rs;

        boolean isResultSet;
        int updateCount;

        int resultSetCount=0;
        int rowCount=0;
        int numberOfUpdates=0;


        isResultSet = stmt.execute("EXEC sp_who");
        output.println("execute(EXEC sp_who) returned: " + isResultSet);

        updateCount=stmt.getUpdateCount();

        while (isResultSet || (updateCount!=-1)) {
            if (isResultSet) {
                resultSetCount++;
                rs = stmt.getResultSet();

                ResultSetMetaData rsMeta =  rs.getMetaData();
                int columnCount = rsMeta.getColumnCount();
                output.println("columnCount: " +
                               Integer.toString(columnCount));
                for (int n=1; n<= columnCount; n++) {
                    output.println(Integer.toString(n) + ": " +
                                   rsMeta.getColumnName(n));
                }

                while (rs.next()) {
                    rowCount++;
                    for (int n=1; n<= columnCount; n++) {
                        output.println(Integer.toString(n) + ": " +
                                       rs.getString(n));
                    }
                }

            } else {
                numberOfUpdates += updateCount;
                output.println("UpdateCount: " +
                               Integer.toString(updateCount));
            }
            isResultSet=stmt.getMoreResults();
            updateCount = stmt.getUpdateCount();
        }
        stmt.close();

        output.println("resultSetCount: " + resultSetCount);
        output.println("Total rowCount: " + rowCount);
        output.println("Number of updates: " + numberOfUpdates);


        assertTrue((rowCount>=1) && (numberOfUpdates==0) && (resultSetCount==1));
    }
    public void testxx0029() throws Exception {
        Statement   stmt = con.createStatement();
        ResultSet   rs;

        boolean isResultSet;
        int updateCount;

        int resultSetCount=0;
        int rowCount=0;
        int numberOfUpdates=0;


        output.println("before execute DROP PROCEDURE");

        try {
            isResultSet =stmt.execute("DROP PROCEDURE #t0029_p1");
            updateCount = stmt.getUpdateCount();
            do {
                output.println("DROP PROCEDURE isResultSet: " + isResultSet);
                output.println("DROP PROCEDURE updateCount: " + updateCount);
                isResultSet = stmt.getMoreResults();
                updateCount = stmt.getUpdateCount();
            } while (((updateCount!=-1) && !isResultSet) || isResultSet);
        } catch (SQLException e) {
        }

        try {
            isResultSet =stmt.execute("DROP PROCEDURE #t0029_p2");
            updateCount = stmt.getUpdateCount();
            do {
                output.println("DROP PROCEDURE isResultSet: " + isResultSet);
                output.println("DROP PROCEDURE updateCount: " + updateCount);
                isResultSet = stmt.getMoreResults();
                updateCount = stmt.getUpdateCount();
            } while (((updateCount!=-1) && !isResultSet) || isResultSet);
        } catch (SQLException e) {
        }


        dropTable("#t0029_t1");

        isResultSet =
        stmt.execute(
                    " create table #t0029_t1                       " +
                    "  (t1 datetime not null,                     " +
                    "   t2 datetime null,                         " +
                    "   t3 smalldatetime not null,                " +
                    "   t4 smalldatetime null,                    " +
                    "   t5 text null)                             ");
        updateCount = stmt.getUpdateCount();
        do {
            output.println("CREATE TABLE isResultSet: " + isResultSet);
            output.println("CREATE TABLE updateCount: " + updateCount);
            isResultSet = stmt.getMoreResults();
            updateCount = stmt.getUpdateCount();
        } while (((updateCount!=-1) && !isResultSet) || isResultSet);


        isResultSet =
        stmt.execute(
                    "CREATE PROCEDURE #t0029_p1 AS                " +

                    " insert into #t0029_t1 values                " +
                    " ('1999-01-07', '1998-09-09 15:35:05',       " +
                    " getdate(), '1998-09-09 15:35:00', null)     " +

                    " update #t0029_t1 set t1='1999-01-01'         " +

                    " insert into #t0029_t1 values                " +
                    " ('1999-01-08', '1998-09-09 15:35:05',       " +
                    " getdate(), '1998-09-09 15:35:00','456')     " +

                    " update #t0029_t1 set t2='1999-01-02'        " +

                    " declare @ptr varbinary(16)                  " +
                    " select @ptr=textptr(t5) from #t0029_t1      " +
                    "   where t1='1999-01-08'                     " +
                    " writetext #t0029_t1.t5 @ptr with log '123'  ");

        updateCount = stmt.getUpdateCount();
        do {
            output.println("CREATE PROCEDURE isResultSet: " + isResultSet);
            output.println("CREATE PROCEDURE updateCount: " + updateCount);
            isResultSet = stmt.getMoreResults();
            updateCount = stmt.getUpdateCount();
        } while (((updateCount!=-1) && !isResultSet) || isResultSet);


        isResultSet =
        stmt.execute(
                    "CREATE PROCEDURE #t0029_p2 AS                " +

                    " set nocount on " +
                    " EXEC #t0029_p1                              " +
                    " SELECT * FROM #t0029_t1                     ");

        updateCount = stmt.getUpdateCount();
        do {
            output.println("CREATE PROCEDURE isResultSet: " + isResultSet);
            output.println("CREATE PROCEDURE updateCount: " + updateCount);
            isResultSet = stmt.getMoreResults();
            updateCount = stmt.getUpdateCount();
        } while (((updateCount!=-1) && !isResultSet) || isResultSet);


        isResultSet = stmt.execute( "EXEC  #t0029_p2  ");

        output.println("execute(EXEC #t0029_p2) returned: " + isResultSet);

        updateCount=stmt.getUpdateCount();

        while (isResultSet || (updateCount!=-1)) {
            if (isResultSet) {
                resultSetCount++;
                rs = stmt.getResultSet();

                ResultSetMetaData rsMeta =  rs.getMetaData();
                int columnCount = rsMeta.getColumnCount();
                output.println("columnCount: " +
                               Integer.toString(columnCount));
                for (int n=1; n<= columnCount; n++) {
                    output.println(Integer.toString(n) + ": " +
                                   rsMeta.getColumnName(n));
                }

                while (rs.next()) {
                    rowCount++;
                    for (int n=1; n<= columnCount; n++) {
                        output.println(Integer.toString(n) + ": " +
                                       rs.getString(n));
                    }
                }

            } else {
                numberOfUpdates += updateCount;
                output.println("UpdateCount: " +
                               Integer.toString(updateCount));
            }
            isResultSet=stmt.getMoreResults();
            updateCount = stmt.getUpdateCount();
        }
        stmt.close();

        output.println("resultSetCount: " + resultSetCount);
        output.println("Total rowCount: " + rowCount);
        output.println("Number of updates: " + numberOfUpdates);


        assertTrue((resultSetCount==1) &&
                   (rowCount==2) &&
                   (numberOfUpdates==0));
    }

    public void testDataTypesByResultSetMetaData0030() throws Exception {
        Statement   stmt = con.createStatement();
        ResultSet   rs;

        String sql = ("select " +
                      " convert(tinyint, 2),  " +
                      " convert(smallint, 5)  ");

        rs = stmt.executeQuery(sql);
        if (!rs.next()) {
            fail("Expecting one row");
        } else {
            ResultSetMetaData meta = rs.getMetaData();

            if (meta.getColumnType(1)!=java.sql.Types.TINYINT) {
                fail("tinyint column was read as "
                               + meta.getColumnType(1));
            }
            if (meta.getColumnType(2)!=java.sql.Types.SMALLINT) {
                fail("smallint column was read as "
                               + meta.getColumnType(2));
            }
            if (rs.getInt(1) != 2) {
                fail("Bogus value read for tinyint");
            }
            if (rs.getInt(2) != 5) {
                fail("Bogus value read for smallint");
            }
        }
        stmt.close();
    }
    public void testTextColumns0031() throws Exception {
        Statement   stmt = con.createStatement();

        assertEquals(0, stmt.executeUpdate(
                "create table #t0031                " +
                "  (t_nullable      text null,     " +
                "   t_notnull       text not null, " +
                "   i               int not null)  "));

        stmt.executeUpdate("insert into #t0031 values(null, '',   1)");
        stmt.executeUpdate("insert into #t0031 values(null, 'b1', 2)");
        stmt.executeUpdate("insert into #t0031 values('',   '',   3)");
        stmt.executeUpdate("insert into #t0031 values('',   'b2', 4)");
        stmt.executeUpdate("insert into #t0031 values('a1', '',   5)");
        stmt.executeUpdate("insert into #t0031 values('a2', 'b3', 6)");

        ResultSet  rs = stmt.executeQuery("select * from #t0031 " +
                                          " order by i ");

        assertTrue(rs.next());
        assertEquals(null, rs.getString(1));
        assertEquals("", rs.getString(2));
        assertEquals(1, rs.getInt(3));

        assertTrue(rs.next());
        assertEquals(null, rs.getString(1));
        assertEquals("b1", rs.getString(2));
        assertEquals(2, rs.getInt(3));

        assertTrue(rs.next());
        assertEquals("", rs.getString(1));
        assertEquals("", rs.getString(2));
        assertEquals(3, rs.getInt(3));

        assertTrue(rs.next());
        assertEquals("", rs.getString(1));
        assertEquals("b2", rs.getString(2));
        assertEquals(4, rs.getInt(3));

        assertTrue(rs.next());
        assertEquals("a1", rs.getString(1));
        assertEquals("", rs.getString(2));
        assertEquals(5, rs.getInt(3));

        assertTrue(rs.next());
        assertEquals("a2", rs.getString(1));
        assertEquals("b3", rs.getString(2));
        assertEquals(6, rs.getInt(3));

        stmt.close();
    }

    public void testSpHelpSysUsers0032() throws Exception {
        Statement   stmt = con.createStatement();
        boolean   passed = true;
        boolean   isResultSet;
        boolean   done;
        int       i;
        int       updateCount;

        output.println("Starting test #t0032-  test sp_help sysusers");

        isResultSet = stmt.execute("sp_help sysusers");

        output.println("Executed the statement.  rc is " + isResultSet);

        do {
            if (isResultSet) {
                output.println("About to call getResultSet");
                ResultSet          rs   = stmt.getResultSet();
                ResultSetMetaData  meta = rs.getMetaData();
                updateCount = 0;
                while (rs.next()) {
                    for (i=1; i<=meta.getColumnCount(); i++) {
                        output.print(rs.getString(i) + "\t");
                    }
                    output.println("");
                }
                output.println("Done processing the result set");
            } else {
                output.println("About to call getUpdateCount()");
                updateCount = stmt.getUpdateCount();
                output.println("Updated " + updateCount + " rows");
            }
            output.println("About to call getMoreResults()");
            isResultSet = stmt.getMoreResults();
            done = !isResultSet && updateCount==-1;
        } while (!done);
        stmt.close();

        assertTrue(passed);
    }
    static String longString(char ch) {
        int                 i;
        StringBuffer        str255 = new StringBuffer(255);

        for (i=0; i<255; i++) {
            str255.append(ch);
        }
        return str255.toString();
    }
    public void testExceptionByUpdate0033() throws Exception {
        boolean passed;
        Statement   stmt = con.createStatement();
        output.println("Starting test #t0033-  make sure Statement.executeUpdate() throws exception");

        try {
            passed = false;
            stmt.executeUpdate("I am sure this is an error");
        } catch (SQLException e) {
            output.println("The exception is " + e.getMessage());
            passed = true;
        }
        stmt.close();
        assertTrue(passed);
    }

    public void testInsertConflict0049() throws Exception {
        try {
            dropTable("jTDS_t0049b");    // important: first drop this because of foreign key
            dropTable("jTDS_t0049a");

            Statement   stmt = con.createStatement();

            String query =
                    "create table jTDS_t0049a(               " +
                    "  a integer identity(1,1) primary key,  " +
                    "  b char    not null)";

            assertEquals(0, stmt.executeUpdate(query));

            query = "create table jTDS_t0049b(               " +
                    "  a integer not null,                   " +
                    "  c char    not null,                   " +
                    "  foreign key (a) references jTDS_t0049a(a)) ";
            assertEquals(0, stmt.executeUpdate(query));

            query = "insert into jTDS_t0049b (a, c) values (?, ?)";
            java.sql.PreparedStatement pstmt = con.prepareStatement(query);

            try {
                pstmt.setInt(1, 1);
                pstmt.setString(2, "a");
                pstmt.executeUpdate();
                fail("Was expecting INSERT to fail");
            } catch (SQLException e) {
                assertEquals("23000", e.getSQLState());
            }
            pstmt.close();

            assertEquals(1, stmt.executeUpdate("insert into jTDS_t0049a (b) values ('a')"));

            pstmt = con.prepareStatement(query);
            pstmt.setInt(1, 1);
            pstmt.setString(2, "a");
            assertEquals(1, pstmt.executeUpdate());

            stmt.close();
            pstmt.close();
        } finally {
            dropTable("jTDS_t0049b");    // important: first drop this because of foreign key
            dropTable("jTDS_t0049a");
        }
    }

    public void testxx0050() throws Exception {
        try {
            Statement   stmt = con.createStatement();

            dropTable("jTDS_t0050b");
            dropTable("jTDS_t0050a");

            String query =
                    "create table jTDS_t0050a(               " +
                    "  a integer identity(1,1) primary key,  " +
                    "  b char    not null)";

            assertEquals(0, stmt.executeUpdate(query));

            query =
                    "create table jTDS_t0050b(               " +
                    "  a integer not null,                   " +
                    "  c char    not null,                   " +
                    "  foreign key (a) references jTDS_t0050a(a)) ";
            assertEquals(0, stmt.executeUpdate(query));

            query =
                "create procedure #p0050 (@a integer, @c char) as " +
                "   insert into jTDS_t0050b (a, c) values (@a, @c)";
            assertEquals(0, stmt.executeUpdate(query));

            query = "exec #p0050 ?, ?";
            java.sql.CallableStatement cstmt = con.prepareCall(query);

            try {
                cstmt.setInt(1, 1);
                cstmt.setString(2, "a");
                cstmt.executeUpdate();
                fail("Expecting INSERT to fail");
            } catch (SQLException e) {
                assertEquals("23000", e.getSQLState());
            }

            assertEquals(1, stmt.executeUpdate(
                    "insert into jTDS_t0050a (b) values ('a')"));

            assertEquals(1, cstmt.executeUpdate());

            stmt.close();
            cstmt.close();
        } finally {
            dropTable("jTDS_t0050b");
            dropTable("jTDS_t0050a");
        }
    }

    public void testxx0051() throws Exception {
        boolean passed = true;

        try {
            String           types[] = {"TABLE"};
            DatabaseMetaData dbMetaData = con.getMetaData( );
            ResultSet        rs         = dbMetaData.getTables( null, "%", "t%", types);

            while (rs.next()) {
                output.println("Table " + rs.getString(3));
                output.println("  catalog " + rs.getString(1));
                output.println("  schema  " + rs.getString(2));
                output.println("  name    " + rs.getString(3));
                output.println("  type    " + rs.getString(4));
                output.println("  remarks " + rs.getString(5));
            }
        } catch (java.sql.SQLException e) {
            passed = false;
            output.println("Exception caught.  " + e.getMessage());
            e.printStackTrace();
        }
        assertTrue(passed);
    }
    public void testxx0055() throws Exception {
        boolean passed = true;
        int         i;

        try {
            String           expectedNames[] = {
                "TABLE_CAT",
                "TABLE_SCHEM",
                "TABLE_NAME",
                "TABLE_TYPE",
                "REMARKS",
                "TYPE_CAT",
                "TYPE_SCHEM",
                "TYPE_NAME",
                "SELF_REFERENCING_COL_NAME",
                "REF_GENERATION"
            };
            String           types[] = {"TABLE"};
            DatabaseMetaData dbMetaData = con.getMetaData();
            ResultSet        rs         = dbMetaData.getTables( null, "%", "t%", types);
            ResultSetMetaData rsMetaData = rs.getMetaData();

            if (rsMetaData.getColumnCount() != expectedNames.length) {
                passed = false;
                output.println("Bad column count.  Should be "
                        + expectedNames.length + ", was "
                        + rsMetaData.getColumnCount());
            }

            for (i=0; passed && i<expectedNames.length; i++) {
                if (! rsMetaData.getColumnName(i+1).equals(expectedNames[i])) {
                    passed = false;
                    output.println("Bad name for column " + (i+1) + ".  "
                                   + "Was " + rsMetaData.getColumnName(i+1)
                                   + ", expected "
                                   + expectedNames[i]);
                }
            }
        } catch (java.sql.SQLException e) {
            passed = false;
            output.println("Exception caught.  " + e.getMessage());
            e.printStackTrace();
        }
        assertTrue(passed);
    }

    public void testxx0052() throws Exception {
        boolean passed = true;

        // ugly, I know
        byte[] image = {
            (byte)0x47, (byte)0x49, (byte)0x46, (byte)0x38,
            (byte)0x39, (byte)0x61, (byte)0x0A, (byte)0x00,
            (byte)0x0A, (byte)0x00, (byte)0x80, (byte)0xFF,
            (byte)0x00, (byte)0xD7, (byte)0x3D, (byte)0x1B,
            (byte)0x00, (byte)0x00, (byte)0x00, (byte)0x2C,
            (byte)0x00, (byte)0x00, (byte)0x00, (byte)0x00,
            (byte)0x0A, (byte)0x00, (byte)0x0A, (byte)0x00,
            (byte)0x00, (byte)0x02, (byte)0x08, (byte)0x84,
            (byte)0x8F, (byte)0xA9, (byte)0xCB, (byte)0xED,
            (byte)0x0F, (byte)0x63, (byte)0x2B, (byte)0x00,
            (byte)0x3B,
        };

        int         i;
        int         count;
        Statement   stmt     = con.createStatement();

        dropTable("#t0052");

        try {
            String sql =
            "create table #t0052 (                                  " +
            " myvarchar                varchar(2000) not null,     " +
            " myvarbinary              varbinary(2000) not null)   ";

            stmt.executeUpdate(sql);

            sql =
            "insert into #t0052               " +
            "  (myvarchar,                   " +
            "   myvarbinary)                 " +
            " values                         " +
            "  (\'This is a test with german umlauts ‰ˆ¸\', " +
            "   0x4749463839610A000A0080FF00D73D1B0000002C000000000A000A00000208848FA9CBED0F632B003B" +
            "  )";
            stmt.executeUpdate(sql);

            sql = "select * from #t0052";
            ResultSet rs = stmt.executeQuery(sql);
            if (!rs.next()) {
                passed = false;
            } else {
                output.println("Testing getAsciiStream()");
                InputStream in = rs.getAsciiStream("myvarchar");
                String expect = "This is a test with german umlauts ???";
                byte[] toRead = new byte[expect.length()];
                count = in.read(toRead);
                if (count == expect.length()) {
                    for (i=0; i<expect.length(); i++) {
                        if (expect.charAt(i) != toRead[i]) {
                            passed = false;
                            output.println("Expected "+expect.charAt(i)
                                           + " but was "
                                           + toRead[i]);
                        }
                    }
                } else {
                    passed = false;
                    output.println("Premature end in "
                                   + "getAsciiStream(\"myvarchar\") "
                                   + count + " instead of "
                                   + expect.length());
                }
                in.close();

                in = rs.getAsciiStream(2);
                toRead = new byte[41];
                count = in.read(toRead);
                if (count == 41) {
                    for (i=0; i<41; i++) {
                        if (toRead[i] != (toRead[i] & 0x7F)) {
                            passed = false;
                            output.println("Non ASCII characters in getAsciiStream");
                            break;
                        }
                    }
                } else {
                    passed = false;
                    output.println("Premature end in getAsciiStream(1) "
                                   +count+" instead of 41");
                }
                in.close();

                output.println("Testing getUnicodeStream()");
                Reader reader = rs.getCharacterStream("myvarchar");
                expect = "This is a test with german umlauts ‰ˆ¸";
                char[] charsToRead = new char[expect.length()];
                count = reader.read(charsToRead, 0, expect.length());
                if (count == expect.length()) {
                    String result = new String(charsToRead);
                    if (!expect.equals(result)) {
                        passed = false;
                        output.println("Expected "+ expect
                                       + " but was " + result);
                    }
                } else {
                    passed = false;
                    output.println("Premature end in "
                                   + "getUnicodeStream(\"myvarchar\") "
                                   + count + " instead of "
                                   + expect.length());
                }
                reader.close();

                /* Cannot think of a meaningfull test */
                reader = rs.getCharacterStream(2);
                reader.close();

                output.println("Testing getBinaryStream()");

                /* Cannot think of a meaningfull test */
                in = rs.getBinaryStream("myvarchar");
                in.close();

                in = rs.getBinaryStream(2);
                count = 0;
                toRead = new byte[image.length];
                do {
                    int actuallyRead = in.read(toRead, count,
                                               image.length-count);
                    if (actuallyRead == -1) {
                        passed = false;
                        output.println("Premature end in "
                                       +" getBinaryStream(2) "
                                       + count +" instead of "
                                       + image.length);
                        break;
                    }
                    count += actuallyRead;
                } while (count < image.length);

                for (i=0; i<count; i++) {
                    if (toRead[i] != image[i]) {
                        passed = false;
                        output.println("Expected "+toRead[i]
                                       + "but was "+image[i]);
                        break;
                    }
                }
                in.close();

                output.println("Testing getCharacterStream()");
                try {
                    reader = (Reader) UnitTestBase.invokeInstanceMethod(
                            rs, "getCharacterStream", new Class[]{String.class}, new Object[]{"myvarchar"});
                    expect = "This is a test with german umlauts ‰ˆ¸";
                    charsToRead = new char[expect.length()];
                    count = reader.read(charsToRead, 0, expect.length());
                    if (count == expect.length()) {
                        String result = new String(charsToRead);
                        if (!expect.equals(result)) {
                            passed = false;
                            output.println("Expected "+ expect
                                           + " but was " + result);
                        }
                    } else {
                        passed = false;
                        output.println("Premature end in "
                                       + "getCharacterStream(\"myvarchar\") "
                                       + count + " instead of "
                                       + expect.length());
                    }
                    reader.close();

                    /* Cannot think of a meaningfull test */
                    reader = (Reader) UnitTestBase.invokeInstanceMethod(
                            rs, "getCharacterStream", new Class[]{Integer.TYPE}, new Object[]{new Integer(2)});
                    reader.close();
                } catch (RuntimeException e) {
                    // FIXME - This will not compile under 1.3...
/*
                    if (e.getCause() instanceof NoSuchMethodException) {
                        output.println("JDBC 2 only");
                    } else {
*/
                        throw e;
//                    }
                } catch (Throwable t) {
                    passed = false;
                    output.println("Exception: "+t.getMessage());
                }
            }
            rs.close();

        } catch (java.sql.SQLException e) {
            passed = false;
            output.println("Exception caught.  " + e.getMessage());
            e.printStackTrace();
        }
        assertTrue(passed);
        stmt.close();
    }

    public void testxx0053() throws Exception {
        boolean passed = true;

        Statement   stmt     = con.createStatement();

        dropTable("#t0053");
        try {
            String sql =
            "create table #t0053 (                                  " +
            " myvarchar                varchar(2000)  not null,    " +
            " mynchar                  nchar(2000)    not null,    " +
            " mynvarchar               nvarchar(2000) not null,    " +
            " myntext                  ntext          not null     " +
            " )   ";

            stmt.executeUpdate(sql);

            sql =
            "insert into #t0053               " +
            "  (myvarchar,                   " +
            "   mynchar,                     " +
            "   mynvarchar,                  " +
            "   myntext)                     " +
            " values                         " +
            "  (\'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\',     " +
            "   \'‰ˆ¸ƒ÷‹\',                  " +
            "   \'‰ˆ¸ƒ÷‹\',                  " +
            "   \'‰ˆ¸ƒ÷‹\'                   " +
            "  )";
            stmt.executeUpdate(sql);

            sql = "select * from #t0053";
            ResultSet rs = stmt.executeQuery(sql);
            if (!rs.next()) {
                passed = false;
            } else {
                System.err.print("Testing varchars > 255 chars: ");
                String test = rs.getString(1);
                if (test.length() == 270) {
                    System.err.println("passed");
                } else {
                    System.err.println("failed");
                    passed = false;
                }

                System.err.print("Testing nchar: ");
                test = rs.getString(2);
                if (test.length() == 2000 && "‰ˆ¸ƒ÷‹".equals(test.trim())) {
                    System.err.println("passed");
                } else {
                    System.err.print("failed, got \'");
                    System.err.print(test.trim());
                    System.err.println("\' instead of \'‰ˆ¸ƒ÷‹\'");
                    passed = false;
                }

                System.err.print("Testing nvarchar: ");
                test = rs.getString(3);
                if (test.length() == 6 && "‰ˆ¸ƒ÷‹".equals(test)) {
                    System.err.println("passed");
                } else {
                    System.err.print("failed, got \'");
                    System.err.print(test);
                    System.err.println("\' instead of \'‰ˆ¸ƒ÷‹\'");
                    passed = false;
                }

                System.err.print("Testing ntext: ");
                test = rs.getString(4);
                if (test.length() == 6 && "‰ˆ¸ƒ÷‹".equals(test)) {
                    System.err.println("passed");
                } else {
                    System.err.print("failed, got \'");
                    System.err.print(test);
                    System.err.println("\' instead of \'‰ˆ¸ƒ÷‹\'");
                    passed = false;
                }
            }
        } catch (java.sql.SQLException e) {
            passed = false;
            output.println("Exception caught.  " + e.getMessage());
            e.printStackTrace();
        }
        assertTrue(passed);
        stmt.close();
    }
    public void testxx005x() throws Exception {
        boolean    passed = true;

        output.println("test getting a DECIMAL as a long from the database.");

        Statement   stmt     = con.createStatement();

        ResultSet  rs;

        rs = stmt.executeQuery("select convert(DECIMAL(4,0), 0)");
        if (!rs.next()) {
            passed = false;
        } else {
            long l = rs.getLong(1);
            if (l != 0) {
                passed = false;
            }
        }

        rs = stmt.executeQuery("select convert(DECIMAL(4,0), 1)");
        if (!rs.next()) {
            passed = false;
        } else {
            long l = rs.getLong(1);
            if (l != 1) {
                passed = false;
            }
        }

        rs = stmt.executeQuery("select convert(DECIMAL(4,0), -1)");
        if (!rs.next()) {
            passed = false;
        } else {
            long l = rs.getLong(1);
            if (l != -1) {
                passed = false;
            }
        }
        assertTrue(passed);
        stmt.close();
    }

    public void testxx0057() throws Exception {
        output.println("test putting a zero length string into a parameter");

        // open the database

        int         count;
        Statement   stmt     = con.createStatement();

        dropTable("#t0057");

        count = stmt.executeUpdate("create table #t0057          "
                                   + " (a varchar(10) not null, "
                                   + "  b char(10)    not null) ");
        stmt.close();
        output.println("Creating table affected " + count + " rows");

        PreparedStatement  pstmt = con.prepareStatement(
                                                       "insert into #t0057 values (?, ?)");
        pstmt.setString(1, "");
        pstmt.setString(2, "");
        count = pstmt.executeUpdate();
        output.println("Added " + count + " rows");
        if (count != 1) {
            pstmt.close();
            output.println("Failed to add rows");
            fail();
        } else {
            pstmt.close();
            pstmt = con.prepareStatement("select a, b from #t0057");

            ResultSet  rs = pstmt.executeQuery();
            if (!rs.next()) {
                output.println("Couldn't read rows from table.");
                fail();
            } else {
                output.println("a is |" + rs.getString("a") + "|");
                output.println("b is |" + rs.getString("b") + "|");
                assertEquals("", rs.getString("a"));
                assertEquals("          ", rs.getString("b"));
            }
            pstmt.close();
        }
    }

    public void testxx0059() throws Exception {
        try {
            DatabaseMetaData  dbMetaData = con.getMetaData( );
            ResultSet         rs         = dbMetaData.getSchemas();
            ResultSetMetaData rsm        = rs.getMetaData();

            boolean JDBC3 = "1.4".compareTo(System.getProperty("java.specification.version")) <= 0;

            assertEquals(JDBC3 ? 2 : 1, rsm.getColumnCount());
            assertTrue(rsm.getColumnName(1).equalsIgnoreCase("TABLE_SCHEM"));
            if (JDBC3) {
                assertTrue(rsm.getColumnName(2).equalsIgnoreCase("TABLE_CATALOG"));
            }

            while (rs.next()) {
                output.println("schema " + rs.getString(1));
            }
        } catch (java.sql.SQLException e) {
            output.println("Exception caught.  " + e.getMessage());
            e.printStackTrace();
            fail();
        }
    }
}

package com.heatonresearch.httprecipes.html;

import java.io.*;

/**
 * The Heaton Research Spider Copyright 2007 by Heaton
 * Research, Inc.
 * 
 * HTTP Programming Recipes for Java ISBN: 0-9773206-6-9
 * http://www.heatonresearch.com/articles/series/16/
 * 
 * PeekableInputStream: This is a special input stream that
 * allows the program to peek one or more characters ahead
 * in the file.
 * 
 * This class is released under the:
 * GNU Lesser General Public License (LGPL)
 * http://www.gnu.org/copyleft/lesser.html
 * 
 * @author Jeff Heaton
 * @version 1.1
 */
public class PeekableInputStream extends InputStream
{

  /**
   * The underlying stream.
   */
  private InputStream stream;

  /**
   * Bytes that have been peeked at.
   */
  private byte peekBytes[];

  /**
   * How many bytes have been peeked at.
   */
  private int peekLength;

  /**
   * The constructor accepts an InputStream to setup the
   * object.
   * 
   * @param is
   *          The InputStream to parse.
   */
  public PeekableInputStream(InputStream is)
  {
    this.stream = is;
    this.peekBytes = new byte[10];
    this.peekLength = 0;
  }

  /**
   * Peek at the next character from the stream.
   * 
   * @return The next character.
   * @throws IOException
   *           If an I/O exception occurs.
   */
  public int peek() throws IOException
  {
    return peek(0);
  }

  /**
   * Peek at a specified depth.
   * 
   * @param depth
   *          The depth to check.
   * @return The character peeked at.
   * @throws IOException
   *           If an I/O exception occurs.
   */
  public int peek(int depth) throws IOException
  {
    // does the size of the peek buffer need to be extended?
    if (this.peekBytes.length <= depth)
    {
      byte temp[] = new byte[depth + 10];
      for (int i = 0; i < this.peekBytes.length; i++)
      {
        temp[i] = this.peekBytes[i];
      }
      this.peekBytes = temp;
    }

    // does more data need to be read?
    if (depth >= this.peekLength)
    {
      int offset = this.peekLength;
      int length = (depth - this.peekLength) + 1;
      int lengthRead = this.stream.read(this.peekBytes, offset, length);

      if (lengthRead == -1)
      {
        return -1;
      }

      this.peekLength = depth + 1;
    }

    return this.peekBytes[depth];
  }

  /*
   * Read a single byte from the stream. @throws IOException
   * If an I/O exception occurs. @return The character that
   * was read from the stream.
   */
  @Override
  public int read() throws IOException
  {
    if (this.peekLength == 0)
    {
      return this.stream.read();
    }

    int result = this.peekBytes[0];
    this.peekLength--;
    for (int i = 0; i < this.peekLength; i++)
    {
      this.peekBytes[i] = this.peekBytes[i + 1];
    }

    return result;
  }

}
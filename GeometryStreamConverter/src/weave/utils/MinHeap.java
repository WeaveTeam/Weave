// copied from http://techpuzzl.wordpress.com/2010/01/24/maxheap-and-minheap-implementations-in-java/

package weave.utils;
import java.util.*;

public class MinHeap<E extends Comparable<E>> {
  List<E> h = new ArrayList<E>();

  public MinHeap() {
  }

  public MinHeap(E[] keys) {
    for (E key : keys) {
      h.add(key);
    }
    for (int k = h.size() / 2 - 1; k >= 0; k--) {
      percolateDown(k, h.get(k));
    }
  }

  public void add(E node) {
    h.add(null);
    int k = h.size() - 1;
    while (k > 0) {
      int parent = (k - 1) / 2;
      E p = h.get(parent);
      if (node.compareTo(p) >= 0) {
        break;
      }
      h.set(k, p);
      k = parent;
    }
    h.set(k, node);
  }

  public E remove() {
    E removedNode = h.get(0);
    E lastNode = h.remove(h.size() - 1);
    percolateDown(0, lastNode);
    return removedNode;
  }

  public E min() {
    return h.get(0);
  }

  public boolean isEmpty() {
    return h.isEmpty();
  }

  void percolateDown(int k, E node) {
    if (h.isEmpty()) {
      return;
    }
    while (k < h.size() / 2) {
      int child = 2 * k + 1;
      if (child < h.size() - 1 && h.get(child).compareTo(h.get(child + 1)) > 0) {
        child++;
      }
      if (node.compareTo(h.get(child)) <= 0) {
        break;
      }
      h.set(k, h.get(child));
      k = child;
    }
    h.set(k, node);
  }

  // Usage example
  public static void main(String[] args) {
    MinHeap<Integer> heap = new MinHeap<Integer>(new Integer[] { 2, 5, 1, 3 });
    // print keys in sorted order
    while (!heap.isEmpty()) {
      System.out.println(heap.remove());
    }
  }
}
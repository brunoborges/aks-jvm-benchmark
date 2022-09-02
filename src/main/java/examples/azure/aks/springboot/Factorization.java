package examples.azure.aks.springboot;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.logging.Logger;

public class Factorization {

    private boolean logging;
    private static final Logger logger = Logger.getLogger(Factorization.class.getName());

    public Factorization() {
        this(false);
    }

    public Factorization(boolean logging) {
        this.logging = logging;
    }

    public Collection<Long> factors(long n) {
        var results = new ArrayList<Long>();

        while (n % 2L == 0) {
            results.add(2L);
            n /= 2L;
        }

        for (int i = 3; i <= Math.sqrt(n); i += 2) {
            while (n % (long) i == 0) {
                results.add((long) i);
                n /= i;
            }
        }

        if (n > 2) {
            results.add(n);
        }

        return Collections.unmodifiableCollection(results);
    }

    public static void main(String[] args) {
        Factorization f = new Factorization();
        long start = System.nanoTime();
        long startMS = System.currentTimeMillis();
        // 2 5 103 3030214670981671
        long n = 3121121111111121130L;
        f.factors(n).forEach(System.out::println);
        System.out.println("");
        System.out.println(System.nanoTime() - start);
        System.out.println(System.currentTimeMillis() - startMS);
    }

}

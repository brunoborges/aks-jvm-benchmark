package examples.azure.aks.springboot;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Factorization {

    private final boolean logging;
    private static final long TWO = 2L;
    private static final Logger logger = LoggerFactory.getLogger(Factorization.class);

    public Factorization() {
        this(false);
    }

    public Factorization(boolean logging) {
        logger.info("Logging enabled? " + logging);

        this.logging = logging;
    }

    public Collection<Long> factors(long n) {
        var results = new ArrayList<Long>((int) Math.min(1, n / 2));

        while (n % 2L == 0) {
            if (logging) {
                logger.info("One factor found: " + n);
            }

            results.add(TWO);
            n /= 2L;
        }

        for (int i = 3; i <= Math.sqrt(n); i += 2) {
            if (logging) {
                logger.info("Testing other factors with sqrt: " + n);
            }

            while (n % (long) i == 0) {
                if (logging) {
                    logger.info("Number 'i' is a factor: " + i);
                }

                results.add((long) i);

                if (logging) {
                    logger.info("Now divide 'n' for 'i': {}/{}", n, i);
                }

                n /= i;
            }
        }

        if (n > 2) {
            if (logging) {
                logger.info("Number 'n' still bigger than 2: " + n);
            }

            results.add(n);
        }

        if (logging) {
            logger.info("Returning factors: " + results);
        }

        return Collections.unmodifiableCollection(results);
    }

}

package examples.azure.aks.springboot;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Factorization {

    private final boolean logging;
    private static final Logger logger = LoggerFactory.getLogger(Factorization.class);

    public Factorization() {
        this(false);
    }

    public Factorization(boolean logging) {
        logger.info("Logging enabled? " + logging);

        this.logging = logging;
    }

    public List<Long> factors(BigInteger n) {
        var results = new ArrayList<Long>(5);

        while (n.mod(BigInteger.valueOf(2)).intValue() == 0) {
            if (logging) {
                logger.info("One factor found: " + n);
            }

            results.add(2L);
            n = n.divide(BigInteger.valueOf(2L));
        }

        for (var i = 3; i <= n.sqrt().longValue(); i += 2) {
            if (logging) {
                logger.info("Testing other factors with sqrt: " + n);
            }
            while (n.mod(BigInteger.valueOf(i)).equals(BigInteger.ZERO)) {
                if (logging) {
                    logger.info("Number 'i' is a factor: " + i);
                }
                results.add((long) i);
                if (logging) {
                    logger.info("Now divide 'n' for 'i': {}/{}", n, i);
                }
                n = n.divide(BigInteger.valueOf(i));
            }
        }
        if (n.compareTo(BigInteger.TWO) > 0) {
            if (logging) {
                logger.info("The last factor is: " + n);
            }
            results.add(n.longValue());
        }
        if (logging) {
            logger.info("Returning factors: " + results);
        }
        return Collections.unmodifiableList(results);
    }

}

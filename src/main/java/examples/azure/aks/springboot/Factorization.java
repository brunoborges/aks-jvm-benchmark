package examples.azure.aks.springboot;

import java.math.BigInteger;
import java.util.List;
import java.util.ArrayList;
import java.util.random.RandomGenerator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Factorization {

    private final boolean logging;
    private static final Logger logger = LoggerFactory.getLogger(Factorization.class);

    public Factorization() {
        this(false);
    }

    public void findNewRandomFactor() {
        var random = RandomGenerator.getDefault();
        var factor = random.nextInt(100);
        logger.info("New random factor: {}", factor);
    }

    public Factorization(boolean logging) {
        logger.info("Logging enabled? {}", logging);
        this.logging = logging;
    }

    public List<Long> factors(BigInteger n) {
        List<Long> factors = new ArrayList<>();
        BigInteger i = BigInteger.TWO;
        BigInteger limit = n.sqrt();

        while (i.compareTo(limit) <= 0) {
            if (n.mod(i).equals(BigInteger.ZERO)) {
                if (logging) {
                    logger.info("Factor found: {}", i);
                }
                factors.add(i.longValue());
                n = n.divide(i);
                limit = n.sqrt();
            } else {
                i = i.add(BigInteger.ONE);
            }
        }

        if (n.compareTo(BigInteger.ONE) > 0) {
            if (logging) {
                logger.info("Adding remaining factor: {}", n);
            }
            factors.add(n.longValue());
        }

        if (logging) {
            logger.info("Found {} factors: {}", factors.size(), factors);
        }

        return List.copyOf(factors);
    }

    private boolean isPrime(BigInteger n) {
        if (n.compareTo(BigInteger.TWO) < 0) {
            return false;
        }
        if (n.equals(BigInteger.TWO) || n.equals(BigInteger.valueOf(3))) {
            return true;
        }
        if (n.mod(BigInteger.TWO).equals(BigInteger.ZERO) || n.mod(BigInteger.valueOf(3)).equals(BigInteger.ZERO)) {
            return false;
        }
        for (BigInteger i = BigInteger.valueOf(5); i.multiply(i).compareTo(n) <= 0; i = i.add(BigInteger.valueOf(6))) {
            if (n.mod(i).equals(BigInteger.ZERO) || n.mod(i.add(BigInteger.TWO)).equals(BigInteger.ZERO)) {
                return false;
            }
        }
        return true;
    }
}

package examples.azure.aks.springboot;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.time.Duration;
import java.time.Instant;
import java.util.stream.Collectors;

import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

import org.junit.jupiter.api.Test;

public class TestFactorization {

    @Test
    public void testFactorization() {
        var input = BigInteger.valueOf(100L);
        var expectedFactorization = "2 * 2 * 5 * 5";

        var controller = new RESTController();
        var map = controller.findFactor(input, true);

        assertFalse(map == null);
        assertEquals(input, map.number());
        assertEquals(expectedFactorization, map.factors());

        testEvaluationOfFactorial(map.number());
    }

    private void testEvaluationOfFactorial(BigInteger number) {
        try {
            var controller = new RESTController();
            var map = controller.findFactor(number, true);

            var mgr = new ScriptEngineManager();
            var engine = mgr.getEngineByName("JavaScript");

            var expression = map.factors();
            var result = (Number) engine.eval(expression);
            assertEquals(map.number().longValue(), result.longValue());
        } catch (ScriptException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        var factorization = new Factorization(true);

        var start = Instant.now();
        var loopCount = 2;
        var n = new BigInteger("2189738129317");
        for (int i = 0; i < loopCount - 1; i++) {
            factorization.factors(n);
        }
        var resultList = factorization.factors(n);
        var stop = Instant.now();

        // Print out
        var result = resultList.stream().map((l) -> l.toString()).collect(Collectors.joining(" * "));
        var duration = Duration.between(start, stop);
        var durationInBD = BigDecimal.valueOf(duration.toMillis()).divide(BigDecimal.valueOf(1000));
        System.out.println("\nResult: " + new PrimeFactor(n, result, durationInBD));
        var secondsPrecise = new BigDecimal(duration.toMillis()).divide(new BigDecimal(1000));
        System.out.println("Duration: " + duration.toMillis() + " ms // " + secondsPrecise + " s");
    }

}

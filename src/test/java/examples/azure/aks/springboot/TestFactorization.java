package examples.azure.aks.springboot;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

import org.junit.jupiter.api.Test;

public class TestFactorization {

    @Test
    public void testFactorization() {
        var input = 100L;
        var expectedFactorization = "2 * 2 * 5 * 5";

        var controller = new Controller();
        var map = controller.findFactor(input, true);

        assertFalse(map == null);
        assertEquals(input, map.number());
        assertEquals(expectedFactorization, map.factors());

        testEvaluationOfFactorial(map.number());
    }

    @Test
    public void testRandomNumbers() {
        for (int i = 0; i < 5; i++) {
            var input = (long) (Math.random() * 1000000);
            testEvaluationOfFactorial(input);
        }
    }

    private void testEvaluationOfFactorial(Long number) {
        try {
            var controller = new Controller();
            var map = controller.findFactor(number, true);

            var mgr = new ScriptEngineManager();
            var engine = mgr.getEngineByName("JavaScript");

            var expression = map.factors();
            var result = (Number) engine.eval(expression);
            assertEquals(Long.valueOf(map.number()), result.longValue());
        } catch (ScriptException e) {
            e.printStackTrace();
        }
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

package examples.azure.aks.springboot;

import static java.lang.Runtime.getRuntime;

import java.lang.management.ManagementFactory;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RESTController {

    @GetMapping("/")
    public String helloWorld() {
        return "Hello World";
    }

    @GetMapping("/primeFactor")
    public PrimeFactor findFactor(BigInteger number, Boolean logging) {
        if (number == null) {
            number = BigInteger.valueOf(100L);
        }
        var factorization = new Factorization(Boolean.TRUE.equals(logging));
        var start = Instant.now();
        var factors = factorization.factors(number).stream().map(n -> n.toString()).collect(Collectors.joining(" * "));
        var stop = Instant.now();
        var duration = Duration.between(start, stop);
        var durationInBD = BigDecimal.valueOf(duration.toMillis()).divide(BigDecimal.valueOf(1000));
        return new PrimeFactor(number, factors, durationInBD);
    }

    @GetMapping("/waitWithPrimeFactor")
    public String networkWaitWithPrime(Integer duration, BigInteger number) {
        var primeFactor = findFactor(number, false);
        StringBuilder sb = new StringBuilder();
        sb.append(networkWait(duration));
        sb.append("\n");
        sb.append("Found factors for " + number + ": " + primeFactor);
        return sb.toString();
    }

    @GetMapping("/wait")
    public String networkWait(Integer duration) {
        var random = ThreadLocalRandom.current();
        var randomWait = random.nextInt(2, 50);
        var totalWait = duration + randomWait;
        try {
            Thread.sleep(duration + randomWait);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return "Waited " + totalWait + "ms (random wait: " + randomWait + "ms)";
    }

    @GetMapping("/inspect")
    public Map<String, String> inspect() throws ClassNotFoundException {
        var map = new TreeMap<String, String>();
        var runtime = getRuntime();

        // Current GC
        var gcIdentifier = new IdentifyCurrentGC();
        map.put("Running GC", gcIdentifier.identifyGC().name());

        var podIP = System.getenv("MY_POD_IP");
        map.put("podIP", podIP);

        // CPUs and Memory

        map.put("availableProcessors", Integer.toString(runtime.availableProcessors()));
        map.put("maxMemory (MB)", Long.toString(runtime.maxMemory() / 1024 / 1024));
        map.put("totalMemory (MB)", Long.toString(runtime.totalMemory() / 1024 / 1024));

        // Garbage Collector
        var gcMxBeans = ManagementFactory.getGarbageCollectorMXBeans();
        for (var gcBean : gcMxBeans) {
            map.put("GC [" + gcBean.getName() + "]", gcBean.getObjectName().toString());
        }

        // OperatingSystem MX Bean
        var osBean = (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
        map.put("osMXBean.getCommittedVirtualMemorySize", bytesToMBString(osBean.getCommittedVirtualMemorySize()));
        map.put("osMXBean.getTotalMemorySize", bytesToMBString(osBean.getTotalMemorySize()));
        map.put("osMXBean.getFreeMemorySize", bytesToMBString(osBean.getFreeMemorySize()));
        map.put("osMXBean.getTotalSwapSpaceSize", bytesToMBString(osBean.getTotalSwapSpaceSize()));
        map.put("osMXBean.getFreeSwapSpaceSize", bytesToMBString(osBean.getFreeSwapSpaceSize()));
        map.put("osMXBean.getCpuLoad", Double.toString(osBean.getCpuLoad() * 100.0));
        map.put("osMXBean.getProcessCpuLoad", Double.toString(osBean.getProcessCpuLoad()));
        map.put("osMXBean.getSystemLoadAverage", Double.toString(osBean.getSystemLoadAverage()));
        map.put("osMXBean.getProcessCpuTime", Double.toString(osBean.getProcessCpuTime()));
        map.put("osMXBean.getAvailableProcessors", Integer.toString(osBean.getAvailableProcessors()));

        map.put("cpu_shares", System.getProperty("cpushares"));

        // current user
        map.put("user.name", System.getProperty("user.name"));

        return map;
    }

    private String bytesToMBString(long bytes) {
        return Long.toString(bytes / 1024 / 1024) + " MB";
    }

    @GetMapping("/json")
    @ResponseBody
    Map<String, String> json() {
        return Map.of("message", "Hello, World!", "randomNumber", Integer.toString(randomNumber()));
    }

    private static int randomNumber() {
        return ThreadLocalRandom.current().nextInt(0, Integer.MAX_VALUE);
    }

    @GetMapping("/generateRandomNumbers")
    @ResponseBody
    List<Integer> generateRandomNumbers(int amount, int bound) {
        var random = ThreadLocalRandom.current();
        var numbers = new ArrayList<Integer>(amount);
        for (int i = 0; i < amount; i++) {
            numbers.add(random.nextInt(bound));
        }
        return numbers;
    }
}

package examples.azure.aks.springboot;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.ResponseBody;

import static java.lang.Runtime.getRuntime;
import java.lang.management.ManagementFactory;

@RestController
public class Controller {

    @RequestMapping("/")
    public String helloWorld() {
        return "Hello World";
    }

    @RequestMapping("/primeFactor")
    public Map<Long, String> findFactor(Long number, Boolean logging) {
        var factorization = new Factorization(Boolean.TRUE.equals(logging));
        var factors = factorization.factors(number).stream().map(n -> n.toString()).toList();
        var map = new HashMap<Long, String>();
        map.put(number, String.join(" ", factors));
        return map;
    }

    @RequestMapping("/inspect")
    public Map<String, String> inspect() {
        var runtime = getRuntime();
        var map = new HashMap<String, String>();

        // CPUs and Memory
        map.put("availableProcessors", Integer.toString(runtime.availableProcessors()));
        map.put("maxMemory (MB)", Long.toString(runtime.maxMemory() / 1024 / 1024));
        map.put("totalMemory (MB)", Long.toString(runtime.totalMemory() / 1024 / 1024));

        // Garbage Collector
        var gcMxBeans = ManagementFactory.getGarbageCollectorMXBeans();
        for (var gcBean : gcMxBeans) {
            map.put(gcBean.getName(), gcBean.getObjectName().toString());
        }

        // OperatingSystem MX Bean
        var osBean = (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
        map.put("osMXBean.getCommittedVirtualMemorySize", bytesToMBString(osBean.getCommittedVirtualMemorySize()));
        map.put("osMXBean.getTotalPhysicalMemorySize", bytesToMBString(osBean.getTotalPhysicalMemorySize()));
        map.put("osMXBean.getFreePhysicalMemorySize", bytesToMBString(osBean.getFreePhysicalMemorySize()));
        map.put("osMXBean.getTotalSwapSpaceSize", bytesToMBString(osBean.getTotalSwapSpaceSize()));
        map.put("osMXBean.getFreeSwapSpaceSize", bytesToMBString(osBean.getFreeSwapSpaceSize()));
        map.put("osMXBean.getSystemCpuLoad", Double.toString(osBean.getSystemCpuLoad()));
        map.put("osMXBean.getProcessCpuLoad", Double.toString(osBean.getProcessCpuLoad()));
        map.put("osMXBean.getSystemLoadAverage", Double.toString(osBean.getSystemLoadAverage()));
        map.put("osMXBean.getProcessCpuTime", Double.toString(osBean.getProcessCpuTime()));
        map.put("osMXBean.getAvailableProcessors", Integer.toString(osBean.getAvailableProcessors()));

        map.put("cpu_shares", System.getProperty("cpushares"));

        return map;
    }

    private String bytesToMBString(long bytes) {
        return Long.toString(bytes / 1024 / 1024) + " MB";
    }

    @RequestMapping("/json")
    @ResponseBody
    Map<String, String> json() {
        return Map.of("message", "Hello, World!", "randomNumber", Integer.toString(randomNumber()));
    }

    private static int randomNumber() {
        return ThreadLocalRandom.current().nextInt(0, Integer.MAX_VALUE);
    }
}

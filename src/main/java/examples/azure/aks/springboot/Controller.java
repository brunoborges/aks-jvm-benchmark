package examples.azure.aks.springboot;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.ResponseBody;

import jdk.internal.platform.Metrics;

import static java.lang.Runtime.getRuntime;

import java.lang.management.ManagementFactory;

@RestController
public class Controller {

    @RequestMapping("/")
    public String helloWorld() {
        return "Hello World";
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

        // Metrics
        // var metrics = Metrics.systemMetrics();

        return map;
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

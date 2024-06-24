package examples.azure.aks.springboot;

import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.management.ManagementFactory;
import java.util.Arrays;
import java.util.TreeMap;

public class IdentifyCurrentGC {

    public static enum GCType {
        G1GC, ConcMarkSweepGC, ParallelGC, SerialGC, ShenandoahGC, ZGC, Unknown;
    }

    private static final String HOTSPOT_BEAN_NAME = "com.sun.management:type=HotSpotDiagnostic";

    private static Object getHotspotMBean() {
        try {
            var clazz = Class.forName("com.sun.management.HotSpotDiagnosticMXBean");
            var server = ManagementFactory.getPlatformMBeanServer();
            return ManagementFactory.newPlatformMXBeanProxy(server, HOTSPOT_BEAN_NAME, clazz);
        } catch (RuntimeException re) {
            throw re;
        } catch (Exception exp) {
            throw new RuntimeException(exp);
        }
    }

    private final Class<?> VMOptionClazz, HotSpotDiagnosticMXBeanClazz;

    public IdentifyCurrentGC() throws ClassNotFoundException {
        VMOptionClazz = Class.forName("com.sun.management.VMOption");
        HotSpotDiagnosticMXBeanClazz = Class.forName("com.sun.management.HotSpotDiagnosticMXBean");
    }

    public GCType identifyGC() {
        try {
            var flags = Arrays.asList(GCType.values());
            var flagSettings = new TreeMap<GCType, String>();
            for (var flag : flags) {
                var vmOption = getVMOption("Use" + flag.name());
                if (vmOption != null) {
                    flagSettings.put(flag, vmOption);
                }
            }
            return flagSettings.entrySet().stream()
                    .filter(e -> "true".equals(e.getValue()))
                    .map(e -> e.getKey())
                    .findFirst()
                    .orElse(GCType.Unknown);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private String getVMOption(String vmOptionName) {
        // initialize hotspot diagnostic MBean
        initHotspotMBean();
        try {
            var publicLookup = MethodHandles.publicLookup();
            var mt = MethodType.methodType(VMOptionClazz, String.class);
            var getVMOption = publicLookup.findVirtual(HotSpotDiagnosticMXBeanClazz, "getVMOption", mt);
            var vmOption = getVMOption.invokeWithArguments(hotspotMBean, vmOptionName);

            var mt2 = MethodType.methodType(String.class);
            var mh2 = publicLookup.findVirtual(VMOptionClazz, "getValue", mt2);
            return (String) mh2.invokeWithArguments(vmOption);
        } catch (IllegalArgumentException e) {
            if (e.getMessage().contains("does not exist")) {
                return null;
            }
            throw e;
        } catch (Throwable e) {
            throw new RuntimeException(e);
        }
    }

    private volatile Object hotspotMBean;

    private void initHotspotMBean() {
        if (hotspotMBean == null) {
            synchronized (IdentifyCurrentGC.class) {
                if (hotspotMBean == null) {
                    hotspotMBean = getHotspotMBean();
                }
            }
        }
    }

    // main
    public static void main(String[] args) throws ClassNotFoundException {
        IdentifyCurrentGC identifyCurrentGC = new IdentifyCurrentGC();
        GCType gcType = identifyCurrentGC.identifyGC();
        System.out.println("Current GC Type: " + gcType);
    }

}

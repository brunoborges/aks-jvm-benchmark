package examples.azure.aks.springboot;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import org.junit.jupiter.api.Test;

public class TestIdentifyCurrentGC {

    @Test
    public void testIdentifyCurrentGC() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        System.out.printf("Identified GC: %s\n", gc);
        assertNotEquals(IdentifyCurrentGC.GCType.Unknown, gc);
    }

    // @Test
    public void testSerialGC() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        assertEquals(IdentifyCurrentGC.GCType.SerialGC, gc);
    }

    // @Test
    public void testParallelGC() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        assertEquals(IdentifyCurrentGC.GCType.ParallelGC, gc);
    }

    // @Test
    public void testG1GC() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        assertEquals(IdentifyCurrentGC.GCType.G1GC, gc);
    }

    // @Test
    public void testShenandoahGC() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        assertEquals(IdentifyCurrentGC.GCType.ShenandoahGC, gc);
    }

    // @Test
    public void testZGC() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        assertEquals(IdentifyCurrentGC.GCType.ZGC, gc);
    }

    // @Test
    public void testUnknown() throws ClassNotFoundException {
        var gcIdentifier = new IdentifyCurrentGC();
        var gc = gcIdentifier.identifyGC();
        assertEquals(IdentifyCurrentGC.GCType.Unknown, gc);
    }

}

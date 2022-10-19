package examples.azure.aks.springboot;

public class AvailableProcessors {
    // method main showing available processors
    public static void main(String[] args) {
        // available processors
        System.out.println("Available processors: " + Runtime.getRuntime().availableProcessors());
    }
}

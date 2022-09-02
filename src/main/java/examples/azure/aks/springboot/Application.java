package examples.azure.aks.springboot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

import com.microsoft.applicationinsights.attach.ApplicationInsights;

@SpringBootApplication
public class Application extends SpringBootServletInitializer {

    static {
        try {
            ApplicationInsights.attach();
        } catch (Exception e) {
            System.err.println("Failed to attach Application Insights");
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}

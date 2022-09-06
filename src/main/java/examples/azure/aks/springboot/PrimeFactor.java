package examples.azure.aks.springboot;

import java.math.BigDecimal;
import java.math.BigInteger;

public record PrimeFactor(BigInteger number, String factors, BigDecimal timeInSeconds) {}

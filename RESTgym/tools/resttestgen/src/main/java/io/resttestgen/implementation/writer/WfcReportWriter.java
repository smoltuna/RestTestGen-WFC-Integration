package io.resttestgen.implementation.writer;

import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import io.resttestgen.core.Environment;
import io.resttestgen.core.openapi.Operation;
import io.resttestgen.core.testing.Oracle;
import io.resttestgen.core.testing.TestInteraction;
import io.resttestgen.core.testing.TestResult;
import io.resttestgen.core.testing.TestSequence;
import io.resttestgen.core.testing.WfcFaultCategory;
import io.resttestgen.core.testing.Writer;
import io.resttestgen.core.testing.coverage.Coverage;
import io.resttestgen.core.testing.coverage.CoverageManager;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Writer that generates reports conforming to the WFC (Web Fuzzing Commons) Report schema.
 * Extends the abstract Writer class for consistency with other RTG writers.
 * 
 * The WFC Report schema is defined at:
 * https://github.com/WebFuzzing/Commons/blob/master/src/main/resources/wfc/schemas/report.yaml
 */
public class WfcReportWriter extends Writer {

    private static final Logger logger = LogManager.getLogger(WfcReportWriter.class);
    
    // Schema version for WFC Report format
    private static final String SCHEMA_VERSION = "0.1.0";
    private static final String TOOL_NAME = "RestTestGen";
    private static final String TOOL_VERSION = "25.12";
    
    private final CoverageManager coverageManager;
    private final long executionTimeInSeconds;
    private final List<TestSequence> testSequences;

    /**
     * Creates a new WfcReportWriter.
     *
     * @param testSequence The aggregated test sequence containing all test interactions
     * @param coverageManager The coverage manager containing all coverage data
     * @param executionTimeInSeconds The total execution time in seconds
     * @param testSequences The list of individual test sequences with oracle results
     */
    public WfcReportWriter(TestSequence testSequence, CoverageManager coverageManager, 
                           long executionTimeInSeconds, List<TestSequence> testSequences) {
        super(testSequence);
        this.coverageManager = Objects.requireNonNull(coverageManager, "CoverageManager cannot be null");
        this.executionTimeInSeconds = executionTimeInSeconds;
        this.testSequences = testSequences != null ? testSequences : new ArrayList<>();
    }

    @Override
    public String getOutputFormatName() {
        return "wfc-report";
    }

    /**
     * Override getOutputPath to put the WFC report at the session level (not per-generator).
     */
    @Override
    public String getOutputPath() {
        return configuration.getOutputPath() + configuration.getTestingSessionName() + "/" + getOutputFormatName() + "/";
    }

    @Override
    public void write() throws IOException {
        File outputDir = new File(getOutputPath());
        if (!outputDir.exists()) {
            outputDir.mkdirs();
        }

        JsonObject report = buildReport();
        
        String outputFile = getOutputPath() + "wfc-report.json";
        try (FileWriter writer = new FileWriter(outputFile)) {
            new GsonBuilder().setPrettyPrinting().create().toJson(report, writer);
        }
        
        logger.info("WFC Report written to: {}", outputFile);
    }

    /**
     * Builds the complete WFC report as a JsonObject.
     * @return The complete report conforming to WFC schema
     */
    private JsonObject buildReport() {
        JsonObject report = new JsonObject();
        
        // Required fields
        report.addProperty("schemaVersion", SCHEMA_VERSION);
        report.addProperty("toolName", TOOL_NAME);
        report.addProperty("toolVersion", TOOL_VERSION);
        report.addProperty("creationTime", OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME));
        
        // Faults section
        report.add("faults", buildFaultsSection());
        
        // Problem details for REST
        report.add("problemDetails", buildProblemDetails());
        
        // Total tests (number of test interactions in the sequence)
        report.addProperty("totalTests", testSequence.size());
        
        // Test file paths
        report.add("testFilePaths", buildTestFilePaths());
        
        // Test cases
        report.add("testCases", buildTestCases());
        
        // Execution time
        report.addProperty("executionTimeInSeconds", executionTimeInSeconds);
        
        // Extra coverage information
        report.add("extra", buildExtraCoverage());
        
        return report;
    }

    /**
     * Builds the faults section of the report.
     * Detects faults from oracle results that have WFC fault categories assigned.
     * Falls back to detecting 5xx responses for backwards compatibility.
     */
    private JsonObject buildFaultsSection() {
        JsonObject faults = new JsonObject();
        JsonArray foundFaults = new JsonArray();
        Set<String> processedFaults = new HashSet<>(); // To avoid duplicate faults
        
        // First, collect faults from oracle results (which have proper WFC fault categories)
        for (TestSequence seq : testSequences) {
            Map<Oracle, TestResult> testResults = seq.getTestResults();
            for (Map.Entry<Oracle, TestResult> entry : testResults.entrySet()) {
                TestResult result = entry.getValue();
                if (result.isFail() && result.getFaultCategory() != null) {
                    WfcFaultCategory faultCategory = result.getFaultCategory();
                    
                    // Get the relevant operation from the sequence
                    String operationId = getOperationIdFromSequence(seq);
                    String testCaseId = seq.getName() + "-" + seq.getId();
                    String faultKey = operationId + "|" + testCaseId + "|" + faultCategory.getCode();
                    
                    if (!processedFaults.contains(faultKey)) {
                        JsonObject fault = buildFaultObject(operationId, testCaseId, faultCategory, result.getMessage());
                        foundFaults.add(fault);
                        processedFaults.add(faultKey);
                    }
                }
            }
        }
        
        // Fallback: Also detect 5xx responses from aggregated test sequence (for faults not caught by oracles)
        for (TestInteraction interaction : testSequence) {
            if (interaction.getResponseStatusCode() != null && 
                interaction.getResponseStatusCode().getCode() >= 500) {
                
                String operationId = formatOperationId(interaction.getFuzzedOperation());
                String testCaseId = testSequence.getName() + "-" + testSequence.getId();
                String faultKey = operationId + "|" + testCaseId + "|" + WfcFaultCategory.HTTP_STATUS_500.getCode();
                
                if (!processedFaults.contains(faultKey)) {
                    JsonObject fault = buildFaultObject(
                            operationId, 
                            testCaseId, 
                            WfcFaultCategory.HTTP_STATUS_500,
                            "HTTP " + interaction.getResponseStatusCode().getCode()
                    );
                    foundFaults.add(fault);
                    processedFaults.add(faultKey);
                }
            }
        }
        
        faults.addProperty("totalNumber", foundFaults.size());
        faults.add("foundFaults", foundFaults);
        
        return faults;
    }

    /**
     * Builds a fault JSON object with the given parameters.
     */
    private JsonObject buildFaultObject(String operationId, String testCaseId, 
                                         WfcFaultCategory faultCategory, String context) {
        JsonObject fault = new JsonObject();
        fault.addProperty("operationId", operationId);
        fault.addProperty("testCaseId", testCaseId);
        
        JsonArray categories = new JsonArray();
        JsonObject category = new JsonObject();
        category.addProperty("code", faultCategory.getCode());
        category.addProperty("context", context != null ? context : faultCategory.getDescriptiveName());
        categories.add(category);
        
        fault.add("faultCategories", categories);
        return fault;
    }

    /**
     * Gets the operation ID from the last interaction in a test sequence.
     */
    private String getOperationIdFromSequence(TestSequence seq) {
        if (seq.isEmpty()) {
            return "UNKNOWN:/unknown";
        }
        TestInteraction lastInteraction = seq.getLast();
        return formatOperationId(lastInteraction.getFuzzedOperation());
    }

    /**
     * Builds the problem details section with REST-specific information.
     */
    private JsonObject buildProblemDetails() {
        JsonObject problemDetails = new JsonObject();
        JsonObject restReport = new JsonObject();
        
        // Count HTTP calls from the test sequence
        int httpCalls = testSequence.size();
        
        restReport.addProperty("outputHttpCalls", httpCalls);
        restReport.addProperty("evaluatedHttpCalls", httpCalls);
        
        // Endpoint IDs from OpenAPI spec
        JsonArray endpointIds = new JsonArray();
        for (Operation op : Environment.getInstance().getOpenAPI().getOperations()) {
            endpointIds.add(formatOperationId(op));
        }
        restReport.add("endpointIds", endpointIds);
        
        // Covered HTTP status codes
        restReport.add("coveredHttpStatus", buildCoveredHttpStatus());
        
        problemDetails.add("rest", restReport);
        return problemDetails;
    }

    /**
     * Builds the covered HTTP status section from the test sequence.
     */
    private JsonArray buildCoveredHttpStatus() {
        JsonArray coveredEndpoints = new JsonArray();
        Map<String, Set<Integer>> endpointStatusCodes = new HashMap<>();
        
        // Collect status codes per endpoint from the test sequence
        for (TestInteraction interaction : testSequence) {
            String endpointId = formatOperationId(interaction.getFuzzedOperation());
            
            endpointStatusCodes.computeIfAbsent(endpointId, k -> new HashSet<>());
            if (interaction.getResponseStatusCode() != null) {
                endpointStatusCodes.get(endpointId).add(interaction.getResponseStatusCode().getCode());
            }
        }
        
        // Build JSON array
        for (Map.Entry<String, Set<Integer>> entry : endpointStatusCodes.entrySet()) {
            JsonObject coveredEndpoint = new JsonObject();
            coveredEndpoint.addProperty("endpointId", entry.getKey());
            coveredEndpoint.addProperty("testCaseId", testSequence.getName() + "-" + testSequence.getId());
            
            JsonArray statusCodes = new JsonArray();
            for (Integer code : entry.getValue()) {
                statusCodes.add(code);
            }
            coveredEndpoint.add("httpStatus", statusCodes);
            
            coveredEndpoints.add(coveredEndpoint);
        }
        
        return coveredEndpoints;
    }

    /**
     * Builds the test file paths array.
     */
    private JsonArray buildTestFilePaths() {
        JsonArray filePaths = new JsonArray();
        String fileName = testSequence.getName().replaceAll("[^a-zA-Z0-9\\.\\-]", "_") + "-" + testSequence.getId() + ".json";
        filePaths.add("../json-reports/" + toKebabCase(testSequence.getGenerator()) + "/" + fileName);
        return filePaths;
    }

    /**
     * Builds the test cases section.
     */
    private JsonArray buildTestCases() {
        JsonArray testCases = new JsonArray();
        
        JsonObject testCase = new JsonObject();
        testCase.addProperty("id", testSequence.getName() + "-" + testSequence.getId());
        String fileName = testSequence.getName().replaceAll("[^a-zA-Z0-9\\.\\-]", "_") + "-" + testSequence.getId() + ".json";
        testCase.addProperty("filePath", "../json-reports/" + toKebabCase(testSequence.getGenerator()) + "/" + fileName);
        testCase.addProperty("name", testSequence.getName());
        testCase.addProperty("startLine", 0);
        testCase.addProperty("endLine", 0);
        
        testCases.add(testCase);
        
        return testCases;
    }

    /**
     * Builds the extra coverage information from various coverage metrics.
     */
    private JsonArray buildExtraCoverage() {
        JsonArray extraCoverage = new JsonArray();
        
        JsonObject rtgCoverage = new JsonObject();
        rtgCoverage.addProperty("toolName", "RestTestGen");
        
        JsonArray criteria = new JsonArray();
        
        for (Coverage coverage : coverageManager.getCoverageMetrics()) {
            JsonObject criterion = new JsonObject();
            criterion.addProperty("name", coverage.getClass().getSimpleName());
            criterion.addProperty("covered", coverage.getNumOfTestedDocumented());
            criterion.addProperty("total", coverage.getToTest());
            criteria.add(criterion);
        }
        
        rtgCoverage.add("criteria", criteria);
        extraCoverage.add(rtgCoverage);
        
        return extraCoverage;
    }

    /**
     * Formats an operation to a WFC-compliant operation ID.
     * Format: HTTP_METHOD:/path/to/resource
     */
    private String formatOperationId(Operation operation) {
        if (operation == null) {
            return "UNKNOWN:/unknown";
        }
        return operation.getMethod().toString() + ":" + operation.getEndpoint();
    }
}

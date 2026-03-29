package io.resttestgen.implementation.strategy;

import io.resttestgen.core.Environment;
import io.resttestgen.core.openapi.Operation;
import io.resttestgen.core.testing.Strategy;
import io.resttestgen.core.testing.StrategyConfiguration;
import io.resttestgen.core.testing.TestRunner;
import io.resttestgen.core.testing.TestSequence;
import io.resttestgen.core.testing.operationsorter.OperationsSorter;
import io.resttestgen.implementation.fuzzer.ErrorFuzzer;
import io.resttestgen.implementation.fuzzer.NominalFuzzer;
import io.resttestgen.implementation.operationssorter.GraphBasedOperationsSorter;
import io.resttestgen.implementation.oracle.StatusCodeOracle;
import io.resttestgen.implementation.strategy.configuration.NominalAndErrorStrategyConfiguration;
import io.resttestgen.implementation.writer.CoverageReportWriter;
import io.resttestgen.implementation.writer.HtmlReportWriter;
import io.resttestgen.implementation.writer.ReportWriter;
import io.resttestgen.implementation.writer.RestAssuredWriter;
import io.resttestgen.implementation.writer.WfcReportWriter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@SuppressWarnings("unused")
public class NominalAndErrorStrategy extends Strategy {

    private static final Logger logger = LogManager.getLogger(NominalAndErrorStrategy.class);
    private final NominalAndErrorStrategyConfiguration config = StrategyConfiguration.loadConfiguration(NominalAndErrorStrategyConfiguration.class);
    private static final int ERROR_TEST_COUNT = 10;
    private final TestSequence globalNominalTestSequence = new TestSequence();

    public void start() {
        long startTime = System.currentTimeMillis();
        
        HtmlReportWriter htmlReportWriter = initializeHtmlReportWriter();
        List<TestSequence> testSequencesToReport = new ArrayList<>();

        executeNominalFuzzer(testSequencesToReport);
        // Keep only successful test interactions in the sequence
        globalNominalTestSequence.filterBySuccessfulStatusCode();

        //GraphTestCase.generateGraph(globalNominalTestSequence);

        executeErrorFuzzer(testSequencesToReport);
        writeCoverageReport(htmlReportWriter);
        
        htmlReportWriter.populateCoverageCollection(TestRunner.getInstance().getCoverage());
        injectTestSequenceData(htmlReportWriter, testSequencesToReport);
        
        // Write WFC Report using the abstract Writer class
        // Pass all test sequences for proper Oracle result -> WFC fault mapping
        long executionTimeInSeconds = (System.currentTimeMillis() - startTime) / 1000;
        writeWfcReport(executionTimeInSeconds, testSequencesToReport);
    }

    private HtmlReportWriter initializeHtmlReportWriter() {
        HtmlReportWriter htmlReportWriter = new HtmlReportWriter(Environment.getInstance().getConfiguration());
        try {
            htmlReportWriter.createReportResourcesFiles();
        } catch (IOException e) {
            logger.warn("Could not copy folders from template-resources", e);
        }
        return htmlReportWriter;
    }

    private void executeNominalFuzzer(List<TestSequence> testSequencesToReport) {
        // According to the order provided by the graph, execute the nominal fuzzer
        OperationsSorter sorter = new GraphBasedOperationsSorter();
        while (!sorter.isEmpty()) {
            Operation operationToTest = sorter.getFirst();
            logger.debug("Testing operation {}", operationToTest);
            NominalFuzzer nominalFuzzer = new NominalFuzzer(operationToTest);
            List<TestSequence> nominalSequences = nominalFuzzer.generateTestSequences(config.getNumberOfSequences());

            for (TestSequence testSequence : nominalSequences) {
                runAndEvaluateTestSequence(testSequence);
                writeTestSequenceReport(testSequence);
                testSequencesToReport.add(testSequence);
            }
            globalNominalTestSequence.append(nominalSequences);
            sorter.removeFirst();
        }
    }

    private void runAndEvaluateTestSequence(TestSequence testSequence) {
        TestRunner testRunner = TestRunner.getInstance();
        testRunner.run(testSequence);

        StatusCodeOracle statusCodeOracle = new StatusCodeOracle();
        statusCodeOracle.assertTestSequence(testSequence);
    }

    private void writeTestSequenceReport(TestSequence testSequence) {
        try {
            ReportWriter reportWriter = new ReportWriter(testSequence);
            reportWriter.write();
            RestAssuredWriter restAssuredWriter = new RestAssuredWriter(testSequence);
            restAssuredWriter.write();
        } catch (IOException e) {
            logger.warn("Could not write test sequence report to file.", e);
        }
    }

    private void executeErrorFuzzer(List<TestSequence> testSequencesToReport) {
        ErrorFuzzer errorFuzzer = new ErrorFuzzer(globalNominalTestSequence);
        List<TestSequence> errorFuzzerTestSequences = errorFuzzer.generateTestSequences(ERROR_TEST_COUNT);
        testSequencesToReport.addAll(errorFuzzerTestSequences);
    }

    private void writeCoverageReport(HtmlReportWriter htmlReportWriter) {
        try {
            CoverageReportWriter coverageReportWriter = new CoverageReportWriter(TestRunner.getInstance().getCoverage());
            coverageReportWriter.write();
        } catch (IOException e) {
            logger.warn("Could not write test coverage report to file.", e);
        }
    }

    /**
     * Writes the WFC (Web Fuzzing Commons) report.
     * This report follows the standardized WFC schema and can be consumed by the WFC Web Report application.
     * Uses the abstract Writer class for consistency with other RTG writers.
     * 
     * Fault mappings:
     * - StatusCodeOracle (FAIL on 5xx) → F100: HTTP Status 500
     * - ErrorStatusCodeOracle (FAIL on 2xx for invalid input) → F102: Received Success Response When Sending Wrong Data
     * - ErrorStatusCodeOracle (FAIL on 5xx) → F100: HTTP Status 500
     * 
     * @param executionTimeInSeconds The total execution time in seconds
     * @param testSequences All test sequences with their Oracle results for proper fault detection
     */
    private void writeWfcReport(long executionTimeInSeconds, List<TestSequence> testSequences) {
        try {
            // Use constructor that accepts all test sequences for Oracle result -> WFC fault mapping
            WfcReportWriter wfcReportWriter = new WfcReportWriter(
                    TestRunner.globalTestSequenceForDebug,
                    TestRunner.getInstance().getCoverage(),
                    executionTimeInSeconds,
                    testSequences
            );
            wfcReportWriter.write();
            logger.info("WFC Report generated successfully.");
        } catch (IOException e) {
            logger.warn("Could not write WFC report to file.", e);
        }
    }

    private void injectTestSequenceData(HtmlReportWriter htmlReportWriter, List<TestSequence> testSequencesToReport) {
        logger.debug("Injecting test sequences into JS constants file.");
        try {
            htmlReportWriter.injectTestSequenceData(testSequencesToReport);
        } catch (IOException e) {
            logger.warn("Could not write test sequence data to JavaScript constants file.", e);
        }
        logger.debug("Done injecting test sequences into JS constants file.");
    }
}

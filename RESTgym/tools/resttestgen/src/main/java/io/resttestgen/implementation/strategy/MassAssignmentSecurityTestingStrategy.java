package io.resttestgen.implementation.strategy;

import io.resttestgen.core.Environment;
import io.resttestgen.core.helper.CrudGroup;
import io.resttestgen.core.helper.CrudInferredVsGroundTruthComparator;
import io.resttestgen.core.helper.CrudManager;
import io.resttestgen.core.helper.CrudInformationExtractor;
import io.resttestgen.core.testing.Strategy;
import io.resttestgen.core.testing.TestRunner;
import io.resttestgen.core.testing.TestSequence;
import io.resttestgen.implementation.fuzzer.MassAssignmentFuzzer;
import io.resttestgen.implementation.oracle.MassAssignmentOracle;
import io.resttestgen.implementation.writer.ReportWriter;
import io.resttestgen.implementation.writer.WfcReportWriter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@SuppressWarnings("unused")
public class MassAssignmentSecurityTestingStrategy extends Strategy {

    private static final Logger logger = LogManager.getLogger(MassAssignmentSecurityTestingStrategy.class);

    Environment environment = Environment.getInstance();

    @Override
    public void start() {
        long startTime = System.currentTimeMillis();
        
        // List to collect all test sequences for WFC report generation
        List<TestSequence> allTestSequences = new ArrayList<>();

        // Extract/infer resource types handled by operations
        CrudInformationExtractor crudInformationExtractor = new CrudInformationExtractor();
        crudInformationExtractor.extract();

        CrudInferredVsGroundTruthComparator.compare();

        // Instantiate CRUD manager to get groups/batches of CRUD operations
        CrudManager crudManager = new CrudManager(Environment.getInstance().getOpenAPI());

        // Iterate on batches of CRUD operations
        for (CrudGroup crudGroup : crudManager.getInferredGroups()) {

            MassAssignmentFuzzer massAssignmentFuzzer = new MassAssignmentFuzzer(crudGroup);
            massAssignmentFuzzer.setUseInferredCRUDInformation(true);
            List<TestSequence> testSequences = massAssignmentFuzzer.generateTestSequences();

            MassAssignmentOracle massAssignmentOracle = new MassAssignmentOracle();
            massAssignmentOracle.setUseInferredCRUDInformation(true);
            for (TestSequence testSequence : testSequences) {

                // Evaluate sequence with oracle
                massAssignmentOracle.assertTestSequence(testSequence);
                
                // Collect for WFC report
                allTestSequences.add(testSequence);

                // Write report to file
                try {
                    ReportWriter reportWriter = new ReportWriter(testSequence);
                    reportWriter.write();
                } catch (IOException e) {
                    logger.warn("Could not write report to file.");
                }
            }
            try {
                TestSequence globalDebugSequence = TestRunner.globalTestSequenceForDebug;
                globalDebugSequence.setName("GlobalSequenceForDebugPurposes");
                ReportWriter reportWriter = new ReportWriter(globalDebugSequence);
                reportWriter.write();
            } catch (IOException e) {
                logger.warn("Could not write global report to file.");
            }

        }
        
        // Write WFC Report with all test sequences for proper Oracle result -> F203 fault mapping
        long executionTimeInSeconds = (System.currentTimeMillis() - startTime) / 1000;
        writeWfcReport(executionTimeInSeconds, allTestSequences);
    }
    
    /**
     * Writes the WFC (Web Fuzzing Commons) report.
     */
    private void writeWfcReport(long executionTimeInSeconds, List<TestSequence> testSequences) {
        try {
            // Use constructor that accepts all test sequences for Oracle result -> WFC fault mapping
            WfcReportWriter wfcReportWriter = new WfcReportWriter(testSequences, executionTimeInSeconds);
            wfcReportWriter.write();
            logger.info("WFC Report generated successfully.");
        } catch (IOException e) {
            logger.warn("Could not write WFC report to file.", e);
        }
    }
}
package io.resttestgen.implementation.oracle;

import io.resttestgen.core.testing.Oracle;
import io.resttestgen.core.testing.TestInteraction;
import io.resttestgen.core.testing.TestResult;
import io.resttestgen.core.testing.TestSequence;
import io.resttestgen.core.testing.WfcFaultCategory;

/**
 * Evaluates an erroneous sequence whose last test interaction is mutated by the error fuzzer.
 * 
 * WFC Fault Mapping:
 * - Invalid input accepted with 2XX is mapped to F102:Received Success Response When Sending Wrong Data
 * - Server errors (5XX status codes) are mapped to F100:HTTP Status 500
 */
public class ErrorStatusCodeOracle extends Oracle {

    @Override
    public TestResult assertTestSequence(TestSequence testSequence) {

        TestResult testResult = new TestResult();

        if (!testSequence.isExecuted()) {
            return testResult.setError("One or more interaction in the sequence have not been executed.");
        }

        if (!testSequence.isEmpty()) {
            TestInteraction testInteraction = testSequence.getLast();
            if (testInteraction.getResponseStatusCode().isClientError()) {
                testResult.setPass("The erroneous test sequence was rejected by the server.");
            } else if (testInteraction.getResponseStatusCode().isSuccessful()) {
                testResult.setFail("The erroneous test sequence was accepted as valid by the server.",
                        WfcFaultCategory.SCHEMA_VALIDATION_BYPASS);
            } else if (testInteraction.getResponseStatusCode().isServerError()) {
                testResult.setFail("A server error occurred during the execution of the sequence.",
                        WfcFaultCategory.HTTP_STATUS_500);
            }
        }
        testSequence.addTestResult(this, testResult);
        return testResult;
    }
}

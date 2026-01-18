package io.resttestgen.core.testing;

/**
 * Enumeration of WFC (Web Fuzzing Commons) fault categories.
 * Based on the fault categories defined in:
 * https://github.com/WebFuzzing/Commons/blob/master/src/main/resources/wfc/faults/fault_categories.json
 * 
 * This enum provides a local copy of WFC fault categories to enable RTG oracles
 * to report faults using the standardized WFC classification.
 */
public enum WfcFaultCategory {

    /**
     * F100: HTTP Status 500
     * The HTTP status code 500 represents a 'Server Error'.
     */
    HTTP_STATUS_500(100, "HTTP Status 500", "causes500_internalServerError"),

    /**
     * F101: Schema Invalid Response
     * Received a response from API with a structure/data that is not matching its schema.
     */
    SCHEMA_INVALID_RESPONSE(101, 
            "Received A Response From API With A Structure/Data That Is Not Matching Its Schema", 
            "returnsMismatchResponseWithSchema"),

    /**
     * F102: Schema Validation Bypass
     * Received success response when sending wrong/invalid data.
     */
    SCHEMA_VALIDATION_BYPASS(102, 
            "Received Success Response When Sending Wrong Data", 
            "successOnInvalidInputs"),

    /**
     * F103: Delete Not Working
     * Resource still accessible after being deleted.
     */
    DELETE_NOT_WORKING(103, 
            "Resource Still Accessible After Being Deleted", 
            "deleteNotWorking"),

    /**
     * F104: Failed Creation Side Effects
     * Failed creation of resource has side effects on backend.
     */
    FAILED_CREATION_SIDE_EFFECTS(104, 
            "Failed Creation of Resource Has Side Effects on Backend", 
            "sideEffectsOnFailedCreation"),

    /**
     * F200: SQL Injection (SQLi)
     */
    SQL_INJECTION(200, "SQL Injection (SQLi)", "vulnerableToSQLInjection"),

    /**
     * F201: Cross-Site Scripting (XSS)
     */
    XSS(201, "Cross-Site Scripting (XSS)", "vulnerableToXSS"),

    /**
     * F202: Server-Side Request Forgery (SSRF)
     */
    SSRF(202, "Server-Side Request Forgery (SSRF)", "vulnerableToSSRF"),

    /**
     * F203: Mass Assignment
     * This vulnerability exploits possible active record pattern misconfigurations to modify fields of
     * a record that should not be accessible via the API.
     */
    MASS_ASSIGNMENT(203, "Mass Assignment", "vulnerableToMassAssignment"),

    /**
     * F204: Security Existence Leakage
     * Leakage information existence of protected resource.
     */
    SECURITY_EXISTENCE_LEAKAGE(204, 
            "Leakage Information Existence of Protected Resource", 
            "allowsUnauthorizedAccessToProtectedResource"),

    /**
     * F205: Security Not Recognized Authenticated
     * Wrongly not recognized as authenticated.
     */
    SECURITY_NOT_RECOGNIZED_AUTHENTICATED(205, 
            "Wrongly Not Recognized as Authenticated", 
            "authenticatedButWronglyToldNot"),

    /**
     * F206: Security Wrong Authorization
     * Allowed to modify resource that likely should have been protected.
     */
    SECURITY_WRONG_AUTHORIZATION(206, 
            "Allowed To Modify Resource That Likely Should Had Been Protected", 
            "missedAuthorizationCheck");

    private final int code;
    private final String descriptiveName;
    private final String testCaseLabel;

    WfcFaultCategory(int code, String descriptiveName, String testCaseLabel) {
        this.code = code;
        this.descriptiveName = descriptiveName;
        this.testCaseLabel = testCaseLabel;
    }

    /**
     * @return The unique code identifying this fault category
     */
    public int getCode() {
        return code;
    }

    /**
     * @return A short descriptive name to explain the category
     */
    public String getDescriptiveName() {
        return descriptiveName;
    }

    /**
     * @return A short label that can be used in test case naming
     */
    public String getTestCaseLabel() {
        return testCaseLabel;
    }

    /**
     * @return A descriptive identifier for this category (e.g., "F100:HTTP Status 500")
     */
    public String getLabel() {
        return "F" + code + ":" + descriptiveName;
    }
}

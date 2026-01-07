package io.resttestgen.boot;

import io.resttestgen.core.datatype.ParameterName;
import io.resttestgen.core.datatype.parameter.attributes.ParameterLocation;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * WFC Authentication info holder that uses WfcAuthHandler directly.
 */
public class WfcAuthInfo {

    private static final Logger logger = LogManager.getLogger(WfcAuthInfo.class);
    private static final WfcAuthHandler wfcAuthHandler = new WfcAuthHandler();
    
    // Auth failure handling constants
    private static final int MAX_CONSECUTIVE_FAILURES = 3;
    private static final long FAILURE_COOLDOWN_SECONDS = 5;
    private static final String UNAUTHENTICATED_LOG_FILENAME = "auth-fallback-unauthenticated.txt";

    private final String authFilePath;
    private final String baseUrl;

    // Auth state (populated after authentication)
    private ParameterName parameterName;
    private String value;
    private ParameterLocation in;
    private Long duration;
    private Long lastAuthUnixTimeStamp = 0L;
    
    // Failure tracking
    private int consecutiveFailures = 0;
    private long lastFailureTime = 0L;
    private int successfulLoginCount = 0;
    
    // Unauthenticated mode flag
    private boolean unauthenticatedMode = false;
    private boolean unauthenticatedModeLogged = false;

    /**
     * Create WFC auth info from auth.yaml path and base URL.
     */
    public WfcAuthInfo(String authFilePath, String baseUrl) {
        this.authFilePath = authFilePath;
        this.baseUrl = baseUrl;
    }

    /**
     * Perform authentication using WfcAuthHandler.
     * @return true if authentication succeeded
     */
    public boolean authenticate() {
        long currentUnixTime = Instant.now().getEpochSecond();

        logger.info("WFC authentication from: {} with baseUrl: {}", authFilePath, baseUrl);

        WfcAuthHandler.AuthResult result = wfcAuthHandler.authenticate(authFilePath, baseUrl);

        if (result == null) {
            logger.error("WFC authentication failed for: {}", authFilePath);
            return false;
        }

        // Populate auth state from result
        this.parameterName = new ParameterName(result.headerName);
        this.value = result.headerValue;
        this.in = ParameterLocation.getLocationFromString(result.location);
        this.duration = result.duration;
        this.lastAuthUnixTimeStamp = currentUnixTime;

        logger.info("WFC authentication successful: {} = {}... (duration: {}s)",
                result.headerName, 
                result.headerValue.substring(0, Math.min(20, result.headerValue.length())), 
                result.duration);

        return true;
    }

    /**
     * Check if currently authenticated and not expired.
     */
    public boolean isAuthenticated() {
        if (unauthenticatedMode) {
            return false; // In unauthenticated mode, always return false
        }
        return parameterName != null && value != null && in != null && duration != null &&
                Instant.now().getEpochSecond() < lastAuthUnixTimeStamp + duration;
    }

    /**
     * Authenticate if not already authenticated or if token is expired.
     * - Fallback to unauthenticated mode after MAX_CONSECUTIVE_FAILURES
     */
    public boolean authenticateIfNot() {
        // If already in unauthenticated mode, just return
        if (unauthenticatedMode) {
            return false;
        }
        
        if (!isAuthenticated()) {
            long now = Instant.now().getEpochSecond();
            
            // Check if we're in failure cooldown
            if (consecutiveFailures > 0 && now - lastFailureTime < FAILURE_COOLDOWN_SECONDS) {
                logger.debug("WFC: In failure cooldown, waiting before retry.");
                return false;
            }
            
            // Check if max consecutive failures reached -> switch to unauthenticated mode
            if (consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) {
                switchToUnauthenticatedMode("Max consecutive auth failures (" + consecutiveFailures + ") reached");
                return false;
            }
            
            // Attempt authentication (re-login when expired - standard RTG behavior)
            logger.info("WFC: Re-authenticating (reason: token expired/missing, login #{})", successfulLoginCount + 1);
            
            if (!authenticate()) {
                // Auth FAILED - increment failure counter
                consecutiveFailures++;
                lastFailureTime = now;
                
                logger.warn("WFC: Auth failed (failure {}/{})", consecutiveFailures, MAX_CONSECUTIVE_FAILURES);
                
                // If max failures reached, switch to unauthenticated mode
                if (consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) {
                    switchToUnauthenticatedMode("Auth failed " + consecutiveFailures + " consecutive times");
                }
                return false;
            }
            
            // Auth SUCCEEDED - reset failure counter, increment login counter
            consecutiveFailures = 0;
            successfulLoginCount++;
            logger.info("WFC: Token obtained successfully (total logins: {})", successfulLoginCount);
        }
        return true;
    }

    /**
     * Switch to unauthenticated mode and log to file.
     */
    private void switchToUnauthenticatedMode(String reason) {
        if (unauthenticatedMode) {
            return; // Already in unauthenticated mode
        }
        
        unauthenticatedMode = true;
        
        // Clear auth values
        this.parameterName = null;
        this.value = null;
        this.in = null;
        
        logger.error("WFC: SWITCHING TO UNAUTHENTICATED MODE - {}", reason);
        logger.error("WFC: All subsequent requests will be sent without authentication headers.");
        logger.error("WFC: This may result in 401/403 responses for protected endpoints.");
        
        // Log to file
        logUnauthenticatedModeToFile(reason);
    }
    
    /**
     * Log the switch to unauthenticated mode to a file in the results folder.
     */
    private void logUnauthenticatedModeToFile(String reason) {
        if (unauthenticatedModeLogged) {
            return; // Already logged
        }
        
        try {
            // Try to find the results directory
            String resultsDir = findResultsDirectory();
            Path logFile = Paths.get(resultsDir, UNAUTHENTICATED_LOG_FILENAME);
            
            // Create parent directories if needed
            Files.createDirectories(logFile.getParent());
            
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            
            try (PrintWriter writer = new PrintWriter(new FileWriter(logFile.toFile(), true))) {
                writer.println("================================================================================");
                writer.println("AUTHENTICATION FALLBACK TO UNAUTHENTICATED MODE");
                writer.println("================================================================================");
                writer.println("Timestamp: " + timestamp);
                writer.println("Auth File: " + authFilePath);
                writer.println("Base URL: " + baseUrl);
                writer.println("Reason: " + reason);
                writer.println("Consecutive Failures: " + consecutiveFailures);
                writer.println("Successful Logins Before Failure: " + successfulLoginCount);
                writer.println("--------------------------------------------------------------------------------");
                writer.println("NOTE: All subsequent requests will be sent WITHOUT authentication.");
                writer.println("      Protected endpoints will likely return 401/403 errors.");
                writer.println("      This may indicate the test account was deleted/modified by fuzzing.");
                writer.println("================================================================================");
                writer.println();
            }
            
            unauthenticatedModeLogged = true;
            logger.info("WFC: Unauthenticated mode logged to: {}", logFile);
            
        } catch (IOException e) {
            logger.error("WFC: Failed to write unauthenticated mode log: {}", e.getMessage());
        }
    }
    
    /**
     * Find the results directory for the current API.
     */
    private String findResultsDirectory() {
        // Try to extract API name from authFilePath
        // Format: ./apis/<api-name>/auth/<auth-file>.yaml
        try {
            Path authPath = Paths.get(authFilePath);
            Path parent = authPath.getParent(); // auth/
            if (parent != null) {
                Path apiDir = parent.getParent(); // <api-name>/
                if (apiDir != null) {
                    Path resultsDir = apiDir.resolve("results");
                    return resultsDir.toString();
                }
            }
        } catch (Exception e) {
            logger.debug("Could not determine results directory from auth path: {}", e.getMessage());
        }
        
        // Fallback: use current directory
        return "./results";
    }

    // Getters that auto-authenticate if needed

    public ParameterName getParameterName() {
        authenticateIfNot();
        return parameterName;
    }

    public String getValue() {
        authenticateIfNot();
        return value;
    }

    public ParameterLocation getIn() {
        authenticateIfNot();
        return in;
    }

    public Long getDuration() {
        return duration;
    }

    public String getAuthFilePath() {
        return authFilePath;
    }

    public String getBaseUrl() {
        return baseUrl;
    }
    
    /**
     * Check if we're in unauthenticated mode (auth failed permanently).
     */
    public boolean isUnauthenticatedMode() {
        return unauthenticatedMode;
    }
    
    /**
     * Get the count of successful logins during this session.
     */
    public int getSuccessfulLoginCount() {
        return successfulLoginCount;
    }
}

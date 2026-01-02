package io.resttestgen.boot;

import io.resttestgen.core.datatype.ParameterName;
import io.resttestgen.core.datatype.parameter.attributes.ParameterLocation;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.time.Instant;

/**
 * WFC Authentication info holder that uses WfcAuthHandler directly.
 * Replaces the convoluted AuthenticationInfo wrapper for WFC auth.
 */
public class WfcAuthInfo {

    private static final Logger logger = LogManager.getLogger(WfcAuthInfo.class);
    private static final WfcAuthHandler wfcAuthHandler = new WfcAuthHandler();

    private final String authFilePath;
    private final String baseUrl;

    // Auth state (populated after authentication)
    private ParameterName parameterName;
    private String value;
    private ParameterLocation in;
    private Long duration;
    private Long lastAuthUnixTimeStamp = 0L;

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
                result.headerName, result.headerValue.substring(0, Math.min(20, result.headerValue.length())), result.duration);

        return true;
    }

    /**
     * Check if currently authenticated and not expired.
     */
    public boolean isAuthenticated() {
        return parameterName != null && value != null && in != null && duration != null &&
                Instant.now().getEpochSecond() < lastAuthUnixTimeStamp + duration;
    }

    /**
     * Authenticate if not already authenticated or expired.
     */
    public boolean authenticateIfNot() {
        if (!isAuthenticated()) {
            return authenticate();
        }
        return true;
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
}

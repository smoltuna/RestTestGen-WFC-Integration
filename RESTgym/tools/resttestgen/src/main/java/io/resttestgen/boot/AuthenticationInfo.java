package io.resttestgen.boot;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;
import io.resttestgen.core.datatype.ParameterName;
import io.resttestgen.core.datatype.parameter.attributes.ParameterLocation;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.time.Instant;
import java.util.LinkedHashMap;

public class AuthenticationInfo {

    private static final Logger logger = LogManager.getLogger(AuthenticationInfo.class);
    private static final int MAX_AUTH_ATTEMPTS = 5;
    private static final long AUTH_COOLDOWN_SECONDS = 10;

    private String description;
    private String command;
    private ParameterName parameterName;
    private String value;
    private ParameterLocation in;
    private Long duration;
    private Long lastAuthUnixTimeStamp = 0L;

    private String cachedValue = null;
    private ParameterName cachedParameterName = null;
    private ParameterLocation cachedIn = null;
    private int authAttemptCount = 0;
    private long lastAuthAttemptTime = 0L;

    private final static String ignoredAuthInfoError = "This authentication information will be probably ignored.";

    public AuthenticationInfo(String description, String command) {
        this.description = description;
        this.command = command;
    }

    /**
     * Performs authentication by running the authentication script.
     * @return true if the authentication succeeded, false otherwise.
     */
    @SuppressWarnings("unchecked")
    public boolean authenticate() {

        // Store current time to be used as authentication time if authentication is successful
        long currentUnixTime = getCurrentUnixTimeStamp();

        // Proceed only if the command is not null or too short
        if (command == null || command.trim().length() <= 1) {
            logger.warn("Invalid authentication command specified in the API configuration for '{}'. " + ignoredAuthInfoError, description);
            return false;
        }

        StringBuilder stringBuilder = new StringBuilder();

        try {
            Process process = Runtime.getRuntime().exec(command);
            BufferedReader stdInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
            BufferedReader stdError = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            String s;
            while ((s = stdError.readLine()) != null) {
                logger.error(s);
            }
            while ((s = stdInput.readLine()) != null) {
                stringBuilder.append(s);
            }
        } catch (IOException e) {
            logger.error("Could not execute authentication script for '{}'. " + ignoredAuthInfoError, description);
        }

        LinkedHashMap<String, Object> map = null;

        try {
            map = new Gson().fromJson(stringBuilder.toString(), LinkedHashMap.class);
        } catch (JsonSyntaxException | NullPointerException e) {
            logger.warn("Authorization script must return valid JSON data, in the format specified in the README.md file. Instead, its result was: {}. " + ignoredAuthInfoError, stringBuilder);
            return false;
        }

        // Check that the parsed JSON map contains all and only the required fields
        if (map.size() < 4 || !map.containsKey("name") || !map.containsKey("value") ||
                !map.containsKey("in") || !map.containsKey("duration")) {

            logger.error("Authorization script must return a JSON containing all and only the following fields 'name', 'value', 'in', 'duration'. Instead, its result was: {}. " + ignoredAuthInfoError, map);
            return false;
        }

        // Use info to fill instance of the class
        setParameterName(new ParameterName((String) map.get("name")));
        setValue((String) map.get("value"));
        setIn(ParameterLocation.getLocationFromString((String) map.get("in")));
        setDuration(((Double) map.get("duration")).longValue());

        // Finally, set authentication time with the time in which this method was called
        this.lastAuthUnixTimeStamp = currentUnixTime;
        
        // Cache successful auth values
        this.cachedParameterName = this.parameterName;
        this.cachedValue = this.value;
        this.cachedIn = this.in;

        return true;
    }

    /**
     * Checks if the system is authenticated by verifying that all the relevant attributes of the class are set, and
     * the authentication is not expired.
     * @return true if the system is currently authenticated.
     */
    public boolean isAuthenticated() {
        return parameterName != null && value != null && in != null && duration != null &&
                getCurrentUnixTimeStamp() < lastAuthUnixTimeStamp + duration;
    }

    /**
     * Performs authentication if the system is not authenticated.
     * Limits retries and enforces cooldown.
     * @return true if authentication succeeded, or if authentication was already processed.
     */
    public boolean authenticateIfNot() {
        if (!isAuthenticated()) {
            long now = getCurrentUnixTimeStamp();
            
            if (authAttemptCount >= MAX_AUTH_ATTEMPTS) {
                if (cachedValue != null) {
                    logger.warn("Auth: Max attempts ({}) reached. Using cached token.", MAX_AUTH_ATTEMPTS);
                    return true;
                }
                logger.error("Auth: Max attempts ({}) reached with no cached token.", MAX_AUTH_ATTEMPTS);
                return false;
            }
            
            if (now - lastAuthAttemptTime < AUTH_COOLDOWN_SECONDS && authAttemptCount > 0) {
                if (cachedValue != null) {
                    logger.debug("Auth: Cooldown active, using cached token.");
                    return true;
                }
                logger.warn("Auth: Cooldown active, no cached token available.");
                return false;
            }
            
            // Attempt authentication
            authAttemptCount++;
            lastAuthAttemptTime = now;
            
            if (!authenticate()) {
                // Auth failed - use cached values if available
                if (cachedValue != null) {
                    logger.warn("Auth: Failed, falling back to cached token (attempt {}/{})", 
                            authAttemptCount, MAX_AUTH_ATTEMPTS);
                    this.parameterName = cachedParameterName;
                    this.value = cachedValue;
                    this.in = cachedIn;
                    return true;
                }
                return false;
            }
            
            // Auth succeeded - reset attempt counter
            authAttemptCount = 0;
        }
        return true;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCommand() {
        return command;
    }

    public void setCommand(String command) {
        this.command = command;
    }

    public ParameterName getParameterName() {
        authenticateIfNot();
        return parameterName;
    }

    public void setParameterName(ParameterName parameterName) {
        this.parameterName = parameterName;
    }

    public String getValue() {
        authenticateIfNot();
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public ParameterLocation getIn() {
        authenticateIfNot();
        return in;
    }

    public void setIn(ParameterLocation in) {
        this.in = in;
    }

    public Long getDuration() {
        return duration;
    }

    public void setDuration(Long duration) {
        this.duration = duration;
    }

    public Long getLastAuthUnixTimeStamp() {
        return lastAuthUnixTimeStamp;
    }

    private long getCurrentUnixTimeStamp() {
        return Instant.now().getEpochSecond();
    }
}

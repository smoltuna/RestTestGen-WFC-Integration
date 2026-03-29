package io.resttestgen.boot;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import okhttp3.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.yaml.snakeyaml.Yaml;

import java.io.FileInputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Handles WFC (Web Fuzzing Commons) authentication schema.
 * Conforms to the WFC auth.yaml specification (JSON Schema draft 2020-12).
 *
 */
public class WfcAuthHandler {

    private static final Logger logger = LogManager.getLogger(WfcAuthHandler.class);
    private static final Gson gson = new Gson();
    private static final Yaml yaml = new Yaml();
    private static final long DEFAULT_DURATION = 3600L; // 1 hour default token duration

    private final OkHttpClient httpClient;

    public WfcAuthHandler() {
        this.httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .writeTimeout(10, TimeUnit.SECONDS)
                .hostnameVerifier((hostname, session) -> true) // Allow any hostname (dev environments)
                .build();
    }

    /**
     * Result of WFC authentication containing header/query/cookie info.
     */
    public static class AuthResult {
        public final String headerName;
        public final String headerValue;
        public final String location; // "header", "query", "cookie"
        public final long duration; // seconds until expiration

        public AuthResult(String headerName, String headerValue, String location, long duration) {
            this.headerName = headerName;
            this.headerValue = headerValue;
            this.location = location;
            this.duration = duration;
        }
    }

    /**
     * Load and process WFC auth.yaml file, returning authentication result.
     *
     * @param authYamlPath    Path to the auth.yaml file
     * @param baseUrlOverride Optional base URL override (e.g., from dynamic port)
     * @return AuthResult containing header info, or null if auth fails
     */
    @SuppressWarnings("unchecked")
    public AuthResult authenticate(String authYamlPath, String baseUrlOverride) {
        try {
            Map<String, Object> config = yaml.load(new FileInputStream(authYamlPath));
            if (config == null || !config.containsKey("auth")) {
                logger.error("Invalid WFC auth.yaml - missing 'auth' array");
                return null;
            }

            // Log schema version if present
            String schemaVersion = (String) config.get("schemaVersion");
            if (schemaVersion != null) {
                logger.info("WFC: Auth schema version: {}", schemaVersion);
            }

            // Log configs if present
            Map<String, String> configs = (Map<String, String>) config.get("configs");
            if (configs != null && !configs.isEmpty()) {
                logger.info("WFC: Custom configs found: {}", configs.keySet());
            }

            // Get template and users
            Map<String, Object> template = getMapOrEmpty(config, "authTemplate");
            List<Map<String, Object>> users = (List<Map<String, Object>>) config.get("auth");

            if (users == null || users.isEmpty()) {
                logger.error("No users defined in WFC auth.yaml");
                return null;
            }

            // Determine base URL: override > template > default
            String baseUrl = baseUrlOverride;
            if (baseUrl == null || baseUrl.isEmpty()) {
                baseUrl = (String) template.getOrDefault("baseUrl", "http://localhost:8080");
            }

            // Find 'default' user or use first user
            Map<String, Object> selectedUser = null;
            for (Map<String, Object> user : users) {
                if ("default".equals(user.get("name"))) {
                    selectedUser = user;
                    break;
                }
            }
            if (selectedUser == null) {
                selectedUser = users.get(0);
            }

            // Merge user config with template
            Map<String, Object> mergedUser = mergeWithTemplate(selectedUser, template);

            // Process authentication
            return processAuth(baseUrl, mergedUser);

        } catch (Exception e) {
            logger.error("Error processing WFC auth: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Process authentication for a user configuration.
     */
    @SuppressWarnings("unchecked")
    private AuthResult processAuth(String baseUrl, Map<String, Object> user) {
        // Check for fixed headers first (no login required)
        List<Map<String, String>> fixedHeaders = (List<Map<String, String>>) user.get("fixedHeaders");
        if (fixedHeaders != null && !fixedHeaders.isEmpty()) {
            // Use the first fixed header as the primary auth header.
            // If multiple are present, log them all but return the first for AuthResult
            // (RequestManager applies it; additional headers are logged as informational).
            if (fixedHeaders.size() > 1) {
                logger.info("WFC: {} fixed headers found; using first as primary auth", fixedHeaders.size());
                for (int i = 1; i < fixedHeaders.size(); i++) {
                    logger.info("WFC: Additional fixed header [{}]: {}", i, fixedHeaders.get(i).get("name"));
                }
            }
            Map<String, String> header = fixedHeaders.get(0);
            String name = header.get("name");
            String value = header.get("value");
            logger.info("WFC: Using fixed header authentication ({})", name);
            return new AuthResult(name, value, "header", DEFAULT_DURATION);
        }

        // Need to perform login
        // First, try signup if configured (extension to WFC schema)
        Map<String, Object> signupConfig = getMapOrEmpty(user, "signupEndpoint");
        if (!signupConfig.isEmpty()) {
            performSignup(baseUrl, signupConfig);
        }

        // Perform login
        Map<String, Object> loginConfig = getMapOrEmpty(user, "loginEndpointAuth");
        if (loginConfig.isEmpty()) {
            logger.error("WFC: No fixedHeaders or loginEndpointAuth configured");
            return null;
        }

        return performLogin(baseUrl, loginConfig);
    }

    /**
     * Return all fixed headers from the user config (for callers that need them all).
     * Returns an empty list if no fixedHeaders are defined or login-based auth is used.
     */
    @SuppressWarnings("unchecked")
    public List<Map<String, String>> getAllFixedHeaders(String authYamlPath, String baseUrlOverride) {
        try {
            Map<String, Object> config = yaml.load(new FileInputStream(authYamlPath));
            if (config == null || !config.containsKey("auth")) return Collections.emptyList();

            Map<String, Object> template = getMapOrEmpty(config, "authTemplate");
            List<Map<String, Object>> users = (List<Map<String, Object>>) config.get("auth");
            if (users == null || users.isEmpty()) return Collections.emptyList();

            Map<String, Object> selectedUser = null;
            for (Map<String, Object> user : users) {
                if ("default".equals(user.get("name"))) { selectedUser = user; break; }
            }
            if (selectedUser == null) selectedUser = users.get(0);

            Map<String, Object> merged = mergeWithTemplate(selectedUser, template);
            List<Map<String, String>> fixedHeaders = (List<Map<String, String>>) merged.get("fixedHeaders");
            return fixedHeaders != null ? fixedHeaders : Collections.emptyList();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    /**
     * Perform user signup/registration (extension to WFC schema).
     */
    private void performSignup(String baseUrl, Map<String, Object> signupConfig) {
        String endpoint = (String) signupConfig.getOrDefault("endpoint", "");
        String verb = ((String) signupConfig.getOrDefault("verb", "POST")).toUpperCase();
        String contentType = (String) signupConfig.getOrDefault("contentType", "application/json");
        String payloadRaw = (String) signupConfig.getOrDefault("payloadRaw", "");

        String signupUrl = joinUrl(baseUrl, endpoint);
        logger.info("WFC: Performing signup at {}", signupUrl);

        try {
            RequestBody body = RequestBody.create(payloadRaw, MediaType.parse(contentType));
            Request.Builder requestBuilder = new Request.Builder()
                    .url(signupUrl)
                    .addHeader("Content-Type", contentType)
                    .addHeader("Accept", "application/json");

            applyVerb(requestBuilder, verb, body);

            Response response = httpClient.newCall(requestBuilder.build()).execute();
            int statusCode = response.code();
            response.close();

            // Signup can fail if user already exists (409, 422, 400) - that's OK
            if (statusCode == 200 || statusCode == 201 || statusCode == 409 || statusCode == 422 || statusCode == 400) {
                logger.info("WFC: Signup response: {} (acceptable)", statusCode);
            } else {
                logger.warn("WFC: Signup response: {} (unexpected)", statusCode);
            }
        } catch (Exception e) {
            logger.warn("WFC: Signup error: {}", e.getMessage());
        }
    }

    /**
     * Perform login and extract token (or cookies).
     */
    @SuppressWarnings("unchecked")
    private AuthResult performLogin(String baseUrl, Map<String, Object> loginConfig) {
        String endpoint = (String) loginConfig.getOrDefault("endpoint", "");
        String externalUrl = (String) loginConfig.get("externalEndpointURL");
        String verb = ((String) loginConfig.getOrDefault("verb", "POST")).toUpperCase();
        String contentType = (String) loginConfig.getOrDefault("contentType", "application/json");

        // Determine login URL
        String loginUrl = (externalUrl != null && !externalUrl.isEmpty())
                ? externalUrl
                : joinUrl(baseUrl, endpoint);

        logger.info("WFC: Performing login at {}", loginUrl);

        // Build payload: prefer payloadRaw, fallback to payloadUserPwd
        String payload = (String) loginConfig.get("payloadRaw");
        if (payload == null) {
            Map<String, Object> userPwd = getMapOrEmpty(loginConfig, "payloadUserPwd");
            if (!userPwd.isEmpty()) {
                payload = buildPayloadFromUserPwd(userPwd, contentType);
            }
        }

        try {
            RequestBody body = RequestBody.create(payload != null ? payload : "", MediaType.parse(contentType));
            Request.Builder requestBuilder = new Request.Builder()
                    .url(loginUrl)
                    .addHeader("Content-Type", contentType)
                    .addHeader("Accept", "application/json");

            // Apply additional login headers from config
            List<Map<String, String>> loginHeaders = (List<Map<String, String>>) loginConfig.get("headers");
            if (loginHeaders != null) {
                for (Map<String, String> h : loginHeaders) {
                    String hName = h.get("name");
                    String hValue = h.get("value");
                    if (hName != null && hValue != null) {
                        requestBuilder.addHeader(hName, hValue);
                    }
                }
            }

            applyVerb(requestBuilder, verb, body);

            Response response = httpClient.newCall(requestBuilder.build()).execute();
            int statusCode = response.code();
            String responseBody = response.body() != null ? response.body().string() : "";
            Headers responseHeaders = response.headers();
            response.close();

            logger.info("WFC: Login response: {}", statusCode);

            if (statusCode != 200 && statusCode != 201) {
                logger.error("WFC: Login failed: {}", responseBody.substring(0, Math.min(500, responseBody.length())));
                return null;
            }

            // Check if we should extract cookies instead of a token
            Boolean expectCookies = (Boolean) loginConfig.get("expectCookies");
            if (Boolean.TRUE.equals(expectCookies)) {
                return extractCookies(responseHeaders);
            }

            // Extract token from response
            Map<String, Object> tokenConfig = getMapOrEmpty(loginConfig, "token");
            if (tokenConfig.isEmpty()) {
                logger.error("WFC: No token configuration found");
                return null;
            }

            return extractToken(responseBody, responseHeaders, tokenConfig);

        } catch (Exception e) {
            logger.error("WFC: Login error: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Build a payload string from the structured payloadUserPwd object,
     * formatted according to the given contentType.
     */
    private String buildPayloadFromUserPwd(Map<String, Object> userPwd, String contentType) {
        String username = (String) userPwd.get("username");
        String password = (String) userPwd.get("password");
        String usernameField = (String) userPwd.get("usernameField");
        String passwordField = (String) userPwd.get("passwordField");

        if (username == null || password == null || usernameField == null || passwordField == null) {
            logger.error("WFC: payloadUserPwd missing required fields");
            return null;
        }

        if (contentType != null && contentType.contains("x-www-form-urlencoded")) {
            return URLEncoder.encode(usernameField, StandardCharsets.UTF_8) + "=" +
                    URLEncoder.encode(username, StandardCharsets.UTF_8) + "&" +
                    URLEncoder.encode(passwordField, StandardCharsets.UTF_8) + "=" +
                    URLEncoder.encode(password, StandardCharsets.UTF_8);
        }

        // Default: JSON
        JsonObject json = new JsonObject();
        json.addProperty(usernameField, username);
        json.addProperty(passwordField, password);
        return gson.toJson(json);
    }

    /**
     * Extract cookies from login response headers (expectCookies mode).
     */
    private AuthResult extractCookies(Headers responseHeaders) {
        List<String> setCookies = responseHeaders.values("Set-Cookie");
        if (setCookies.isEmpty()) {
            logger.error("WFC: expectCookies=true but no Set-Cookie headers in response");
            return null;
        }

        // Build a combined Cookie header value from all Set-Cookie entries
        StringBuilder cookieValue = new StringBuilder();
        for (String sc : setCookies) {
            // Extract cookie name=value (before first ';')
            String nameValue = sc.contains(";") ? sc.substring(0, sc.indexOf(';')) : sc;
            if (cookieValue.length() > 0) cookieValue.append("; ");
            cookieValue.append(nameValue.trim());
        }

        logger.info("WFC: Extracted {} cookies from login response", setCookies.size());
        return new AuthResult("Cookie", cookieValue.toString(), "cookie", DEFAULT_DURATION);
    }

    /**
     * Extract token from login response (body or header), using standard WFC 0.2.0 field names.
     */
    private AuthResult extractToken(String responseBody, Headers responseHeaders, Map<String, Object> tokenConfig) {
        String extractFrom = (String) tokenConfig.getOrDefault("extractFrom", "body");
        String extractSelector = (String) tokenConfig.get("extractSelector");
        String sendIn = (String) tokenConfig.getOrDefault("sendIn", "header");
        String sendName = (String) tokenConfig.getOrDefault("sendName", "Authorization");
        String sendTemplate = (String) tokenConfig.get("sendTemplate");

        if (extractSelector == null || extractSelector.isEmpty()) {
            logger.error("WFC: No extractSelector specified in token config");
            return null;
        }

        try {
            String token;

            if ("header".equalsIgnoreCase(extractFrom)) {
                // Extract token from response header
                token = responseHeaders.get(extractSelector);
                if (token == null || token.isEmpty()) {
                    logger.error("WFC: Failed to extract token from response header '{}'", extractSelector);
                    return null;
                }
            } else {
                // Extract token from response body (JSON Pointer)
                JsonObject json = gson.fromJson(responseBody, JsonObject.class);
                token = extractJsonPointer(json, extractSelector);

                if (token == null || token.isEmpty()) {
                    logger.error("WFC: Failed to extract token using selector '{}'", extractSelector);
                    return null;
                }

                // Extract duration from body
                long duration = extractDuration(json);

                // Build the final token value
                String finalValue = applyTokenTemplate(token, sendTemplate);
                logger.info("WFC: Token extracted successfully from body (duration: {}s, sendIn: {})", duration, sendIn);
                return new AuthResult(sendName, finalValue, sendIn, duration);
            }

            // For header-extracted tokens, no JSON body to get duration from
            String finalValue = applyTokenTemplate(token, sendTemplate);
            logger.info("WFC: Token extracted successfully from header '{}' (sendIn: {})", extractSelector, sendIn);
            return new AuthResult(sendName, finalValue, sendIn, DEFAULT_DURATION);

        } catch (Exception e) {
            logger.error("WFC: Failed to parse response for token extraction: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Apply token template to a raw token value.
     * sendTemplate contains "{token}" placeholder, e.g., "Bearer {token}"
     */
    private String applyTokenTemplate(String token, String sendTemplate) {
        if (sendTemplate != null && !sendTemplate.isEmpty()) {
            return sendTemplate.replace("{token}", token);
        }
        return token;
    }

    /**
     * Apply HTTP verb to request builder. Supports all five WFC verbs: POST, GET, PUT, PATCH, DELETE.
     */
    private void applyVerb(Request.Builder requestBuilder, String verb, RequestBody body) {
        switch (verb) {
            case "POST":   requestBuilder.post(body);   break;
            case "GET":    requestBuilder.get();         break;
            case "PUT":    requestBuilder.put(body);     break;
            case "PATCH":  requestBuilder.patch(body);   break;
            case "DELETE": requestBuilder.delete(body);  break;
            default:
                logger.warn("WFC: Unsupported HTTP verb '{}', defaulting to POST", verb);
                requestBuilder.post(body);
        }
    }

    /**
     * Extract value from JSON using JSON Pointer syntax (e.g., "/access_token" or "/user/token").
     */
    private String extractJsonPointer(JsonObject json, String pointer) {
        if (pointer == null || !pointer.startsWith("/")) {
            return null;
        }

        String[] parts = pointer.substring(1).split("/");
        JsonElement current = json;

        for (String part : parts) {
            if (current == null || !current.isJsonObject()) {
                return null;
            }
            current = current.getAsJsonObject().get(part);
        }

        if (current != null && current.isJsonPrimitive()) {
            return current.getAsString();
        }

        return null;
    }

    /**
     * Extract token duration from response.
     * Checks: expires_in (seconds), expiresIn (seconds), exp (unix timestamp)
     */
    private long extractDuration(JsonObject json) {
        // Check expires_in or expiresIn (seconds)
        for (String field : Arrays.asList("expires_in", "expiresIn")) {
            if (json.has(field)) {
                JsonElement elem = json.get(field);
                if (elem.isJsonPrimitive() && elem.getAsJsonPrimitive().isNumber()) {
                    return elem.getAsLong();
                }
            }
        }

        // Check exp (unix timestamp)
        if (json.has("exp")) {
            JsonElement elem = json.get("exp");
            if (elem.isJsonPrimitive() && elem.getAsJsonPrimitive().isNumber()) {
                long expTimestamp = elem.getAsLong();
                long now = Instant.now().getEpochSecond();
                return Math.max(0, expTimestamp - now);
            }
        }

        return DEFAULT_DURATION;
    }

    /**
     * Merge user config with template (user values take precedence).
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> mergeWithTemplate(Map<String, Object> user, Map<String, Object> template) {
        Map<String, Object> merged = new LinkedHashMap<>(template);

        for (Map.Entry<String, Object> entry : user.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();

            if ("loginEndpointAuth".equals(key) && merged.containsKey("loginEndpointAuth")) {
                // Deep merge loginEndpointAuth
                Map<String, Object> mergedLogin = new LinkedHashMap<>(
                        getMapOrEmpty(merged, "loginEndpointAuth"));
                
                if (value instanceof Map) {
                    Map<String, Object> userLogin = (Map<String, Object>) value;
                    for (Map.Entry<String, Object> loginEntry : userLogin.entrySet()) {
                        String loginKey = loginEntry.getKey();
                        Object loginValue = loginEntry.getValue();

                        if ("token".equals(loginKey) && mergedLogin.containsKey("token")) {
                            // Deep merge token config
                            Map<String, Object> mergedToken = new LinkedHashMap<>(
                                    getMapOrEmpty(mergedLogin, "token"));
                            if (loginValue instanceof Map) {
                                mergedToken.putAll((Map<String, Object>) loginValue);
                            }
                            mergedLogin.put("token", mergedToken);
                        } else if (loginValue != null) {
                            mergedLogin.put(loginKey, loginValue);
                        }
                    }
                }
                merged.put("loginEndpointAuth", mergedLogin);
            } else if ("signupEndpoint".equals(key) && merged.containsKey("signupEndpoint")) {
                // Deep merge signupEndpoint (template defaults + user overrides)
                Map<String, Object> mergedSignup = new LinkedHashMap<>(
                        getMapOrEmpty(merged, "signupEndpoint"));
                if (value instanceof Map) {
                    mergedSignup.putAll((Map<String, Object>) value);
                }
                merged.put("signupEndpoint", mergedSignup);
            } else if (value != null) {
                merged.put(key, value);
            }
        }

        return merged;
    }

    /**
     * Helper to safely get a Map from config, returning empty map if null.
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> getMapOrEmpty(Map<String, Object> config, String key) {
        Object value = config.get(key);
        if (value instanceof Map) {
            return (Map<String, Object>) value;
        }
        return Collections.emptyMap();
    }

    /**
     * Join base URL and endpoint path.
     */
    private String joinUrl(String baseUrl, String endpoint) {
        if (baseUrl.endsWith("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }
        if (!endpoint.startsWith("/")) {
            endpoint = "/" + endpoint;
        }
        return baseUrl + endpoint;
    }
}

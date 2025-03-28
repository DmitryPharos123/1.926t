/**
 * Copyright (C) 2024 Pharos AI, Inc.
 *
 * This file is part of Pharos Triton.
 *
 * Pharos Triton is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License.
 * See LICENSE file or go to https://github.com/Pharos-AI/triton/blob/main/LICENSE.
 */

/**
 * TritonHelper provides utility methods and builder classes for the Triton logging framework.
 * This class includes functionality for:
 * - Log level management and comparison
 * - UUID generation for transaction tracking
 * - HTTP request/response JSON serialization for integration logging
 * - Pre and post-processing controls for Pharos logging configuration
 * - Message formatting utilities
 * 
 * The class serves as a central utility hub for the Triton logging system, offering
 * helper methods and builder patterns to configure and enhance logging capabilities.
 */
public with sharing class TritonHelper {

    /**
    * Creates a key for log level based on:
    * @param category -- log category field
    * @param tye -- log type field
    * @param area -- log functional area field
    * @return -- a string with values in the following format: Category:{0};Type:{1};Area:{2}
    */
    public static String buildLogLevelKey(String category, String type, String area) {
        return String.format('Category:{0};Type:{1};Area:{2}', new String[]{category, type, area});
    }

    /**
    * Compares 2 log levels.
    * @param value -- this is the value compared against
    * @param toCompare -- comparison performed against this value
    * @return -- if value is higher than toCompare returns false, otherwise true
    */
    public static Boolean compareLevel(TritonTypes.Level value, TritonTypes.Level toCompare) {
        return value.ordinal() >= toCompare.ordinal();
    }

    /**
     * Generates a UUID.
     * Used to create a transaction Id
     */
    public static String generateUUID4() {
        String h = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        return 
            h.substring(0,8) +
            '-' +
            h.substring(8,12) +
            '-' +
            h.substring(12,16) +
            '-' +
            h.substring(16,20) +
            '-' +
            h.substring(20);
    }

    /**
    * Json serialization for http request and response objects.
    * Used by integration logs.
    */
    public static String toJson(RestRequest request, RestResponse response) {
        return JSON.serialize(new TritonHelper.IntegrationWrapper(
            new pharos.HttpRequestWrapper(request).formatRequest(),
            new pharos.HttpResponseWrapper(response).formatResponse()
        ));
    }

    public static String toJson(HttpRequest request, HttpResponse response) {
        return JSON.serialize(new TritonHelper.IntegrationWrapper(
            new pharos.HttpRequestWrapper(request).formatRequest(),
            new pharos.HttpResponseWrapper(response).formatResponse()
        ));
    }

    /**
    * Wrapper class for integration logs
    * Used to create the Json structure that combines http objects
    */
    public class IntegrationWrapper {
        public Map<String, Object> request;
        public Map<String, Object> response;
        public IntegrationWrapper(Map<String, Object> request, Map<String, Object> response) {
            this.request = request;
            this.response = response;
        }
    }

    /**
     * Builder class for constructing Pharos pre processing settings
     */
    public class PreProcessingControlsBuilder {
    }


    /**
     * Builder class for constructing Pharos post processing settings
     */
    public class PostProcessingControlsBuilder {

        private final Map<String, Boolean> controls;

        private final String AUDIT_TRAIL_KEY = 'auditTrail';
        private final String DEPLOY_RESULT_KEY = 'deployResult';
        private final String INSTALLED_PACKAGES_KEY = 'installedPackages';
        private final String AREA_KEY = 'objectInfo';
        private final String PENDING_JOBS_KEY = 'pendingJobs';
        private final String RELATED_OBJECTS_KEY = 'relatedObjects';
        private final String STACK_TRACE_KEY = 'stackTrace';
        private final String TOTAL_ACTIVE_SESSION_KEY = 'totalActiveSession';
        private final String USER_INFO_KEY = 'userInfo';
        

        public PostProcessingControlsBuilder() {
            controls = new Map<String, Boolean>{
                    AUDIT_TRAIL_KEY => false,
                    DEPLOY_RESULT_KEY => false,
                    INSTALLED_PACKAGES_KEY => false,
                    AREA_KEY => false,
                    PENDING_JOBS_KEY => false,
                    RELATED_OBJECTS_KEY => false,
                    STACK_TRACE_KEY => false,
                    TOTAL_ACTIVE_SESSION_KEY => false,
                    USER_INFO_KEY => false
            };
        }

        /**
         * Controls whether Pharos fetches recent audit trail
         */
        public PostProcessingControlsBuilder auditTrail(Boolean value) {
            controls.put(AUDIT_TRAIL_KEY, value);
            return this;
        }

        /**
         * Returns a Json version of the settings
         */
        public String build() {
            return JSON.serialize(controls);
        }

        /**
         * Controls whether Pharos fetches recent deployments
         */
        public PostProcessingControlsBuilder deployResult(Boolean value) {
            controls.put(DEPLOY_RESULT_KEY, value);
            return this;
        }

        /**
         * Controls whether Pharos fetches the number of currently installed packages
         */
        public PostProcessingControlsBuilder installedPackages(Boolean value) {
            controls.put(INSTALLED_PACKAGES_KEY, value);
            return this;
        }
        
        /**
         * Controls whether Pharos automatically sets functional area
         */
        public PostProcessingControlsBuilder area(Boolean value) {
            controls.put(AREA_KEY, value);
            return this;
        }

        /**
         * Controls whether Pharos fetches jobs currently in the flox queue
         */
        public PostProcessingControlsBuilder pendingJobs(Boolean value) {
            controls.put(PENDING_JOBS_KEY, value);
            return this;
        }

        /**
         * Controls whether Pharos fetches related objects names
         */
        public PostProcessingControlsBuilder relatedObjects(Boolean value) {
            controls.put(RELATED_OBJECTS_KEY, value);
            return this;
        }

        /**
         * Sets all flags to the value provided
         */
        public PostProcessingControlsBuilder setAll(Boolean value) {
            for (String key : controls.keySet()) {
                controls.put(key, value);
            }
            return this;
        }

        /**
         * Controls whether stack trace is enhanced by Pharos
         * Only applicable to Apex and Integration logs
         */
        public PostProcessingControlsBuilder stackTrace(Boolean value) {
            controls.put(STACK_TRACE_KEY, value);
            return this;
        }
        
        /**
         * Controls whether Pharos fetches User name
         */
        public PostProcessingControlsBuilder userInfo(Boolean value) {
            controls.put(USER_INFO_KEY, value);
            return this;
        }

        /**
         * Controls whether Pharos fetches the number of currently logged in users
         */
        public PostProcessingControlsBuilder totalActiveSession(Boolean value) {
            controls.put(TOTAL_ACTIVE_SESSION_KEY, value);
            return this;
        }
    }    

    /**
     * Formats a message by replacing {0} placeholder with the provided parameter
     * @param template The message template containing {0} placeholder
     * @param param The parameter to replace the placeholder with
     * @return Formatted message
     */
    public static String formatMessage(String template, String param) {
        return String.format(template, new List<String>{param});
    }

    /**
     * Formats a message by replacing {0}, {1}, etc. placeholders with the provided parameters
     * @param template The message template containing numbered placeholders
     * @param params The list of parameters to replace the placeholders with
     * @return Formatted message
     */
    public static String formatMessage(String template, List<String> params) {
        return String.format(template, params);
    }
}
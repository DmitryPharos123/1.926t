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
 * Provides logging capabilities for Salesforce Flows and Process Builder.
 * This class exposes an invocable method that can be called directly from Flow Builder
 * to create log records with customizable attributes like category, type, area, and level.
 * 
 * The class handles:
 * - Log creation with default INFO level if not specified
 * - Automatic transaction management
 * - Custom field mapping through JSON
 * - Flow context capture (Interview GUID, Flow API Name)
 * - Validation and fallback for category and log level enums
 */
public with sharing class TritonFlow {
    private static final String INVALID_LOG_LEVEL = 'Unable to locate log level: {0}. Default INFO level will be used.';
    private static final String INVALID_CATEGORY = 'Unable to locate category: {0}. Default Flow category will be used.';
    
    /**
     * @description
     * Invocable method, that can be called via flow.
     * Defaults to INFO log level
     * @param flowLogs The list of FlowLog instances to save
     */
    @InvocableMethod(Category='TritonLogging' Label='Add Log' Description='Creates a log for a flow or process builder')
    public static void log(List<FlowLog> flowLogs) {
        for (FlowLog flowLog : flowLogs) {
            processFlowLog(flowLog);
        }
        Triton.instance.flush();
    }
    
    private static void processFlowLog(FlowLog flowLog) {
        TritonTypes.Level level = TritonTypes.Level.INFO;
        String flowDetails = flowLog.details;
        try {
            level = TritonTypes.Level.valueOf(flowLog.level);
        } catch (Exception e) {
            flowDetails += Triton.SPACE_SEP + TritonHelper.formatMessage(INVALID_LOG_LEVEL, flowLog.level);
        }
        
        TritonTypes.Category category = TritonTypes.Category.Flow;
        try {
            category = TritonTypes.Category.valueOf(flowLog.category);
        } catch (Exception e) {
            flowDetails += Triton.SPACE_SEP + TritonHelper.formatMessage(INVALID_CATEGORY, flowLog.category);
        }
        
        //start transaction if one isn't already in progress
        if(Triton.instance.TRANSACTION_ID == null) Triton.instance.startTransaction();
        
        TritonBuilder builder = Triton.makeBuilder();
        builder
                .category(category)
                .type(flowLog.type)
                .area(flowLog.area)
                .summary(flowLog.summary)
                .details(flowDetails)
                .transactionId(Triton.instance.TRANSACTION_ID)
                .interviewGuid(flowLog.interviewGUID)
                .flowApiName(flowLog.flowApiName)
                .level(level);

        if (String.isNotBlank(flowLog.additionalFields)) {
            try {
                Map<String, Object> mapAdditionalFields = (Map<String, Object>)JSON.deserializeUntyped(flowLog.additionalFields);
                for (String field : mapAdditionalFields.keySet()) {
                    builder.attribute(field, mapAdditionalFields.get(field));
                }
            } catch (Exception e) {
                builder.details(flowDetails + Triton.SPACE_SEP + 
                    TritonHelper.formatMessage(
                        'Additional Information (failed to parse json input to invokable): {0}', 
                        flowLog.additionalFields));
            }
        }
        Triton.instance.add(builder.build());
    }


    /**
     * A wrapper class for passing log data from flow
     */
    public class FlowLog {
        @InvocableVariable(Required=true Label='Category')
        public String category;
        @InvocableVariable(Required=true Label='Type')
        public String type;
        @InvocableVariable(Required=true Label='Area')
        public String area;
        @InvocableVariable(Required=true Label='Summary')
        public String summary;
        @InvocableVariable(Required=true Label='Details')
        public String details;
        @InvocableVariable(Required=true Label='Interview GUID')
        public String interviewGUID;
        @InvocableVariable(Required=false Label='Flow API Name')
        public String flowApiName;
        @InvocableVariable(Required=false Label='Level')
        public String level;
        @InvocableVariable(Required=false Label='Additional Fields')
        public String additionalFields;
    }
}
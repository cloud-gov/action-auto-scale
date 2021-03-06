#!/bin/bash

# Authenticate and target CF org and space.
cf api "$INPUT_CF_API"
cf auth "$INPUT_CF_USERNAME" "$INPUT_CF_PASSWORD"
cf target -o "$INPUT_CF_ORG" -s "$INPUT_CF_SPACE"

# Get app details.
GUID=$(cf app "$INPUT_CF_APP_NAME" --guid)
STATS=$(cf curl "/v2/apps/$GUID/stats")
NUM_INSTANCES=$(echo $STATS | jq '. | length')

# Calculate average memory utilization across app inatances.
COUNT=0;
TOTAL=0; 
for i in $(echo $STATS | jq '.[] | (.stats.usage.mem /.stats.mem_quota)*100')
    do
        TOTAL=$(echo $TOTAL+$i | bc )
        ((COUNT++))
    done
AVG_MEM_UTILIZATION=$(echo "scale=2; $TOTAL / $COUNT" | bc | awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')

# If average utilization is above max threshold, scale up.
if  [ $AVG_MEM_UTILIZATION -ge "$INPUT_CF_APP_MAX_THRESHOLD" ] ; then
    echo "Average memory utilization across instances is approximately $AVG_MEM_UTILIZATION%."
    echo "Scaling UP"
    cf scale "$INPUT_CF_APP_NAME" -i $((NUM_INSTANCES+INPUT_CF_INSTANCE_INCREMENT))
fi

# If average utilization is below min threshold, scale down.
if  [ $AVG_MEM_UTILIZATION -le "$INPUT_CF_APP_MIN_THRESHOLD" ] ; then
    echo "Average memory utilization across instances is approximately $AVG_MEM_UTILIZATION%."
    if [ $NUM_INSTANCES -gt 1 ]; then
        echo "Scaling DOWN"
        cf scale "$INPUT_CF_APP_NAME" -i $((NUM_INSTANCES-INPUT_CF_INSTANCE_INCREMENT))
    else 
        echo "No scaling changes needed."
    fi
fi

# Display number of instances.
NEW_INSTANCE_COUNT=$(cf curl "/v2/apps/$GUID/stats" | jq '. | length')
if [ $NUM_INSTANCES -eq 1 ]; then
    echo "Number of instances remains $NUM_INSTANCES"
else 
    echo "Number of instances changed from $NUM_INSTANCES to $NEW_INSTANCE_COUNT"
fi
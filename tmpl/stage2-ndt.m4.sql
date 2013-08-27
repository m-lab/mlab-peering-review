SELECT 
    INTEGER(log_time)           AS day_timestamp,
    connection_spec.server_ip   AS server_ip,
    connection_spec.client_ip   AS client_ip,
    test_id                     AS test_id
FROM 
    DATETABLE
WHERE
        IS_EXPLICITLY_DEFINED(project)
    -- traceroute traffic
    AND project = 3
    -- restrict to NY servers, and given filters ranges.
    AND connection_spec.server_ip IN(SERVERIPS)
    AND include(STAGE2_FILTER_FILENAME)
GROUP BY
    day_timestamp, server_ip, client_ip, test_id
ORDER BY 
    day_timestamp, server_ip, client_ip, test_id;


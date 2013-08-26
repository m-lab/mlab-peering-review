SELECT 
    INTEGER(web100_log_entry.log_time)                  AS day_timestamp,
    web100_log_entry.connection_spec.local_ip           AS server_ip,
    web100_log_entry.connection_spec.remote_ip          AS client_ip,
    test_id                                             AS test_id
FROM 
    DATETABLE
WHERE
        IS_EXPLICITLY_DEFINED(project)
    AND IS_EXPLICITLY_DEFINED(connection_spec.data_direction)
    AND IS_EXPLICITLY_DEFINED(web100_log_entry.is_last_entry)
    AND IS_EXPLICITLY_DEFINED(web100_log_entry.snap.HCThruOctetsAcked)
    AND IS_EXPLICITLY_DEFINED(web100_log_entry.snap.CongSignals)
    AND IS_EXPLICITLY_DEFINED(web100_log_entry.connection_spec.remote_ip)
    AND IS_EXPLICITLY_DEFINED(web100_log_entry.connection_spec.local_ip)
    -- traceroute traffic
    AND project = 3
    -- restrict to NY servers, and given filters ranges.
    AND web100_log_entry.connection_spec.local_ip IN(SERVERIPS)
    AND ( include(STAGE2_FILTER_FILENAME) )
ORDER BY 
    day_timestamp, server_ip, client_ip;


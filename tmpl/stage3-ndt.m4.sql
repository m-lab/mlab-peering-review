SELECT 
    INTEGER(log_time)            AS day_timestamp,
    connection_spec.server_ip    AS server_ip,
    connection_spec.client_ip    AS client_ip,
    paris_traceroute_hop.src_ip  AS hop_src_ip,
    paris_traceroute_hop.dest_ip AS hop_dest_ip,
    test_id                      AS test_id
FROM
    DATETABLE
WHERE
        IS_EXPLICITLY_DEFINED(project)
    -- traceroute traffic
    AND project = 3
    -- restrict to NY servers, and given filters ranges.
    AND connection_spec.server_ip IN(SERVERIPS)
    AND include(STAGE3_FILTER_FILENAME)
ORDER BY
    day_timestamp, test_id, server_ip, client_ip;


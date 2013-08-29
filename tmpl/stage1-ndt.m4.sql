SELECT 
    INTEGER(web100_log_entry.log_time)                  AS day_timestamp,
    web100_log_entry.connection_spec.local_ip           AS server_ip,
    web100_log_entry.connection_spec.remote_ip          AS client_ip,

    -- RATE
    8*web100_log_entry.snap.HCThruOctetsAcked/(
                     web100_log_entry.snap.SndLimTimeRwin +
                     web100_log_entry.snap.SndLimTimeCwnd +
                     web100_log_entry.snap.SndLimTimeSnd) AS raw_download_rate,
    -- RETRANSMISSION
    -- (web100_log_entry.snap.OctetsRetrans/web100_log_entry.snap.DataOctetsOut)  AS raw_retrans,
    -- TODO: maybe network or client or server-limited time ratios?
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
    -- NDT download
    AND project = 0
    AND connection_spec.data_direction = 1
    AND web100_log_entry.is_last_entry = True
    AND web100_log_entry.snap.HCThruOctetsAcked >= 8192 
    AND web100_log_entry.snap.HCThruOctetsAcked < 1000000000
    AND web100_log_entry.snap.CongSignals > 0
    AND (web100_log_entry.snap.SndLimTimeRwin +
         web100_log_entry.snap.SndLimTimeCwnd +
         web100_log_entry.snap.SndLimTimeSnd) >= 9000000
    AND (web100_log_entry.snap.SndLimTimeRwin +
         web100_log_entry.snap.SndLimTimeCwnd +
         web100_log_entry.snap.SndLimTimeSnd) < 3600000000
    AND web100_log_entry.snap.MinRTT < 1e7
    -- restrict to NY lga01 servers, and given ISP address ranges.
    AND web100_log_entry.connection_spec.local_ip IN(SERVERIPS)
    AND ( include(ISP_FILTER_FILENAME) )
ORDER BY 
    day_timestamp, server_ip, client_ip;


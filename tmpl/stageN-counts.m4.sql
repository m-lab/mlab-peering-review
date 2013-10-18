-- count the number of tests less than a certain threshold rate.
SELECT 
       COUNT(*)                      as SITE_total_count,
       SUM( CASE WHEN (8*web100_log_entry.snap.HCThruOctetsAcked/(
                         web100_log_entry.snap.SndLimTimeRwin +
                         web100_log_entry.snap.SndLimTimeCwnd +
                         web100_log_entry.snap.SndLimTimeSnd) < 30)
                 THEN 1 ELSE 0 END ) as SITE_30_count,
       SUM( CASE WHEN (8*web100_log_entry.snap.HCThruOctetsAcked/(
                         web100_log_entry.snap.SndLimTimeRwin +
                         web100_log_entry.snap.SndLimTimeCwnd +
                         web100_log_entry.snap.SndLimTimeSnd) < 40)
                 THEN 1 ELSE 0 END ) as SITE_40_count,
       SUM( CASE WHEN (8*web100_log_entry.snap.HCThruOctetsAcked/(
                         web100_log_entry.snap.SndLimTimeRwin +
                         web100_log_entry.snap.SndLimTimeCwnd +
                         web100_log_entry.snap.SndLimTimeSnd) < 50)
                 THEN 1 ELSE 0 END ) as SITE_50_count,
       SUM( CASE WHEN (8*web100_log_entry.snap.HCThruOctetsAcked/(
                         web100_log_entry.snap.SndLimTimeRwin +
                         web100_log_entry.snap.SndLimTimeCwnd +
                         web100_log_entry.snap.SndLimTimeSnd) < 60)
                 THEN 1 ELSE 0 END ) as SITE_60_count,
       SUM( CASE WHEN (8*web100_log_entry.snap.HCThruOctetsAcked/(
                         web100_log_entry.snap.SndLimTimeRwin +
                         web100_log_entry.snap.SndLimTimeCwnd +
                         web100_log_entry.snap.SndLimTimeSnd) < 80)
                 THEN 1 ELSE 0 END ) as SITE_80_count,
       SUM( CASE WHEN (8*web100_log_entry.snap.HCThruOctetsAcked/(
                         web100_log_entry.snap.SndLimTimeRwin +
                         web100_log_entry.snap.SndLimTimeCwnd +
                         web100_log_entry.snap.SndLimTimeSnd) < 100)
                 THEN 1 ELSE 0 END ) as SITE_100_count,
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
    -- restrict to servers, and given ISP address ranges.
    AND web100_log_entry.connection_spec.local_ip IN(SERVERIPS)
    AND ( include(ISP_FILTER_FILENAME) )


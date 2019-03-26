alter session set current_schema = solife_it0_ods;
set timing on;
set echo on;
set termout on;
BEGIN
    FOR rec IN(
        SELECT /*+ gather_plan_statistics */
            endpol_light.technicalidentifier   AS endpol_light_tid,
            endpol_light.pol_number,
            endpol_light.end_number,
            endpol_light.full_previous_tid     AS endpol_light_fullprev_tid,
            '>' AS c,
            endpol_incr.technicalidentifier    AS endpol_incr_tid,
            endpol_incr.full_previous_tid      AS endpol_incr_fullprev_tid
        FROM
            endpolicy endpol_light
            JOIN endpolicy endpol_incr ON(endpol_incr.technicalidentifier = endpol_light.full_previous_tid)
        WHERE
            endpol_light.ods$current_version = 'Y'
            AND endpol_incr.ods$current_version = 'Y'
            AND endpol_light.technicalidentifier LIKE '45034:%'
            AND endpol_light.full_previous_tid NOT LIKE '6601:%'
    )LOOP
--
        UPDATE endpolicy
        SET
            full_previous_tid = rec.endpol_incr_fullprev_tid
        WHERE
            endpolicy.technicalidentifier = rec.endpol_light_tid
            AND endpolicy.ods$current_version = 'Y';
--

    END LOOP;

    commit;
--  ROLLBACK;
    
END;
/
l
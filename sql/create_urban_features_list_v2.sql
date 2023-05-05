--Multicity structural Connectivity Project (MCSC)
-- 2023-05-04
-- Code Authors:
-- Tiziana Gelmi-Candusso, Peter Rodriguez

-- Main aim: Union all SQL VIEWS to create a master list of study-wide features. Ontario is the reference. 
--    Run this script in the local postgres db that only has planet data for Ontario.


DROP TABLE IF EXISTS urban_features_v1;

CREATE TABLE urban_features_v1 AS

SELECT DISTINCT feature, type, material, size, pri, view, row_number() OVER (ORDER BY view, feature) AS rid
FROM
(
-- water
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'water' AS view FROM water
)
UNION ALL
-- waterways
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'waterways_bf' AS view FROM waterways_bf
)
UNION ALL
--barrier
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,'barrier_bf' AS view FROM barrier_bf
)
UNION ALL
--roads no traffic
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_no_traffic_bf' AS view FROM lf_roads_no_traffic_bf
)
UNION ALL
--roads no traffic sidewalks
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_no_traffic_bf_sidewalks' AS view FROM lf_roads_no_traffic_bf_sidewalks
)
--roads very low traffic
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_very_low_traffic_bf' AS view FROM lf_roads_very_low_traffic_bf
)
-- roads low traffic
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_low_traffic_bf' AS view FROM lf_roads_low_traffic_bf
)
-- roads medium traffic
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_medium_traffic_bf' AS view FROM lf_roads_medium_traffic_bf
)
-- roads high traffic high speed
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_high_traffic_hs_bf' AS view FROM lf_roads_high_traffic_hs_bf
)
-- roads high traffic low speed
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_high_traffic_ls_bf' AS view FROM lf_roads_high_traffic_ls_bf
)
--roads very high traffic
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_very_high_traffic_bf' AS view FROM lf_roads_very_high_traffic_bf
)
--roads unclassified
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_roads_unclassified_bf' AS view FROM lf_roads_unclassified_bf
)
UNION ALL
--railways
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_rails_bf' AS view FROM lf_rails_bf
)
UNION ALL
--railways_trams
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_rails_bf_trams' AS view FROM lf_rails_bf_trams
)
UNION ALL
--railways_abandoned
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'lf_rails_bf_abandoned' AS view FROM lf_rails_bf_abandoned
)
UNION ALL
-- parking_surface
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric, 'parking_surface' AS view FROM parking_surface 
)
UNION ALL
--buildings
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'buildings' AS view FROM buildings
)
UNION ALL
-- resourceful_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'resourceful_green' AS view FROM resourceful_green
)
UNION ALL
-- dense_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'dense_green' AS view FROM dense_green
)
UNION ALL
-- hetero_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'hetero_green' AS view FROM hetero_green
)
UNION ALL
-- bare_soil
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'bare_soil' AS view FROM bare_soil
)
UNION ALL
-- open_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,   'open_green' AS view FROM open_green
)
UNION ALL
-- protected area
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,   'protected_area' AS view FROM protected_area
)
UNION ALL
-- residential
(SELECT  feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'residential' AS view FROM residential
)
UNION ALL
--institutional
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'institutional' AS view FROM institutional
)
UNION ALL
-- industrial
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'industrial' AS view FROM industrial
)UNION ALL
-- commercial
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,  'commercial' AS view FROM commercial
)
UNION ALL
-- railway_landuse
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, pri::numeric,   'railway_landuse' AS view FROM railway_landuse
)

) t1
;

ALTER TABLE urban_features_v1 ADD CONSTRAINT urban_features_v1_pkey PRIMARY KEY (rid);

COMMENT ON TABLE urban_features_v1 IS 'Master list of features defined for Ontario. This list will be used as the references for the study. [2023-04-17]';

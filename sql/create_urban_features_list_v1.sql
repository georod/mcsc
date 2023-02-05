--Multicity structural Connectivity Project (MCSC)
-- 2023-02-03
-- This is version: create_urban_features_list_v3/v4.sql
-- Code Authors:
-- Tiziana Gelmi-Candusso, Peter Rodriguez

-- Main aim: Union all SQL VIEWS to create a master list of study-wide features. Ontario is the reference. 
--    Run this script in the local postgres db that only has planet data for Ontario.


--DROP TABLE IF EXISTS urban_features_v1;

CREATE TABLE urban_features_v2 AS

SELECT DISTINCT feature, type, material, size, view, row_number() OVER (ORDER BY view, feature) AS rid
FROM
(
-- water
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'water' AS view FROM water
)
UNION ALL
--barrier
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'barrier_bf' AS view FROM barrier_bf
)
UNION ALL
--roads
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_notraffic_bf' AS view FROM lf_roads_notraffic_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_very_low_traffic_bf' AS view FROM lf_roads_very_low_traffic_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_low_traffic_bf' AS view FROM lf_roads_low_traffic_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_medium_traffic_bf' AS view FROM lf_roads_medium_traffic_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_high_traffic_hs_bf' AS view FROM lf_roads_high_traffic_hs_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_high_traffic_ls_bf' AS view FROM lf_roads_high_traffic_ls_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_very_high_traffic_bf' AS view FROM lf_roads_very_high_traffic_bf
)
UNION ALL
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_roads_unclassified_bf' AS view FROM lf_roads_unclassified_bf
)
UNION ALL
--railways
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 'lf_rails_bf' AS view FROM lf_rails_bf
)
UNION ALL
-- parking_surface
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'parking_surface' AS view FROM parking_surface 
)
UNION ALL
--buildings
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'buildings' AS view FROM buildings
)
UNION ALL
-- resourceful_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'resourceful_green' AS view FROM resourceful_green
)
UNION ALL
-- dense_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'dense_green' AS view FROM dense_green
)
UNION ALL
-- hetero_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'hetero_green' AS view FROM hetero_green
)
UNION ALL
-- open_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric,  'open_green' AS view FROM open_green
)
UNION ALL
-- residential
(SELECT  feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'residential' AS view FROM residential
)
UNION ALL
--institutional
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric, 'institutional' AS view FROM institutional
)
UNION ALL
-- commercial_industrial
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric,  'commercial_industrial' AS view FROM commercial_industrial
)
-- railway_landuse
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::numeric,  'railway_landuse' AS view FROM commercial_industrial
)
--UNION ALL
--background_layer3
--(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 1::smallint AS priority, 'background_layer3' AS view FROM background_layer3
--)
) t1
;

ALTER TABLE urban_features_v2 ADD CONSTRAINT urban_features_v2_pkey PRIMARY KEY (rid);

COMMENT ON TABLE urban_features_v2 IS 'Master list of features defined for Ontario. This list will be used as the references for the study. [2023-01-30]';
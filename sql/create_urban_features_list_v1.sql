--Multicity structural Connectivity Project (MCSC)
-- 2023-01-05
-- Code Authors:
-- Tiziana Gelmi-Candusso, Peter Rodriguez

-- Main aim: Unnion all SQL VIEWS to create a master list of study-wide features. Ontario is the reference


--DROP TABLE IF EXISTS urban_features_v1;

CREATE TABLE urban_features_v1 AS

SELECT DISTINCT feature, type, material, size, priority, view, row_number() OVER (ORDER BY priority, feature) AS rid
FROM
(
-- water
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 12::smallint AS priority, 'water' AS view FROM water
)
UNION ALL
--barrier
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 14::smallint AS priority, 'barrier_bf' AS view FROM barrier
)
UNION ALL
--railways
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::varchar(10), 15::smallint AS priority, 'lf_rails_bf' AS view FROM lf_rails
)
UNION ALL
--roads
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size::varchar(10), 13::smallint AS priority, 'lf_roads_bf' AS view FROM lf_roads
)
UNION ALL
-- parking_surface
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 11::smallint AS priority, 'parking_surface' AS view FROM parking_surface
)
UNION ALL
--buildings
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 10::smallint AS priority, 'buildings' AS view FROM buildings
)
UNION ALL
-- resourceful_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 9::smallint AS priority, 'resourceful_green' AS view FROM resourceful_green
)
UNION ALL
-- dense_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 8::smallint AS priority, 'dense_green' AS view FROM dense_green
)
UNION ALL
-- hetero_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 7::smallint AS priority, 'hetero_green' AS view FROM hetero_green
)
UNION ALL
-- open_green
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 6::smallint AS priority, 'open_green' AS view FROM open_green
)
UNION ALL
--landuse_park
(SELECT  feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 5::smallint AS priority, 'landuse_park' AS view FROM landuse_park
)
UNION ALL
-- residential
(SELECT  feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 4::smallint AS priority, 'residential' AS view FROM residential
)
UNION ALL
--institutional
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 3::smallint AS priority, 'institutional' AS view FROM institutional
)
UNION ALL
-- commercial_industrial
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 2::smallint AS priority, 'commercial_industrial' AS view FROM commercial_industrial
)
UNION ALL
--background_layer3
(SELECT feature, CASE WHEN type is null then 'NULL' else type END AS type, material, size, 1::smallint AS priority, 'background_layer3' AS view FROM background_layer3
)
) t1
;

ALTER TABLE urban_features_v1 ADD CONSTRAINT urban_features_v1_pkey PRIMARY KEY (rid);

COMMENT ON TABLE urban_features_v1 IS 'Master list of features defined for Ontario. This list will be used as the references for the study. [2023-01-05]';

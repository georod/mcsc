--Multicity structural Connectivity Project (MCSC)
-- 2022-12-19
-- Code Authors:
-- Tiziana Gelmi-Candusso, Peter Rodriguez

-- Main aim: Create SQL VIEWS for all relevant OSM (Open Street Map) features

-- Note: This version also create buffers for linear features to help processing

DROP VIEW IF EXISTS buildings;
CREATE OR REPLACE VIEW buildings AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'building'::varchar(30) AS feature,
	tags->>'building'::varchar(30) AS type,
	''::varchar(30) AS material,
	tags->>'height' AS size, --has feet and meter, a bit of a mess tbh, do not use
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'building' <>'' or tags->>'building' IN ('parking','industrial', 'school', 'commercial', 'terrace', 'detached', 'semideatched_house', 'house', 'retail', 'hotel', 'apartments') or tags->> 'amenity' IN ('school', 'fast_food', 'clinic', 'theatre', 'conference_center', 'hospital', 'place_of_worship', 'police')
	;

COMMENT ON VIEW buildings  IS 'OSM buildings spatial layer. [2022-12-19]';

DROP VIEW IF EXISTS lf_roads;
CREATE OR REPLACE VIEW lf_roads AS
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
CASE
WHEN size = '22' THEN '2'
WHEN size = '2;1' THEN '1'
WHEN size = '2; 1' THEN '1'
WHEN size = '2;3' THEN '2'
WHEN size = '10' THEN '1'
WHEN size = '1; 2' THEN '1'
WHEN size = '1;2' THEN '1'
ELSE size
END::numeric(3,1) AS size, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id, feature, type, material,
	REPLACE(size, '-', '') AS size,
 geom
FROM
(
SELECT way_id,  
	'linear_feature' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	tags ->> 'lanes' AS size,
	geom AS geom
    FROM lines WHERE tags->>'highway' <>'' or tags ->> 'highway' IN ('residential','footway', 'primary', 'motorway', 'secondary')
		) t1
	) t2
	;

DROP VIEW IF EXISTS lf_roads_bf;
CREATE OR REPLACE VIEW lf_roads_bf AS
--roads
(SELECT sid, way_id as osm_id, feature, type, material, size::varchar(10), 13::smallint AS priority, 
 st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom FROM lf_roads
);


DROP VIEW IF EXISTS lf_rails;
CREATE OR REPLACE VIEW lf_rails AS
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
CASE
WHEN type = 'rail' THEN 2
WHEN type = 'proposed' THEN 0
ELSE 1
END::smallint AS size, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id, feature, type, material,
	REPLACE(size, '-', '') AS size,
 geom
FROM
(
SELECT way_id,  
	'linear_feature_rail' AS feature,
	tags->>'railway' AS type,
	'' AS material,
	'' AS size,
	geom  AS geom
    FROM lines WHERE tags->>'railway' NOT IN ('monorail','funicular','subway') or tags->> 'landuse' = 'railway'
		) t1
	) t2
	;


DROP VIEW IF EXISTS lf_rails_bf;
CREATE OR REPLACE VIEW lf_rails_bf AS
(SELECT sid, way_id as osm_id, feature, type, material, size::varchar(10), 15::smallint AS priority, 
 st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom FROM lf_rails
);


DROP VIEW IF EXISTS open_green;
CREATE OR REPLACE VIEW open_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'open_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse' IN ('grass', 'cemetery', 'greenfield', 'recreation_ground',  'winter_sports','brownfield', 'construction') or tags ->> 'natural' IN ('tundra') or tags->> 'golf'<>'rough' or tags->> 'highway'='construction'
	;

DROP VIEW IF EXISTS hetero_green;
CREATE OR REPLACE VIEW hetero_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'hetero_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'natural'IN('garden', 'scrub', 'sand', 'shrub') or  tags->> 'landuse'IN('plant_nursery', 'meadow',  'flowerbed') or tags->> 'meadow'<>'' or tags->> 'golf' = 'rough'
	;
	
DROP VIEW IF EXISTS dense_green;
CREATE OR REPLACE VIEW dense_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'dense_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'leaf_type'::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'IN('forest') or tags->>'natural'='wood' or tags ->> 'boundary' = 'forest'
	;

DROP VIEW IF EXISTS resourceful_green;
CREATE OR REPLACE VIEW resourceful_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'resourceful_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse' IN ('orchard','farmland', 'landfill','vineyard', 'farmyard','allotments')
	;

DROP VIEW IF EXISTS water;
CREATE OR REPLACE VIEW water AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'water'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'water'::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'='basin' or tags ->> 'natural' IN ('water', 'wetland') or tags ->> 'water' <>''
	;

DROP VIEW IF EXISTS parking_surface;
CREATE OR REPLACE VIEW parking_surface AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'parking_surface'::varchar(30) AS feature,
	tags->>'amenity'::varchar(30) AS type,
	''::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'parking'='surface'
	;

DROP VIEW IF EXISTS residential;
CREATE OR REPLACE VIEW residential AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'residential'::varchar(30) AS feature,
	tags->>'residential'::varchar(30) AS type,
	''::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'='residential'
	;
	
DROP VIEW IF EXISTS commercial_industrial;
CREATE OR REPLACE VIEW commercial_industrial AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'commercial_industrial'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'retail'::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'IN('commercial',  'retail', 'industrial')
	;

DROP VIEW IF EXISTS institutional;
CREATE OR REPLACE VIEW institutional AS	
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'institutional'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30)  AS type,
	''::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'IN('institutional',  'education', 'religious')
	;

DROP VIEW IF EXISTS barrier;
CREATE OR REPLACE VIEW barrier AS	
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20),  
	'barrier'::varchar(30) AS feature,
	tags->>'barrier'::varchar(30)  AS type,
	tags->>'fence_type'::varchar(30) AS material,
	tags->>'height'::varchar(30) AS size,
	geom AS geom
    FROM lines WHERE tags->>'barrier'<>''
	;


DROP VIEW IF EXISTS barrier_bf;
CREATE OR REPLACE VIEW barrier_bf AS	
(SELECT sid, way_id as osm_id, feature, type, material, size, 14::smallint AS priority, st_multi(st_buffer(geom, 1))::geometry('MultiPolygon', 3857) AS geom FROM barrier
);


DROP VIEW IF EXISTS landuse_park;
CREATE OR REPLACE VIEW landuse_park AS	
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'institutional'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30)  AS type,
	''::varchar(30) AS material,
	'' AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'IN('park', 'nature_reserve', 'natural_reserve', 'landscape_reserve') or tags ->> 'amenity' = 'park' or tags ->> 'leisure' IN ('park', 'nature_riserve', 'golf_course', 'marina', 'playground', 'sports_centre', 'stadium', 'pitch', 'picnic_table', 'pitch', 'dog_park', 'playground') or tags->> 'boundary'='protected_area' or tags ->> 'sport' = 'soccer' or tags ->> 'power' = 'substation' 
	;


DROP VIEW background_layer3;
CREATE OR REPLACE VIEW background_layer3 AS	
SELECT (row_number() OVER ())::int AS sid, relation_id::varchar(20),  
 	'background'::varchar(30) AS feature,
 	tags->>'name'::varchar(30)  AS type,
 	tags ->> 'admin_level'::varchar(30) AS material,
 	'' AS size,
 	st_multi(ST_BuildArea(geom))::geometry(Multipolygon, 3857) AS geom
 	FROM boundaries WHERE tags->> 'boundary'IN('administrative', 'political')
	;
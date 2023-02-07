--Multicity structural Connectivity Project (MCSC)
-- 2023-02-07
-- This is version create_urban_feature_layers_v4.sql
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
	NULL AS size, --has feet and meter, a bit of a mess tbh, do not use
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'building' <>'' or tags->>'building' IN ('parking','industrial', 'school', 'commercial', 'terrace', 'detached', 'semideatched_house', 'house', 'retail', 'hotel', 'apartments') or tags->> 'amenity' IN ('school', 'fast_food', 'clinic', 'theatre', 'conference_center', 'hospital', 'place_of_worship', 'police')
	;

COMMENT ON VIEW buildings  IS 'OSM buildings spatial layer. [2023-02-07]';


---Tiziana is creating more layers for the linear features, based on traffic load and human activity. 
--no traffic roads does not contian sidewalks
DROP VIEW IF EXISTS lf_roads_notraffic_bf;
CREATE OR REPLACE VIEW lf_roads_notraffic_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_no_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'footway' AS material,
	0.5 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('footway','construction','escape','cycleway','steps','bridleway','construction','path','pedestrian','track','abandoned') and 
	tags ->> 'footway' <> 'sidewalk'
		) t1
	) t2
	) t3
	; 

DROP VIEW IF EXISTS lf_roads_very_low_traffic_bf;
CREATE OR REPLACE VIEW lf_roads_very_low_traffic_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_vl_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	1 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('services','service','turning_loop','living_street')
		) t1
	) t2
	) t3
	; 

DROP VIEW IF EXISTS lf_roads_low_traffic_bf;
CREATE OR REPLACE VIEW lf_roads_low_traffic_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_l_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	2 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('residential', 'rest_area')
		) t1
	) t2
	) t3
	; 

DROP VIEW IF EXISTS lf_roads_medium_traffic_bf;
CREATE OR REPLACE VIEW lf_roads_medium_traffic_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_m_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	2 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('primary')
		) t1
	) t2
	) t3
	; 

DROP VIEW IF EXISTS lf_roads_high_traffic_hs_bf;
CREATE OR REPLACE VIEW lf_roads_high_traffic_hs_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_h_traffic_hs' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	6 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('tertiary', 'tertiary_link')
		) t1
	) t2
	) t3
	; 

DROP VIEW IF EXISTS lf_roads_high_traffic_ls_bf;
CREATE OR REPLACE VIEW lf_roads_high_traffic_ls_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_h_traffic_ls' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	3 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('secondary', 'secondary_link')
		) t1
	) t2
	) t3
	;

DROP VIEW IF EXISTS lf_roads_very_high_traffic_bf;
CREATE OR REPLACE VIEW lf_roads_very_high_traffic_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_vh_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	4 AS size,
	geom AS geom
    FROM lines WHERE tags ->> 'highway' IN ('motorway','motorway_link','trunk_link', 'trunk')
		) t1
	) t2
	) t3
	;

DROP VIEW IF EXISTS lf_roads_unclassified_bf;
CREATE OR REPLACE VIEW lf_roads_unclassified_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, geom 
FROM
(
SELECT way_id, feature, type, material,
size , (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_na_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'footway' AS material,
	2 AS size,
	geom AS geom
    FROM lines WHERE tags->>'highway' <>'' AND tags ->> 'highway' NOT IN (
        'footway','construction','escape','cycleway','steps','bridleway','construction','path','pedestrian','track','abandoned',
    'turning_loop','living_street',
	'service','services',
    'residential', 'rest_area',
    'primary',
    'secondary', 'secondary_link',
    'tertiary', 'tertiary_link',
    'motorway','motorway_link','trunk_link', 'trunk',
    'corridor','elevator','platform','platform','crossing','proposed', 'razed')
		) t1
	) t2
	) t3
	;


DROP VIEW IF EXISTS lf_rails_bf;
CREATE OR REPLACE VIEW lf_rails_bf AS
SELECT sid, way_id, feature, type, material, size, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom  
FROM 
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
CASE
WHEN type = 'rail' THEN 2
--WHEN type = 'proposed' THEN 0 -- proposed is not in the layer anymore, and the rest of the noise isnt either
ELSE 1
END::smallint AS size, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id, feature, type, material, size,
	--REGEXP_REPLACE(left(REGEXP_REPLACE(size, '[[:alpha:]]', '', 'g'),2), '[^\w]+','', 'g') AS size,
 geom
FROM
(
SELECT way_id,  
	'linear_feature_rail' AS feature,
	tags->>'railway' AS type,
	'' AS material,
	NULL AS size,
	geom  AS geom
	FROM lines WHERE tags->>'railway' IN ('abandonded','construction','disused','light_rail','narrow_gauge','rail','preserved','tram') --or tags->> 'landuse' = 'railway' -- here I changed to IN only those tags
		) t1
	) t2
	) t3
	;

DROP VIEW IF EXISTS open_green;
CREATE OR REPLACE VIEW open_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'open_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse' IN ('park','grass', 'cemetery', 'greenfield', 'recreation_ground',  'winter_sports','brownfield', 'construction') or tags ->> 'natural' IN ('tundra') or tags->> 'golf'<>'rough' or tags->> 'highway'='construction' OR tags ->> 'amenity' = 'park' or tags ->> 'leisure' IN ('park', 'golf_course', 'marina', 'playground', 'sports_centre', 'stadium', 'pitch', 'picnic_table', 'pitch', 'dog_park', 'playground') or tags ->> 'sport' = 'soccer' or tags ->> 'power' = 'substation'
	;

DROP VIEW IF EXISTS hetero_green;
CREATE OR REPLACE VIEW hetero_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'hetero_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'natural'IN('garden', 'scrub', 'sand', 'shrub') or  tags->> 'landuse'IN('nature_reserve', 'natural_reserve', 'landscape_reserve','plant_nursery', 'meadow',  'flowerbed') or tags->> 'meadow'<>'' or tags->> 'golf' = 'rough' or tags ->> 'leisure' = 'nature_riserve' or tags->> 'boundary'='protected_area'
	;
	
DROP VIEW IF EXISTS dense_green;
CREATE OR REPLACE VIEW dense_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'dense_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'leaf_type'::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'IN('forest') or tags->>'natural'='wood' or tags ->> 'boundary' = 'forest'
	;

DROP VIEW IF EXISTS resourceful_green;
CREATE OR REPLACE VIEW resourceful_green AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'resourceful_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse' IN ('orchard','farmland', 'landfill','vineyard', 'farmyard','allotments')
	;

--- not wetland is included in the water layer, for other species such as turtles this should be a green type.
DROP VIEW IF EXISTS water;
CREATE OR REPLACE VIEW water AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'water'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'water'::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'='basin' or tags ->> 'natural' IN ('water', 'wetland') or tags ->> 'water' <>''
	;

DROP VIEW IF EXISTS parking_surface;
CREATE OR REPLACE VIEW parking_surface AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'parking_surface'::varchar(30) AS feature,
	tags->>'amenity'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'parking'='surface'
	;

DROP VIEW IF EXISTS residential;
CREATE OR REPLACE VIEW residential AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'residential'::varchar(30) AS feature,
	tags->>'residential'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'='residential'
	;

DROP VIEW IF EXISTS railway_landuse;
CREATE OR REPLACE VIEW railway_landuse AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'landuse_rail'::varchar(30) AS feature,
	tags->>'railway'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'='railway'
	;

DROP VIEW IF EXISTS commercial_industrial;
CREATE OR REPLACE VIEW commercial_industrial AS
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'commercial_industrial'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'retail'::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse' IN ('commercial',  'retail', 'industrial')
	;

DROP VIEW IF EXISTS institutional;
CREATE OR REPLACE VIEW institutional AS	
SELECT (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'institutional'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30)  AS type,
	''::varchar(30) AS material,
	NULL AS size,
	st_multi(geom)::geometry('MultiPolygon', 3857)  AS geom
    FROM polygons WHERE tags->>'landuse'IN('institutional',  'education', 'religious')
	;


DROP VIEW IF EXISTS barrier_bf;
CREATE OR REPLACE VIEW barrier_bf AS	
SELECT sid, way_id, feature, type, material,  size, st_multi(st_buffer(geom, 1))::geometry('MultiPolygon', 3857) AS geom
FROM
(
SELECT sid, way_id, feature, type, material, 
NULLIF(REGEXP_REPLACE(left(REGEXP_REPLACE(size, '[[:alpha:]]', '', 'g'),2), '[^\w]+','', 'g'),'')::numeric AS size, geom
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20),  
	'barrier'::varchar(30) AS feature,
	tags->>'barrier'::varchar(30)  AS type,
	tags->>'fence_type'::varchar(30) AS material,
	tags->>'height'::varchar(30) AS size,
	geom AS geom
    FROM lines WHERE tags->>'barrier'<>''
	) t1
	) t2
	;



	
	

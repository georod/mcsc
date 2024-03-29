pg_union_views0 <-  paste0("
SELECT 'buildings' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'building'::varchar(30) AS feature,
	tags->>'building'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size, 
	14 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'building' <>'' or 
	tags->>'building' IN ('hospital', 'parking','industrial', 'school', 'commercial', 'terrace', 'detached', 'semideatched_house', 'house', 'retail', 'hotel', 'apartments', 'yes', 'airport', 'university') or 
	tags->> 'parking' IN ('multi-storey') or 
	tags->> 'aeroway' IN ('terminal') 

UNION ALL

SELECT 'lf_roads_no_traffic_bf' as view, sid, way_id, feature, type, material, size, pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size , pri,  (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_no_traffic' AS feature, 
	tags->> 'highway' AS type,
	tags->> 'footway' AS material,
	0.5 AS size,	
	24 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom) 
	WHERE tags ->> 'highway' IN ('footway','construction','escape',
	'cycleway','steps','bridleway','path','pedestrian','track',
	'abandoned','bicycle road', 'cyclestreet', 'cycleway lane','cycleway tracks', 
	'bus and cyclists') AND  
	tags ->> 'footway' <> ('sidewalk') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL

SELECT 'lf_roads_no_traffic_bf_sidewalks'  AS view, sid, way_id, feature, type, material, size, pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size , pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_no_traffic_sidewalks' AS feature, 
	tags->>'highway' AS type,
	tags->>'footway' AS material,
	0.5 AS size,	
	16 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('footway','construction','escape',
	'cycleway','steps','bridleway','path','pedestrian','track',
	'abandoned','bicycle road', 'cyclestreet', 'cycleway lane','cycleway tracks', 
	'bus and cyclists') AND  
	tags ->> 'footway' IN ('sidewalk') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL

SELECT 'lf_roads_very_low_traffic_bf' AS view, sid, way_id, feature, type, material, size, pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size , pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_vl_traffic' AS feature, 
	tags->> 'highway' AS type,
	tags->> 'surface' AS material,
	1 AS size,	
	18 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('services','service','turning_loop','living_street') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL	

SELECT 'lf_roads_low_traffic_bf' AS view, sid, way_id, feature, type, material, size, pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size,  pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size,  pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_l_traffic' AS feature, 
	tags->> 'highway' AS type,
	tags->> 'surface' AS material,
	2 AS size,	
	19 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('residential', 'rest_area', 'busway') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL

SELECT 'lf_roads_medium_traffic_bf' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size,  pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size,  pri,  (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_m_traffic' AS feature,
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	2 AS size,
	20 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('tertiary', ' tertiary_link') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL	

SELECT 'lf_roads_high_traffic_ls_bf' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size,  pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size,  pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_h_traffic_ls' AS feature, 
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	3 AS size,
	21 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('primary', 'primary_link', 'secondary', 'secondary_link') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3
	
UNION ALL

SELECT 'lf_roads_high_traffic_hs_bf' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size,  pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size, pri,  (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_h_traffic_hs' AS feature, 
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	6 AS size,
	22 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('trunk', 'trunk_link') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL

SELECT 'lf_roads_very_high_traffic_bf' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size,  pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size, pri,  (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_vh_traffic' AS feature, 
	tags->>'highway' AS type,
	tags->>'surface' AS material,
	4 AS size,
	15 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'highway' IN ('motorway','motorway_link', 'motorway_junction') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3

UNION ALL
	
SELECT 'lf_roads_unclassified_bf' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size,  pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size, pri,  (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'linear_feature_na_traffic' AS feature, 
	tags->>'highway' AS type,
	tags->>'footway' AS material,
	2 AS size,
	17 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'highway' <>'' AND tags ->> 'highway' NOT IN (
        'footway','construction','escape','cycleway','steps','bridleway','construction','path','pedestrian','track','abandoned',
    'turning_loop','living_street', 'bicycle road', 'cyclestreet', 'cycleway lane','cycleway tracks', 'bus and cyclists',
	'service','services',  'busway', 'sidewalk',
    'residential', 'rest_area',
    'primary', 'motorway_junction',
    'secondary', 'secondary_link',
    'tertiary', 'tertiary_link',
    'motorway','motorway_link','trunk_link', 'trunk',
    'corridor','elevator','platform','platform','crossing','proposed', 'razed') AND (tags ->> 'bridge'='no' OR tags ->> 'bridge' is null)
		) t1
	) t2
	) t3


UNION ALL

SELECT 'lf_rails_bf_abandoned' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom  
FROM 
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
CASE
WHEN type = 'rail' THEN 2
ELSE 1
END::smallint AS size,  pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id, feature, type, material, size,  pri, 
	 geom
FROM
(
SELECT way_id,  
	'linear_feature_rail_abandoned' AS feature, 
	tags->>'railway' AS type,
	tags->>'highway' AS material,
	NULL AS size,
	26 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
	FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'railway' IN ('abandonded','construction','disused' 
	) or 
	tags->> 'highway'='construction' 
		) t1
	) t2
	) t3

UNION ALL

SELECT 'lf_rails_bf_trams' AS view, sid, way_id, feature, type, material, size,  pri, st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom  
FROM 
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
CASE
WHEN type = 'rail' THEN 2
ELSE 1
END::smallint AS size,  pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id, feature, type, material, size, pri, 
	 geom
FROM
(
SELECT way_id,  
	'linear_feature_rail_trams' AS feature, 
	tags->>'railway' AS type,
	tags->>'highway' AS material,
	NULL AS size,
	23 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
	FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'railway' IN ('tram') 
		) t1
	) t2
	) t3

UNION ALL
	
SELECT 'lf_rails_bf' AS view, sid, way_id, feature, type, material, size, pri,  st_multi(st_buffer(geom, 6*size))::geometry('MultiPolygon', 3857) AS geom  
FROM 
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
CASE
WHEN type = 'rail' THEN 2
ELSE 1
END::smallint AS size,  pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id, feature, type, material, size, pri, 
	geom
FROM
(
SELECT way_id,  
	'linear_feature_rail' AS feature, 
	tags->>'railway' AS type,
	tags->>'highway' AS material,
	NULL AS size,
	25 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
	FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'railway' IN (
	'light_rail','narrow_gauge','rail','preserved')
		) t1
	) t2
	) t3

UNION ALL

SELECT 'open_green' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'open_green_area'::varchar(30) AS feature, 
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	6 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse' IN ('park','grass', 'cemetery', 
	'greenfield', 'recreation_ground', 'winter_sports') or 
	tags->> 'golf'<>'rough' or  
	tags ->> 'amenity' = 'park' or 
	tags ->> 'leisure' IN ('park', 'stadium', 'playground', 'pitch', 
	'sports_centre', 'stadium', 'pitch', 'picnic_table', 'pitch', 'dog_park', 'playground') or 
	tags ->> 'sport' = 'soccer' or 
	tags ->> 'power' = 'substation' or
	tags ->> 'surface' = 'grass' 

UNION ALL

SELECT 'protected_area' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'protected_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	7 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags ->> 'leisure' = 'nature_riserve' or  
	tags->> 'boundary' IN ('protected_area', 'national_park') or
	tags->> 'protected_area' = 'nature' or 
	tags->> 'landuse' IN ('nature_reserve', 'natural_reserve', 'landscape_reserve') 

UNION ALL

SELECT 'hetero_green' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'hetero_green_area'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	9 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'natural' IN ('garden',
	 'scrub', 'shrubbery', 'tundra', 'cliff',
	'shrub', 'wetland', 
	'grassland', 'fell', 'heath','moor') or
	tags->> 'landuse'IN('plant_nursery', 
	'meadow',  'flowerbed', 'wetland') or
	tags->> 'meadow' <>'' or 
	tags->> 'golf' IN ('rough') or 
	tags->> 'grassland' = 'prairie'

UNION ALL

SELECT 'bare_soil' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
        'bare_soil'::varchar(30) AS feature,
        tags->>'landuse'::varchar(30) AS type,
        tags->>'natural'::varchar(30) AS material,
        NULL AS size,
        10 AS pri, 
        (ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
        FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
        WHERE tags->>'natural' IN ('mud', 'dune',
                                 'sand','scree','sinkhole', 'beach') or  
        tags->> 'landuse' IN ('brownfield', 'construction') or 
        tags->> 'golf' IN ('bunker') or 
        tags->> 'waterway' = 'boatyard' 
        
UNION ALL
        
        SELECT 'dense_green' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
        'dense_green_area'::varchar(30) AS feature,
        tags->>'landuse'::varchar(30) AS type,
        tags->>'leaf_type'::varchar(30) AS material,
        NULL AS size,
        11 AS pri,
        (ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
        FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
        WHERE tags->>'landuse' IN ('forest') or 
        tags->>'natural'='wood' or 
        tags ->> 'boundary' IN ('forest', 'forest_compartment') 

UNION ALL

SELECT 'resourceful_green' AS  view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'resourceful_green_area'::varchar(30) AS feature, 
	tags->>'landuse'::varchar(30) AS type,
	tags->>'natural'::varchar(30) AS material,
	NULL AS size,
	8 AS pri, 
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse' IN ('orchard','farmland', 
	'landfill','vineyard', 'farmyard', 'allotments', 'allotment', 'farmland') or
	tags->> 'leisure' = 'garden' or
	tags->> 'allotments' <> ''

UNION ALL

SELECT 'water' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'water'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'water'::varchar(30) AS material,
	NULL AS size,
	12 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse'='basin' OR 
	tags->> 'natural' IN ('water', 'spring', 'waterway') OR 
	tags->> 'waterway' IN ('river', 'stream', 'tidal_channel', 'canal', 'drain', 'ditch', 'yes') or
	tags->> 'water' <>'' OR
	tags->> 'waterway' <> 'boatyard' OR
	tags->> 'water' <> 'intermittent' OR
	tags->> 'landuse' = 'basin' OR
	tags->> 'basin' = 'detention' AND
	tags->> 'intermittent' <> 'yes' AND 
	tags->> 'seasonal' <> 'yes' AND
	tags->> 'tidal' <> 'yes'

UNION ALL

SELECT 'parking_surface' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'parking_surface'::varchar(30) AS feature,
	tags->>'amenity'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size,
	13 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'parking'='surface' or
	tags->> 'aeroway' IN ('runway', 'apron') 

UNION ALL

SELECT 'residential' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'residential'::varchar(30) AS feature,
	tags->>'residential'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size,
	4 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse'='residential'
	
UNION ALL

SELECT 'railway_landuse' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'landuse_rail'::varchar(30) AS feature,
	tags->>'railway'::varchar(30) AS type,
	''::varchar(30) AS material,
	NULL AS size,
	5 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse'='railway'
	
UNION ALL

SELECT 'commercial' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'commercial'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'retail'::varchar(30) AS material,
	NULL AS size,
	2 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse' IN ('commercial',  'retail')

UNION ALL

SELECT 'industrial' AS view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'industrial'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30) AS type,
	tags->>'retail'::varchar(30) AS material,
	NULL AS size,
	1 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse' IN ('industrial', 'fairground') or
	tags->> 'industrial' IN ('factory') 

UNION ALL

SELECT 'institutional' AS	view, (row_number() OVER ())::int AS sid, area_id::varchar(20),  
	'institutional'::varchar(30) AS feature,
	tags->>'landuse'::varchar(30)  AS type,
	''::varchar(30) AS material,
	NULL AS size,
	3 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('Polygon', 3857) AS geom
    FROM polygons t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'landuse' IN ('institutional',  'education', 'religious', 'military') or
	tags->> 'amenity' IN ('school', 'hospital', 'university','fast_food', 'clinic', 'theatre', 'conference_center', 
	'place_of_worship', 'police') or
	tags->> 'leisure' IN ('golf_course', 'marina') or
	tags->> 'healthcare' IN ('clinic', 'hospital')or
	tags ->> 'tourism' = 'theme_park'

UNION ALL

SELECT 'barrier_bf' AS view, sid, way_id, feature, type, material,  size,  pri, st_multi(st_buffer(geom, 1))::geometry('MultiPolygon', 3857) AS geom
FROM
(
SELECT sid, way_id, feature, type, material, 
 size,  pri, geom
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20),  
	'barrier'::varchar(30) AS feature,
	tags->>'barrier'::varchar(30)  AS type,
	tags->>'fence_type'::varchar(30) AS material,
	NULL::int AS size,
	27 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'barrier' <>''
	) t1
	) t2

UNION ALL

SELECT 'waterways_bf' AS view, sid, way_id, feature, type, material, size, pri, st_multi(st_buffer(geom, 3*size))::geometry('MultiPolygon', 3857) AS geom 
FROM
(
SELECT (row_number() OVER ())::int AS sid, way_id::varchar(20), 
feature::varchar(30), type::varchar(30), material::varchar(30), 
size, pri, geom 
FROM
(
SELECT way_id, feature, type, material,
size , pri, (geom)::geometry(LineString, 3857) AS geom
FROM
(
SELECT way_id,  
	'waterways' AS feature, 
	tags->>'waterway' AS type,
	tags->>'water' AS material,
	2 AS size,
	12 AS pri,
	(ST_DUMP(ST_Intersection(t1.geom, t2.geom))).geom::geometry('LineString', 3857) AS geom
    FROM lines t1 JOIN ", city0," t2
        ON st_intersects(t1.geom,t2.geom)
	WHERE tags->>'waterway' <>'' OR 
	tags->>'water' <>'' AND
	tags->> 'intermittent' <> 'yes' AND 
	tags->> 'seasonal' <> 'yes' AND
	tags->> 'tidal' <> 'yes'
		) t1
	) t2
	) t3

 "
   )
   
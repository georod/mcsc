---------------------------------------------------------------
-- Creating custom city envelopes that are not found in OSM
---------------------------------------------------------------

-- 2025-04-26
-- Peter R.

-- 1) Create object in QGIS 
-- 2) Save object as sql file
-- 3) Run in psql
--    \i /project/6000221/georod/scripts/github/mcsc/misc/indianapolis3_env.sql
-- 4) I carried out some manual QL changes which I do not document. The method below is better and should be used.

---------------------------------------------------------------
--  2025-04-26
--  Adding custom city envelopes that are not found in OSM
-- 1) Run
CREATE TABLE seattle3_env (sid serial, relation_id int, feature varchar(30), type varchar(30), material varchar(30), size varchar(30), geom geometry(Polygon, 3857));
INSERT INTO seattle3_env (sid, relation_id, feature, type, material, size) VALUES (1, 10000000, 'background', 'Seattle3', '', '');

--Tempate: ST_MakeEnvelope(xmin, ymin, xmax, ymax, SRID)

UPDATE seattle3_env SET geom = st_transform(ST_MakeEnvelope(-122.423911576421, 47.4169708269983, -121.945288423579, 47.7540498395082, 4326), 3857) WHERE sid=1;


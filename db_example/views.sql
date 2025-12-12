-- Vista per confeirmento coordinate
CREATE OR REPLACE VIEW accessi.conf_coord
 AS
 SELECT civici.acc_id AS id,
    civici.progressivo_civico AS progressivo_accesso,
    round(st_x(st_transform(civici.geom, 4326))::numeric, 6) AS coord_x,
    round(st_y(st_transform(civici.geom, 4326))::numeric, 6) AS coord_y,
    3 AS metodo
   FROM accessi.civici
  WHERE civici.acc_id IS NOT NULL AND civici.progressivo_civico IS NOT NULL AND civici.geom IS NOT NULL AND civici.allineato IS FALSE;

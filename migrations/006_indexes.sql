-- Spatial indexes for the demonstrated screening paths.
\echo '--> Create index iris_core.idx_parcel_geom_gist on iris_core.parcel'
CREATE INDEX idx_parcel_geom_gist
    ON iris_core.parcel
    USING GIST (geom);

\echo '--> Create index iris_core.idx_substation_geom_gist on iris_core.substation'
CREATE INDEX idx_substation_geom_gist
    ON iris_core.substation
    USING GIST (geom);

\echo '--> Create index iris_core.idx_peatland_geom_gist on iris_core.peatland'
CREATE INDEX idx_peatland_geom_gist
    ON iris_core.peatland
    USING GIST (geom);

\echo '--> Create index iris_core.idx_screening_layer_geom_gist on iris_core.screening_layer'
CREATE INDEX idx_screening_layer_geom_gist
    ON iris_core.screening_layer
    USING GIST (geom);

-- Metre-based proximity queries use the geography expression.
\echo '--> Create index iris_core.idx_substation_geography_gist on iris_core.substation'
CREATE INDEX idx_substation_geography_gist
    ON iris_core.substation USING GIST ((geom::geography));

-- Relational indexes for evidence lookups.
\echo '--> Create index iris_core.idx_evidence_country_parcel on iris_core.evidence'
CREATE INDEX idx_evidence_country_parcel
    ON iris_core.evidence (country_code, parcel_id);

\echo '--> Create index iris_core.idx_evidence_country_source_run on iris_core.evidence'
CREATE INDEX idx_evidence_country_source_run
    ON iris_core.evidence (country_code, source_run_id);

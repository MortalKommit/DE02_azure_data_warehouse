CREATE TABLE dimStation WITH
(
    DISTRIBUTION = ROUND_ROBIN
) AS   

SELECT 
    [StationId] = [staging_station].station_id,
    [StationName] = [staging_station].[name],
    [Latitude] = [staging_station].latitude,
	[Longitude] = longitude
FROM [staging_station] 

ALTER TABLE dimStation ALTER COLUMN [StationId] nvarchar(50) NOT NULL;
ALTER TABLE dimStation add CONSTRAINT dim_station_key PRIMARY KEY NONCLUSTERED ([StationId]) NOT ENFORCED;

CREATE INDEX dim_station_name_idx ON [dimStation] ([StationName]);
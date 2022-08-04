CREATE TABLE dimTrip WITH
(
    DISTRIBUTION = ROUND_ROBIN
) AS   

WITH start_station_detail AS (
	SELECT trip_id, rideable_type,
		"name" AS start_station_name,
	 	latitude AS start_station_latitude,
	 	longitude AS start_station_longitude

	FROM staging_trip JOIN staging_station
	ON staging_trip.start_station_id = staging_station.station_id
),
end_station_detail AS (
	SELECT trip_id,
		"name" AS end_station_name,
		latitude AS end_station_latitude,
		longitude AS end_station_longitude
	FROM staging_trip JOIN staging_station
	ON staging_trip.end_station_id  = staging_station.station_id
) 
SELECT 
    [TripId] = start_station_detail.trip_id,
    [RideableType] = rideable_type,
    [StartStationName] = start_station_detail.start_station_name,
    [StartStationLatitude] = start_station_latitude,
	[StartStationLongitude] = start_station_longitude,
    [EndStationName] =  end_station_name,
    [EndStationLatitude] = end_station_latitude, 
	[EndStationLongitude] = end_station_longitude
FROM start_station_detail 
  JOIN end_station_detail
  ON start_station_detail.trip_id = end_station_detail.trip_id;

ALTER TABLE dimTrip ALTER COLUMN [TripId] varchar(50) NOT NULL;
ALTER TABLE dimTrip add CONSTRAINT dim_trip_key PRIMARY KEY NONCLUSTERED ([TripId]) NOT ENFORCED;


CREATE TABLE factTripRiderDetails WITH
(
    DISTRIBUTION = ROUND_ROBIN
) AS   
SELECT 
    [TripRiderKey]   =   CONCAT(trip_id, CAST ([dimRider].RiderId AS varchar(10))),
    [StartStationId] = [staging_trip].start_station_id,
	[EndStationId] = [staging_trip].end_station_id,
	[RiderId] = [dimRider].RiderId,
	[TripStartKey] = CAST(FORMAT(TRY_CONVERT(datetime2, staging_trip.start_at), 'yyyyMMddHH') AS BIGINT),
	[RiderAgeAtTripYears] = CAST(DATEDIFF(YEAR, dimRider.birthday, staging_trip.start_at) AS SMALLINT),
	[TripDurationSeconds] = CAST(DATEDIFF(SECOND, [staging_trip].start_at, [staging_trip].ended_at) AS BIGINT)  
	FROM [staging_trip]
	LEFT JOIN [dimRider]
	ON [staging_trip].rider_id = [dimRider].RiderId ;

ALTER TABLE [factTripRiderDetails] ALTER COLUMN [TripRiderKey] varchar(50) NOT NULL;
ALTER TABLE [factTripRiderDetails] ADD CONSTRAINT fact_Trip_Rider_Details_Key PRIMARY KEY NONCLUSTERED ([TripRiderKey]) NOT ENFORCED;


CREATE INDEX fact_trip_rider_details_rider_idx ON [factTripRiderDetails] ([RiderId]);
CREATE INDEX fact_trip_rider_details_duration_idx ON [factTripRiderDetails] ([TripDurationSeconds]);
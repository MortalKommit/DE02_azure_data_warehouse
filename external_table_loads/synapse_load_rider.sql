IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseDelimitedTextFormat') 
	CREATE EXTERNAL FILE FORMAT [SynapseDelimitedTextFormat] 
	WITH ( FORMAT_TYPE = DELIMITEDTEXT ,
	       FORMAT_OPTIONS (
			 FIELD_TERMINATOR = ',',
			 STRING_DELIMITER = '"',
			 USE_TYPE_DEFAULT = FALSE
			))
GO

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'azuredwhfile_azuredwhacc_dfs_core_windows_net') 
	CREATE EXTERNAL DATA SOURCE [azuredwhfile_azuredwhacc_dfs_core_windows_net] 
	WITH (
		LOCATION = 'abfss://azuredwhfile@azuredwhacc.dfs.core.windows.net', 
		TYPE = HADOOP 
	)
GO

CREATE EXTERNAL TABLE staging_rider (
	[rider_id] bigint,
	[first] nvarchar(50),
	[last] nvarchar(50),
	[address] nvarchar(100),
	[birthday] nvarchar(50),
	[account_start_date] nvarchar(50),
	[account_end_date] nvarchar(50),
	[is_member] bit
	)
	WITH (
	LOCATION = 'rider.csv',
	DATA_SOURCE = [azuredwhfile_azuredwhacc_dfs_core_windows_net],
	FILE_FORMAT = [SynapseDelimitedTextFormat]
	)
GO


SELECT TOP 100 * FROM dbo.staging_rider
GO
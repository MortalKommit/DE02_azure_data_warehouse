CREATE TABLE factPaymentDetails WITH
(
    DISTRIBUTION = ROUND_ROBIN
) AS   
SELECT 
    [factPaymentDetailsKey] = payment_id,
    [RiderId]               = dimRider.RiderId,
	[PaymentDateKey]	    = CAST(FORMAT(TRY_CONVERT(datetime2, [staging_payment].date), 'yyyyMMddHH') AS BIGINT), -- this will be looked up against dimDate DateTimeKey
    [PaymentAmount]         = [staging_payment].amount 
	FROM [staging_payment]
	LEFT JOIN [dimRider]
	ON [staging_payment].rider_id = [dimRider].RiderId;


ALTER TABLE [factPaymentDetails] ALTER COLUMN [factPaymentDetailsKey] BIGINT NOT NULL;
ALTER TABLE [factPaymentDetails] ADD CONSTRAINT fact_Payment_Details_Key PRIMARY KEY NONCLUSTERED ([factPaymentDetailsKey]) NOT ENFORCED;

CREATE INDEX fact_payment_details_rider_idx ON [factPaymentDetails] ([RiderId]);
CREATE INDEX fact_payment_details_date_idx ON [factPaymentDetails] ([PaymentDateKey]);
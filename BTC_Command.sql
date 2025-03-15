CREATE TABLE cryptocurrency_prediction.crypto_data (
	symbol VARCHAR(20),
	timestamp BIGINT PRIMARY KEY,
	open DECIMAL(18, 8),
	high DECIMAL (18,8),
	low DECIMAL (18,8),
	close DECIMAL (18,8),
	volume DECIMAL (18,8)
);

SELECT * FROM cryptocurrency_prediction.crypto_data;
CREATE TABLE cryptocurrency_prediction.prediction_log(
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    features TEXT,
    signal TEXT,
    prob_sell NUMERIC,
    prob_buy NUMERIC
);

SELECT * FROM cryptocurrency_prediction.prediction_log;


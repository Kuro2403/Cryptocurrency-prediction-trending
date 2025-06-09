/*-------------------------------------------------
  0.  Tạo schema riêng cho project
-------------------------------------------------*/
CREATE SCHEMA IF NOT EXISTS cryptocurrency_prediction;
SET search_path TO cryptocurrency_prediction;

/*-------------------------------------------------
  1. Dimension table – danh mục cặp giao dịch
-------------------------------------------------*/
CREATE TABLE IF NOT EXISTS cryptocurrency_prediction.symbols (
    symbol_id   SERIAL  PRIMARY KEY,
    symbol      TEXT    UNIQUE NOT NULL,      -- e.g. ‘BTCUSDT’
    base_asset  TEXT    NOT NULL,
    quote_asset TEXT    NOT NULL,
    status      TEXT    DEFAULT 'TRADING'     -- hoặc ‘DELISTED’
);

/*-------------------------------------------------
  2. Fact table – OHLCV gốc (time‑series)
     Partition by month để ghi nhanh & xóa gọn
-------------------------------------------------*/
CREATE TABLE IF NOT EXISTS cryptocurrency_prediction.ohlcv_raw (
    symbol_id  INT  NOT NULL,
    ts         TIMESTAMPTZ NOT NULL,          -- UTC
    open       NUMERIC(18,8),
    high       NUMERIC(18,8),
    low        NUMERIC(18,8),
    close      NUMERIC(18,8),
    volume     NUMERIC(28,8),
    PRIMARY KEY (symbol_id, ts),
    FOREIGN KEY (symbol_id) REFERENCES cryptocurrency_prediction.symbols(symbol_id)
);

/*-------------------------------------------------
  3. Indicators – các chỉ báo tính hậu kỳ
-------------------------------------------------*/
CREATE TABLE IF NOT EXISTS cryptocurrency_prediction.indicators (
    symbol_id  INT,
    ts         TIMESTAMPTZ,
    rsi_14     NUMERIC(6,3),
    macd       NUMERIC(8,4),
    macd_sig   NUMERIC(8,4),
    bb_up      NUMERIC(18,8),
    bb_mid     NUMERIC(18,8),
    bb_low     NUMERIC(18,8),
    sma_50     NUMERIC(18,8),
    sma_200    NUMERIC(18,8),
    PRIMARY KEY (symbol_id, ts),
    FOREIGN KEY (symbol_id, ts)
        REFERENCES cryptocurrency_prediction.ohlcv_raw(symbol_id, ts) ON DELETE CASCADE
);

/*-------------------------------------------------
  4. Ảnh nến lưu file‑path + metadata
-------------------------------------------------*/
CREATE TABLE IF NOT EXISTS cryptocurrency_prediction.chart_images (
    img_id     BIGSERIAL PRIMARY KEY,
    symbol_id  INT          NOT NULL REFERENCES cryptocurrency_prediction.symbols(symbol_id),
    ts_start   TIMESTAMPTZ  NOT NULL,
    timeframe  INTERVAL     NOT NULL,          -- 15m / 1h …
    file_path  TEXT         NOT NULL UNIQUE,
    md5_hash   CHAR(32)     UNIQUE,
    created_at TIMESTAMPTZ  DEFAULT NOW()
);

/*-------------------------------------------------
  5. Bảng đa‑nhãn pattern ↔ ảnh
-------------------------------------------------*/
CREATE TABLE IF NOT EXISTS cryptocurrency_prediction.pattern_labels (
    img_id     BIGINT REFERENCES cryptocurrency_prediction.chart_images(img_id) ON DELETE CASCADE,
    pattern    TEXT    NOT NULL,               -- ‘Bullish Engulfing’ …
    confidence REAL    CHECK (confidence BETWEEN 0 AND 1),
    PRIMARY KEY (img_id, pattern)
);

/*-------------------------------------------------
  6. Log dự đoán (mô hình → xác suất)
-------------------------------------------------*/
CREATE TABLE IF NOT EXISTS cryptocurrency_prediction.prediction_log (
    pred_id     BIGSERIAL PRIMARY KEY,
    ts_predict  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    symbol_id   INT         NOT NULL REFERENCES cryptocurrency_prediction.symbols(symbol_id),
    horizon     SMALLINT    NOT NULL,          -- số nến dự báo
    signal      TEXT        CHECK (signal IN ('BUY','SELL','HOLD')),
    prob_buy    REAL        CHECK (prob_buy BETWEEN 0 AND 1),
    prob_sell   REAL        CHECK (prob_sell BETWEEN 0 AND 1),
    img_id      BIGINT REFERENCES cryptocurrency_prediction.chart_images(img_id),
    feature_sha CHAR(40)    -- hash vector để trace reproducibility
);

/*-------------------------------------------------
  7. (Tùy chọn) Bảng trade nếu triển khai auto‑bot
-- -------------------------------------------------*/
-- CREATE TABLE IF NOT EXISTS trades (
--     trade_id   BIGSERIAL PRIMARY KEY,
--     pred_id    BIGINT REFERENCES prediction_log(pred_id),
--     side       TEXT    CHECK (side IN ('LONG','SHORT')),
--     qty        NUMERIC(28,10),
--     entry_px   NUMERIC(18,8),
--     exit_px    NUMERIC(18,8),
--     pnl_usd    NUMERIC(18,8),
--     opened_at  TIMESTAMPTZ,
--     closed_at  TIMESTAMPTZ,
--     fee_usd    NUMERIC(18,8)
-- );

/*-------------------------------------------------
  8. Indexes – tăng tốc truy vấn phổ biến
-------------------------------------------------*/
CREATE INDEX IF NOT EXISTS idx_raw_symbol_ts
    ON ohlcv_raw(symbol_id, ts DESC);

CREATE INDEX IF NOT EXISTS idx_img_symbol_ts
    ON chart_images(symbol_id, ts_start DESC);

CREATE INDEX IF NOT EXISTS idx_pred_symbol_ts
    ON prediction_log(symbol_id, ts_predict DESC);


-- 0) Ngắt foreign‑key, xóa theo thứ tự phụ thuộc
TRUNCATE TABLE
    -- cryptocurrency_prediction.prediction_log
    -- cryptocurrency_prediction.pattern_labels
    -- cryptocurrency_prediction.chart_images
    -- cryptocurrency_prediction.indicators
    -- cryptocurrency_prediction.ohlcv_raw
RESTART IDENTITY CASCADE;

SELECT * FROM cryptocurrency_prediction.symbols
SELECT * FROM cryptocurrency_prediction.ohlcv_raw
SELECT * FROM cryptocurrency_prediction.pattern_labels
SELECT * FROM cryptocurrency_prediction.chart_images
SELECT * FROM cryptocurrency_prediction.indicators
SELECT * FROM cryptocurrency_prediction.prediction_log

SELECT 
    pattern,
    COUNT(*) AS total
FROM 
    cryptocurrency_prediction.pattern_labels
GROUP BY 
    pattern
ORDER BY 
    total DESC;

ALTER TABLE cryptocurrency_prediction.chart_images
ADD COLUMN img_bytes BYTEA;     -- can be NULL for rows you haven’t filled yet


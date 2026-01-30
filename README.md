# Cryptocurrency-prediction-trending
**Multimodal Deep Learning for Cryptocurrency Trend Prediction** using candlestick chart morphology + OHLCV/technical indicators, fused with XGBoost and confidence-aware gating for risk-controlled trading signals.

> Paper (research prototype): *Multimodal Deep Learning for Cryptocurrency Trend Prediction via Candlestick Charts and Technical Indicators*  
> DOI/Proceedings: (add your publisher link/DOI here)

---

## 🔥 What this repo does
This project predicts short-term crypto market direction on **15-minute BTC/USDT** bars by combining:
- **Candlestick chart images** (visual patterns / market psychology)
- **OHLCV time series + technical indicators** (short-term + long-term context)
- A **fusion classifier** and an optional **confidence gate** that can abstain (HOLD) when uncertainty is high.

**Output classes:** `Bull / Bear / Neutral`  
**Trading actions:** `Buy / Sell / Hold` (mapped from predicted probabilities and gating threshold)

---

## 🧠 Method (High-level)
**Stage 1 – Feature extraction (3 encoders):**
1) **MobileNetV2** encodes candlestick images → visual embedding  
2) **GRU** encodes OHLCV + indicators → short-term embedding  
3) **NAR encoder (self-attention + positional encoding)** → long-term embedding  

**Stage 2 – Fusion + classification:**
- Concatenate embeddings (+ selected indicators) → feed into **XGBoost** (`multi:softprob`, `num_class=3`)

**Reliability (optional): Confidence-aware gating**
- Only place trades when confidence ≥ `τ`; otherwise return **HOLD** (abstain).  
This provides a practical trade-off between **coverage** (how often you trade) and **accuracy**.

---

## 📦 Dataset
- Market data: **Binance Kline API**, BTC/USDT, **15-minute OHLCV**
- Time range used in experiments: **01/07/2023 – 01/07/2025**
- Splits: **70% train / 15% val / 15% test**
- Notes:
  - Candlestick images are rendered with a fixed template (e.g., 224×224).
  - Technical indicators include MA, RSI, MACD, Bollinger Bands, volume features, etc.
  - Neutral labels may dominate; for training stability you may downsample/remove excess Neutral and rebalance Bull/Bear.

> ⚠️ Data is not bundled in this repository. You must comply with Binance terms and any dataset licensing rules.

---

## 🧪 Reported Results (from the paper)
**Full Fusion (MobileNetV2 + GRU + NAR + XGBoost):**
- Accuracy: **0.7430**
- Macro-F1: **0.7429**
- MCC: **0.4867**

**Confidence gating (τ = 0.70):**
- Coverage: **67.74%**
- Accuracy / Macro-F1: **0.8145 / 0.8130**
- Higher thresholds can push selective accuracy close to **~98%** on smaller subsets (lower coverage).

---

## 🛠️ Setup
### Requirements
- Python 3.10+ recommended
- PyTorch (if training encoders)
- XGBoost
- Typical stack: numpy, pandas, scikit-learn, ta/ta-lib (indicators), matplotlib, opencv/PIL

Example:
```bash
pip install -r requirements.txt

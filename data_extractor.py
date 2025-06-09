import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path
import yaml, os

cfg = yaml.safe_load(Path("config.yaml").read_text())
engine = create_engine(os.environ["POSTGRES_URI"])

def row_stream(chunksize=2048):
    sql = cfg["sql"]["query"]
    for chunk in pd.read_sql(sql, engine, chunksize=chunksize):
        for rec in chunk.itertuples(index=False):
            yield rec.file_path, rec.pattern, getattr(rec, "confidence", 1.0)

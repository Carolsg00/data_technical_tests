
from pathlib import Path
import duckdb

base = Path(__file__).resolve().parent.parent
data = base / "data"

with duckdb.connect(str(data / "primer_impacto.duckdb")) as con:
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    for archivo in (data / "raw").glob("*.csv"):
        ruta = archivo.as_posix().replace("'", "''")

        con.execute(f"""
            CREATE OR REPLACE TABLE raw.{archivo.stem} AS
            SELECT *
            FROM read_csv('{ruta}', all_varchar=true)
        """)

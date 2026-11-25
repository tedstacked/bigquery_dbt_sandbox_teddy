# Repro for dbt-labs/dbt#16614. With the BigQuery Foundry ADBC driver, Fusion
# Stable sends adbc.bigquery.dataproc.pooling_timeout as a string, and the
# driver rejects it (dbt1308) before any BigQuery job is created.
import pandas as pd


def model(dbt, session):
    dbt.config(materialized="table", submission_method="bigframes")
    return pd.DataFrame({"x": [1]})

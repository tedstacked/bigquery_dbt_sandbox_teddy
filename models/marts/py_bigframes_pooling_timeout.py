# Repro for dbt-labs/dbt#16614. With the BigQuery Foundry ADBC driver, Fusion
# Stable sends adbc.bigquery.dataproc.pooling_timeout (this model's timeout) as
# a string, and the driver rejects it (dbt1308) before any BigQuery job is created.
# timeout=600 only caps how long dbt waits on the notebook if a run gets that far.
import pandas as pd


def model(dbt, session):
    dbt.config(materialized="table", submission_method="bigframes", timeout=600)
    return pd.DataFrame({"x": [1]})

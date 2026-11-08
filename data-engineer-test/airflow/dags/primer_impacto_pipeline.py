
import logging

from datetime import datetime, timedelta, timezone

from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator


logger = logging.getLogger(__name__)


def log_task_failure(context):
    task_instance = context.get("task_instance")
    error = context.get("exception")

    logger.error(
        "Error en el DAG %s, tarea %s, ejecucion %s: %s",
        task_instance.dag_id,
        task_instance.task_id,
        context.get("run_id"),
        error,
    )


default_args = {
    "owner": "data_engineering",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
    "on_failure_callback": log_task_failure,
}


with DAG(
    dag_id="primer_impacto_pipeline",
    description="Ingesta de datos y transformaciones dbt",
    start_date=datetime(2026, 11, 1, tzinfo=timezone.utc),
    schedule="0 4 * * *",
    catchup=False,
    is_paused_upon_creation=True,
    max_active_runs=1,
    dagrun_timeout=timedelta(minutes=40),
    default_args=default_args,
    tags=["primer_impacto", "data_engineering"],
) as dag:

    load_raw = BashOperator(
        task_id="load_raw",
        bash_command=(
            "cd /opt/project && "
            "python scripts/load_raw.py"
        ),
        execution_timeout=timedelta(minutes=5),
        do_xcom_push=False,
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=(
            "cd /opt/project/dbt && "
            "dbt build --profiles-dir ."
        ),
        execution_timeout=timedelta(minutes=20),
        do_xcom_push=False,
    )

    load_raw >> dbt_build

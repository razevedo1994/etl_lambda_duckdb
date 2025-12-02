import duckdb
import os
import boto3


KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
SECRET_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]

def lambda_handler(event, context):
    print(event)
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]

    conn = duckdb.connect()

    conn.query(
        """
               INSTALL httpfs;
               LOAD httpfs;
                CREATE SECRET secretaws (
                TYPE S3,
                PROVIDER CREDENTIAL_CHAIN
            );
               """
    )
from fastapi import FastAPI
from datetime import datetime
import os
import boto3
import json
import psycopg2


app = FastAPI(title="AWS Platform API")

startup_time = datetime.utcnow()

def getdbconnection():
    secret_arn = os.getenv("DB_SECRET_ARN")
    region     = os.getenv("AWS_REGION", "eu-west-1")

    client = boto3.client("secretsmanager", region_name=region)
    secret = json.loads(
        client.get_secret_value(SecretId=secret_arn)["SecretString"]
    )

    return psycopg2.connect(
        host            = secret["host"],
        port            = int(secret["port"]),
        dbname          = secret["dbname"],
        user            = secret["username"],
        password        = secret["password"],
        connect_timeout = 3
    )

@app.get("/health")
def health_check():
    """
    Purpose: To do a simple health check
    """
    db_status = "unknown"

    try:
        conn = getdbconnection()
        conn.close()
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "healthy" if db_status == "healthy" else 'degraded',
        "environment": os.getenv("ENVIRONMENT","unknownenv"),
        "timestamp": datetime.utcnow().isoformat(),
        "uptime": (datetime.utcnow() - startup_time).seconds,
        "database": db_status
    }

# end def

@app.get("/info")
def getinfo():
    """
    Purpose: To provide some information about the project 
    """
    return {
        "app": "aws-platform-api",
        "environment": os.getenv("ENVIRONMENT", "Unknown env"),
        "region": os.getenv("AWS_REGION", "unknown region"),
        "version": "1.0.0"
    }
# end def

@app.get("/")
def root():
    """
    Purpose: A simple endpoint to check if the API is running or not 
    """
    return {
        "message": "The API endpoint is up and running :) have fun!"
    }
# end def


# trigerring change
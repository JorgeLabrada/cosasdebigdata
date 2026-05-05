import json
import os
from datetime import datetime, timezone

import boto3

s3 = boto3.client("s3")
BUCKET_NAME = os.environ["BUCKET_NAME"]


def handler(event, context):
    severity = event.get("severity", "low")
    ticket_id = event.get("ticket_id", "unknown")

    key = f"{severity}/{ticket_id}.json"
    routed_at = datetime.now(timezone.utc).isoformat()

    payload = {**event, "routed": True, "s3_key": key, "routed_at": routed_at}

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=json.dumps(payload),
        ContentType="application/json",
    )

    return payload

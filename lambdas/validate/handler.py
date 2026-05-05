import json


def handler(event, context):
    priority_score = event.get("priority_score")
    description = event.get("description", "")

    if priority_score is None:
        raise ValueError("priority_score is required")

    if not isinstance(priority_score, (int, float)):
        raise ValueError("priority_score must be numeric")

    if not (0 <= float(priority_score) <= 100):
        raise ValueError("priority_score must be between 0 and 100")

    if not description or not description.strip():
        raise ValueError("description cannot be empty")

    return {
        **event,
        "validated": True,
    }

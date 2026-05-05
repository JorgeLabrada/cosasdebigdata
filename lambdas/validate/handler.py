import json


def handler(event, context):
    priority_score = event.get("priority_score")
    description = event.get("description", "")

    if priority_score is None:
        raise ValueError("mensaje 1")

    if not isinstance(priority_score, (int, float)):
        raise ValueError("mensaje 2")

    if not (0 <= float(priority_score) <= 100):
        raise ValueError("mensaje 3")

    if not description or not description.strip():
        raise ValueError("mensaje 4")

    return {
        **event,
        "validated": True,
    }

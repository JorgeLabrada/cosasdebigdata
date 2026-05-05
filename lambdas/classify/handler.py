URGENT_KEYWORDS = [
    "urgent", "down", "not working", "unresponsive", "critical",
    "broken", "emergency", "asap", "outage", "crashed",
]
ESCALATE_KEYWORDS = ["error", "issue", "problem", "slow", "failing"]


def handler(event, context):
    priority_score = float(event.get("priority_score", 0))
    description = event.get("description", "").lower()

    if priority_score >= 75:
        base = "urgent"
    elif priority_score >= 40:
        base = "normal"
    else:
        base = "low"

    urgent_hit = any(kw in description for kw in URGENT_KEYWORDS)
    escalate_hit = any(kw in description for kw in ESCALATE_KEYWORDS)

    if urgent_hit and base in ("normal", "low"):
        severity = "urgent"
    elif escalate_hit and base == "low":
        severity = "normal"
    else:
        severity = base

    return {
        **event,
        "severity": severity,
        "classified": True,
    }

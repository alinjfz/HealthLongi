#!/usr/bin/env python3
"""Generate mock HealthKit-like JSON payloads for RiskCalculator testing."""

import json
import random
from datetime import datetime, timezone

SCENARIOS = [
    {
        "name": "high_anxiety_dropping_steps",
        "demographics": {"age": 32, "sex": "female", "smokingStatus": "never"},
        "weeklySteps": 3500,
        "priorWeeklySteps": 7200,
        "restingHeartRate": 76,
        "sleepHoursAvg": 5.2,
        "phq9Score": 8,
        "gad7Score": 14,
        "bmi": 24.5,
        "physicalActivityMinutes": 20,
    },
    {
        "name": "low_risk_active",
        "demographics": {"age": 28, "sex": "male", "smokingStatus": "never"},
        "weeklySteps": 9500,
        "priorWeeklySteps": 9100,
        "restingHeartRate": 62,
        "sleepHoursAvg": 7.5,
        "phq9Score": 2,
        "gad7Score": 1,
        "bmi": 22.0,
        "physicalActivityMinutes": 180,
    },
    {
        "name": "metabolic_moderate_sedentary",
        "demographics": {"age": 58, "sex": "male", "smokingStatus": "former"},
        "weeklySteps": 2800,
        "priorWeeklySteps": 3100,
        "restingHeartRate": 74,
        "sleepHoursAvg": 6.0,
        "phq9Score": 6,
        "gad7Score": 4,
        "bmi": 31.2,
        "physicalActivityMinutes": 15,
    },
]


def generate_random_payload() -> dict:
    return {
        "name": "random",
        "demographics": {
            "age": random.randint(25, 70),
            "sex": random.choice(["male", "female", "other"]),
            "smokingStatus": random.choice(["never", "former", "current"]),
        },
        "weeklySteps": random.randint(2000, 12000),
        "priorWeeklySteps": random.randint(2000, 12000),
        "restingHeartRate": round(random.uniform(58, 88), 1),
        "sleepHoursAvg": round(random.uniform(4.5, 8.5), 1),
        "phq9Score": random.randint(0, 22),
        "gad7Score": random.randint(0, 18),
        "bmi": round(random.uniform(19, 36), 1),
        "physicalActivityMinutes": random.randint(0, 300),
        "generatedAt": datetime.now(timezone.utc).isoformat(),
    }


def main() -> None:
    payloads = SCENARIOS + [generate_random_payload() for _ in range(3)]
    print(json.dumps(payloads, indent=2))


if __name__ == "__main__":
    main()

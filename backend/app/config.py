"""Central configuration for the assessment module.

All scoring thresholds live here so they can be reviewed and calibrated
(with your supervisor / a clinician) without touching the scoring code.
"""

APP_NAME = "Early Development Assistant API"
API_PREFIX = "/api/v1"

# Supported child age range: 0-5 years (up to, but not including, 72 months)
MIN_AGE_MONTHS = 0
MAX_AGE_MONTHS = 71

# --- Scoring thresholds (PROTOTYPE - calibrate before real-world use) -------
# Points per answered question: 0 (no concern), 1 (some concern), 2 (concern)
MAX_POINTS_PER_QUESTION = 2

# Overall concern level from overall percentage of possible points
OVERALL_MODERATE_THRESHOLD = 0.20   # >= 20%  -> Moderate
OVERALL_HIGH_THRESHOLD = 0.40       # >= 40%  -> High

# A single domain this high escalates the overall level to at least Moderate
DOMAIN_ESCALATION_THRESHOLD = 0.67
DOMAIN_ESCALATION_MIN_ANSWERED = 2

# Red flags: 1 triggered -> at least Moderate, 2 or more -> High
RED_FLAGS_FOR_MODERATE = 1
RED_FLAGS_FOR_HIGH = 2

# Data quality
MIN_ANSWERED_FRACTION = 0.60        # below this -> "insufficient_data"
UNSURE_CLARIFICATION_FRACTION = 0.25  # more "not sure" than this -> low confidence

DISCLAIMER = (
    "This tool does not provide a medical diagnosis. It only highlights "
    "possible developmental concerns based on what you reported. Only a "
    "qualified healthcare professional can evaluate a child's development."
)

"""Rule-based personalised guidance (Module 1, feature 11 + consultation guidance).

These are general, low-risk parent-support ideas. They are NOT medical advice
and NOT therapy. Review wording with your supervisor before final release.
"""

from typing import Dict, List

from app.modules.assessment.schemas import Consultation, ConcernLevel, GuidanceItem

DOMAIN_TIPS: Dict[str, Dict[str, List[str]]] = {
    "communication": {
        "title": "Support communication",
        "tips": [
            "Talk about what you and your child are doing during routines (bath, meals, play).",
            "Pause and wait a few seconds after you speak so your child has time to respond.",
            "Repeat and gently expand what they say (child: 'ball' -> you: 'big red ball').",
            "Read picture books together daily and name the pictures.",
        ],
    },
    "social": {
        "title": "Encourage social interaction",
        "tips": [
            "Play face-to-face games such as peek-a-boo, songs with actions and turn-taking games.",
            "Get down to your child's eye level and follow their lead in play.",
            "Arrange short, relaxed play time with familiar children or family members.",
            "Name feelings during the day ('You look happy!', 'That made you sad').",
        ],
    },
    "cognitive": {
        "title": "Build thinking and learning skills",
        "tips": [
            "Offer simple hide-and-find games, shape sorters, stacking toys and age-suitable puzzles.",
            "Encourage pretend play with everyday objects (cups, dolls, toy phones).",
            "Let your child explore safely, and ask simple questions about what they see.",
        ],
    },
    "motor": {
        "title": "Strengthen movement skills",
        "tips": [
            "Give plenty of safe floor time and outdoor play for crawling, walking, climbing and running.",
            "Offer finger-friendly activities such as scribbling, playdough, threading large beads, self-feeding.",
            "Make movement a game: dancing, ball play, obstacle courses made from cushions.",
        ],
    },
    "behavioral": {
        "title": "Understand everyday behaviours",
        "tips": [
            "Keep a short daily note of when the behaviours happen, how long they last and what came before.",
            "Keep routines predictable and prepare your child before changes ('first bath, then story').",
            "Offer calm, quiet breaks if your child seems overwhelmed by noise or touch.",
            "Share your notes with your child's doctor or health visitor at the next visit.",
        ],
    },
}


def build_guidance(domain_levels: Dict[str, ConcernLevel], domain_pcts: Dict[str, float]) -> List[GuidanceItem]:
    """Return guidance for domains showing any concern, highest first.

    If no domain shows concern, return a single general-encouragement item.
    """
    concerned = [d for d, pct in domain_pcts.items() if pct >= 0.20]
    concerned.sort(key=lambda d: domain_pcts[d], reverse=True)

    items = [
        GuidanceItem(domain=d, title=DOMAIN_TIPS[d]["title"], tips=DOMAIN_TIPS[d]["tips"])
        for d in concerned
    ]
    if not items:
        items.append(
            GuidanceItem(
                domain="general",
                title="Keep supporting your child's development",
                tips=[
                    "Keep talking, reading, singing and playing with your child every day.",
                    "Repeat this check regularly as your child grows, and attend routine child health visits.",
                ],
            )
        )
    return items


def build_consultation(level: ConcernLevel, red_flag_count: int, insufficient: bool) -> Consultation:
    if insufficient:
        return Consultation(
            recommended=False,
            urgency="routine",
            message=(
                "There were not enough answered questions to give a reliable result. "
                "Try again after observing your child using the tips shown, or speak with "
                "your child's doctor if you are unsure."
            ),
        )
    if level == ConcernLevel.high or red_flag_count >= 2:
        return Consultation(
            recommended=True,
            urgency="prompt",
            message=(
                "Several of your answers suggest developmental concerns. Please book an "
                "appointment with a paediatrician or child-development specialist soon and "
                "share these results. This is not a diagnosis; a professional assessment is "
                "the right next step."
            ),
        )
    if level == ConcernLevel.moderate or red_flag_count == 1:
        return Consultation(
            recommended=True,
            urgency="soon",
            message=(
                "Some answers suggest areas worth discussing with a healthcare professional. "
                "Consider mentioning them at your next child health visit, and try the "
                "home activities suggested meanwhile."
            ),
        )
    return Consultation(
        recommended=False,
        urgency="routine",
        message=(
            "Your answers do not show notable concerns right now. Continue regular check-ups "
            "and talk to a professional any time you are worried about your child's development."
        ),
    )

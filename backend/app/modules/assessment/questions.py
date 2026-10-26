"""Age-based question bank for Module 1.

IMPORTANT: this is a PROTOTYPE question bank written in original wording,
organised around widely used developmental-milestone domains. Before real
use, have it reviewed against validated tools (e.g. CDC developmental
milestones, M-CHAT-R/F for 16-30 months) by your supervisor / a clinician.

Each question is answered on a frequency scale:
    usually | sometimes | rarely | not_sure

polarity:
    "skill"   -> a positive milestone; "rarely" means more concern.
    "concern" -> a possible warning behaviour; "usually" means more concern.

red_flag: a single concerning answer on this item matters more than usual.
clarify:  a short "how to observe this" tip shown when the parent picks
          "not sure" (this powers the committee's clarification feature).
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional

DOMAINS = ["communication", "social", "cognitive", "motor", "behavioral"]

DOMAIN_LABELS = {
    "communication": "Communication",
    "social": "Social Interaction",
    "cognitive": "Cognitive Development",
    "motor": "Motor Development",
    "behavioral": "Behavioral Indicators",
}

ANSWER_CHOICES = ["usually", "sometimes", "rarely", "not_sure"]


@dataclass(frozen=True)
class AgeBand:
    id: str
    label: str
    min_months: int
    max_months: int


AGE_BANDS: List[AgeBand] = [
    AgeBand("0_5m", "0-5 months", 0, 5),
    AgeBand("6_11m", "6-11 months", 6, 11),
    AgeBand("12_23m", "12-23 months", 12, 23),
    AgeBand("24_35m", "2-3 years (24-35 months)", 24, 35),
    AgeBand("36_71m", "3-5 years (36-71 months)", 36, 71),
]


@dataclass(frozen=True)
class Question:
    id: str
    band_id: str
    domain: str
    text: str
    polarity: str  # "skill" | "concern"
    clarify: str
    red_flag: bool = False


def _q(band, n, domain, text, polarity, clarify, red_flag=False) -> Question:
    return Question(
        id=f"{band}_{domain[:3]}{n}",
        band_id=band,
        domain=domain,
        text=text,
        polarity=polarity,
        clarify=clarify,
        red_flag=red_flag,
    )


S, C = "skill", "concern"

QUESTIONS: List[Question] = [
    # ------------------------------------------------------------ 0-5 months
    _q("0_5m", 1, "communication", "Makes cooing or gurgling sounds when you talk or smile at them.", S,
       "Talk to your baby in a happy voice for a minute and watch for little sounds back."),
    _q("0_5m", 2, "communication", "Cries in different ways for different needs (hungry, tired, uncomfortable).", S,
       "Over a day, notice whether the cries sound different before feeds versus before sleep."),
    _q("0_5m", 3, "communication", "Turns their head or eyes toward your voice.", S,
       "When your baby is calm, speak softly from the side (out of sight) and see if they turn."),
    _q("0_5m", 1, "social", "Smiles back at you or smiles on their own when they see your face.", S,
       "Smile and talk to your baby face to face when they are calm and alert."),
    _q("0_5m", 2, "social", "Looks at your face while being fed or talked to.", S,
       "During feeding, notice whether your baby looks up at your face from time to time."),
    _q("0_5m", 3, "social", "Calms down when picked up, held, or spoken to softly.", S,
       "Next time your baby is fussy, pick them up and speak gently and see how they respond."),
    _q("0_5m", 1, "cognitive", "Follows a moving face or object with their eyes.", S,
       "Hold a bright toy about 20-30 cm from their face and move it slowly side to side."),
    _q("0_5m", 2, "cognitive", "Shows interest in a bright toy or object held in front of them.", S,
       "Show a colourful toy and watch whether they look at it, reach, or get excited."),
    _q("0_5m", 1, "motor", "Lifts their head briefly when lying on their tummy.", S,
       "Supervised tummy time on a firm surface; watch whether they lift their head."),
    _q("0_5m", 2, "motor", "Moves both arms and both legs in a smooth, balanced way.", S,
       "Watch your baby lying on their back and see if both sides move about equally."),
    _q("0_5m", 1, "behavioral", "Is very hard to soothe most of the time, even when their needs are met.", C,
       "Think about the past week: how often did nothing seem to settle your baby?"),
    _q("0_5m", 2, "behavioral", "Avoids looking at faces or looks away from people much of the time.", C,
       "Hold your baby close and notice how often they look at your face versus away."),

    # ----------------------------------------------------------- 6-11 months
    _q("6_11m", 1, "communication", "Babbles with different sounds such as 'ba', 'da' or 'ma'.", S,
       "Listen during play for repeated consonant sounds, not just cooing."),
    _q("6_11m", 2, "communication", "Turns toward you when you call their name.", S,
       "Call your baby's name from behind or the side in a normal voice when they are busy playing."),
    _q("6_11m", 3, "communication", "Uses gestures such as reaching up to be picked up, or waving.", S,
       "Notice what your baby does when they want to be lifted or want something out of reach."),
    _q("6_11m", 1, "social", "Enjoys simple games like peek-a-boo and responds with smiles or sounds.", S,
       "Play peek-a-boo for a minute and watch their reaction."),
    _q("6_11m", 2, "social", "Looks at you to see your reaction when something new happens.", S,
       "When a new toy or sound appears, see whether they glance at your face."),
    _q("6_11m", 3, "social", "Reacts differently to familiar people compared with strangers.", S,
       "Notice how they behave with you versus someone they rarely see."),
    _q("6_11m", 1, "cognitive", "Looks for a toy that you hide or that falls out of sight.", S,
       "Partly cover a toy with a cloth while they watch and see if they search for it."),
    _q("6_11m", 2, "cognitive", "Explores toys by banging, shaking, passing hand to hand or putting them in the mouth.", S,
       "Give a safe toy and watch how they explore it."),
    _q("6_11m", 1, "motor", "Sits with little or no support (or is working toward it).", S,
       "Sit your baby on a soft surface and see how long they stay up."),
    _q("6_11m", 2, "motor", "Reaches for and grasps toys, and can pick up small soft food with fingers.", S,
       "Offer a toy and a small piece of soft food and see how they pick them up."),
    _q("6_11m", 1, "behavioral", "Seems very upset by ordinary sounds, textures or touch.", C,
       "Think about everyday sounds (vacuum, blender) or clothes; how strongly do they react?"),
    _q("6_11m", 2, "behavioral", "Repeats the same body movement (e.g. flapping hands, rocking) for long periods.", C,
       "Notice whether such movements last long and are hard to interrupt."),

    # ---------------------------------------------------------- 12-23 months
    _q("12_23m", 1, "communication", "Says a few words with meaning (such as 'mama', 'dada', 'more' or 'ball').", S,
       "Listen for words used on purpose for a person or object, not random sounds."),
    _q("12_23m", 2, "communication", "Points to things to show you or to ask for them.", S,
       "Notice what they do when they want something across the room or see an interesting animal."),
    _q("12_23m", 3, "communication", "Understands simple requests such as 'give me' or 'come here' without gestures.", S,
       "Try a simple request without pointing or showing, and see if they follow it."),
    _q("12_23m", 1, "social", "Looks up or turns when you call their name.", S,
       "Call their name in a normal voice while they are playing, from a short distance.", True),
    _q("12_23m", 2, "social", "Looks where you point or look when you say 'look at that!'.", S,
       "Point to a toy or animal across the room and watch whether they look at it.", True),
    _q("12_23m", 3, "social", "Brings things to show you, or copies actions such as waving or clapping.", S,
       "Wave bye-bye or clap and see if they copy; notice if they bring you things to show."),
    _q("12_23m", 1, "cognitive", "Finds a toy hidden under a cloth or behind something.", S,
       "Hide a toy while they watch and see if they look for it."),
    _q("12_23m", 2, "cognitive", "Uses everyday objects in the right way (cup, spoon, brush, toy phone).", S,
       "Hand them a spoon or brush and watch what they do with it."),
    _q("12_23m", 1, "motor", "Pulls up to stand, cruises along furniture or walks (depending on age).", S,
       "Place a toy on a low table and see how they move to reach it."),
    _q("12_23m", 2, "motor", "Picks up small objects using thumb and finger, or scribbles with a crayon.", S,
       "Offer a crayon and small safe pieces of food and watch how they hold them."),
    _q("12_23m", 1, "behavioral", "Spends long periods lining up or spinning objects instead of playing with them in usual ways.", C,
       "Notice if play is mostly lining up/spinning, and whether you can get them to try something else."),
    _q("12_23m", 2, "behavioral", "Has stopped using words, gestures or skills they used to have.", C,
       "Compare with a few months ago: is there any skill or word they no longer use?", True),

    # ---------------------------------------------------------- 24-35 months
    _q("24_35m", 1, "communication", "Puts two words together (e.g. 'more milk', 'daddy go').", S,
       "Listen to them during play or meals for short two-word phrases."),
    _q("24_35m", 2, "communication", "Uses many different words, and people outside the family understand some of them.", S,
       "Ask a relative or friend how much they understand when your child speaks."),
    _q("24_35m", 3, "communication", "Follows two-step instructions (e.g. 'get your shoes and bring them here').", S,
       "Give a simple two-step request without gestures and see what they do."),
    _q("24_35m", 1, "social", "Shows interest in other children, and plays near or with them.", S,
       "Think about playground or family settings: do they watch, approach or join other children?"),
    _q("24_35m", 2, "social", "Copies other people, including pretend actions (feeding a doll, 'cooking').", S,
       "Start a pretend game (e.g. pretend to drink from a cup) and see if they join in."),
    _q("24_35m", 3, "social", "Shares enjoyment with you: points to or shows things and looks at your face.", S,
       "Notice if they show you toys or interesting things and check your reaction.", True),
    _q("24_35m", 1, "cognitive", "Does simple puzzles or sorts shapes, or stacks several blocks.", S,
       "Give a shape sorter or blocks and see how they try to solve it."),
    _q("24_35m", 2, "cognitive", "Plays pretend with toys (e.g. puts a doll to bed, 'drives' a car).", S,
       "Watch free play: do toys 'do' things, or are they mostly handled or lined up?"),
    _q("24_35m", 1, "motor", "Runs, kicks a ball, and climbs stairs or low steps.", S,
       "Watch them at play and on steps."),
    _q("24_35m", 2, "motor", "Turns book pages, stacks small blocks, or holds a crayon to draw lines.", S,
       "Offer a book and blocks or crayons and watch hand use."),
    _q("24_35m", 1, "behavioral", "Becomes extremely upset by small changes in routine, much more than other children.", C,
       "Think about changes (different route, different cup): how intense and long are the reactions?"),
    _q("24_35m", 2, "behavioral", "Repeats words or phrases they heard (e.g. from videos) without using them to communicate.", C,
       "Notice if repeated phrases are used to ask or comment, or just repeated."),

    # ---------------------------------------------------------- 36-71 months
    _q("36_71m", 1, "communication", "Speaks in sentences of three or more words.", S,
       "Listen during a meal or play for full sentences."),
    _q("36_71m", 2, "communication", "People outside the family can understand most of what they say.", S,
       "Ask a teacher, relative or neighbour how well they understand your child."),
    _q("36_71m", 3, "communication", "Can tell you what happened, or answer simple 'what' and 'why' questions.", S,
       "After an outing, ask 'what did we see?' or 'why did we...?' and see how they answer."),
    _q("36_71m", 1, "social", "Plays with other children, takes turns and joins group games.", S,
       "Think about playdates, nursery or playground: do they play with others or mostly alone?"),
    _q("36_71m", 2, "social", "Shows concern or tries to comfort when someone is sad or hurt.", S,
       "Think of a time someone cried or got hurt; what did your child do?"),
    _q("36_71m", 3, "social", "Has back-and-forth conversations and makes eye contact when talking to you.", S,
       "Ask about their day and see whether they respond and look at you during the exchange.", True),
    _q("36_71m", 1, "cognitive", "Names some colours and counts a few objects.", S,
       "Ask them to name colours of toys and count items on a table."),
    _q("36_71m", 2, "cognitive", "Draws or copies simple shapes (circle, cross) or a simple person.", S,
       "Give paper and a crayon and ask them to draw a circle or a person."),
    _q("36_71m", 1, "motor", "Hops, balances on one foot for a moment, or climbs playground equipment.", S,
       "Watch at the playground or ask them to try hopping or standing on one foot."),
    _q("36_71m", 2, "motor", "Uses a spoon or fork, handles buttons or zips, and holds a crayon with fingers.", S,
       "Watch at mealtime and while dressing."),
    _q("36_71m", 1, "behavioral", "Has very strong, narrow interests or fixations that get in the way of daily activities.", C,
       "Think about whether one topic or object dominates play and makes other activities hard."),
    _q("36_71m", 2, "behavioral", "Repeats movements such as hand-flapping, spinning or rocking, or has lost skills they used to have.", C,
       "Notice how often and how long these happen, and compare with a few months ago.", True),
]

# ---------------------------------------------------------------- helpers
_BY_ID: Dict[str, Question] = {q.id: q for q in QUESTIONS}


def get_band_for_age(age_months: int) -> Optional[AgeBand]:
    for band in AGE_BANDS:
        if band.min_months <= age_months <= band.max_months:
            return band
    return None


def get_questions_for_band(band_id: str) -> List[Question]:
    return [q for q in QUESTIONS if q.band_id == band_id]


def get_question(question_id: str) -> Optional[Question]:
    return _BY_ID.get(question_id)

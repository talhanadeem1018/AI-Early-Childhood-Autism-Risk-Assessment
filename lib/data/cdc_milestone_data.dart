/// Age-specific developmental milestones transcribed from the CDC
/// "Learn the Signs. Act Early." online milestone checklists.
///
/// These are developmental-monitoring milestones (most children, at least
/// 75%, can do them by the listed age). They are NOT a validated autism or
/// developmental screening instrument and must not be converted into a
/// diagnostic/risk score.
///
/// Source pages are stored per age group for attribution and review.
class CdcMilestoneData {
  CdcMilestoneData._();

  static const String generalSource =
      'https://www.cdc.gov/act-early/digital-online-checklist/';

  static const Map<int, Map<String, List<String>>> _checklists = {
    12: {
      'Social/Emotional': ['Plays games with you, like pat-a-cake'],
      'Language/Communication': [
        'Waves “bye-bye”',
        'Calls a parent “mama” or “dada” or another special name',
        'Understands “no” (pauses briefly or stops when you say it)',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Puts something in a container, like a block in a cup',
        'Looks for things he sees you hide, like a toy under a blanket',
      ],
      'Movement/Physical Development': [
        'Pulls up to stand',
        'Walks, holding on to furniture',
        'Drinks from a cup without a lid, as you hold it',
        'Picks things up between thumb and pointer finger, like small bits of food',
      ],
    },
    15: {
      'Social/Emotional': [
        'Copies other children while playing, like taking toys out of a container when another child does',
        'Shows you an object she likes',
        'Claps when excited',
        'Hugs stuffed doll or other toy',
        'Shows you affection (hugs, cuddles, or kisses you)',
      ],
      'Language/Communication': [
        'Tries to say one or two words besides “mama” or “dada,” like “ba” for ball or “da” for dog',
        'Looks at a familiar object when you name it',
        'Follows directions given with both a gesture and words. For example, she gives you a toy when you hold out your hand and say, “Give me the toy.”',
        'Points to ask for something or to get help',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Tries to use things the right way, like a phone, cup, or book',
        'Stacks at least two small objects, like blocks',
      ],
      'Movement/Physical Development': [
        'Takes a few steps on his own',
        'Uses fingers to feed herself some food',
      ],
    },
    18: {
      'Social/Emotional': [
        'Moves away from you, but looks to make sure you are close by',
        'Points to show you something interesting',
        'Puts hands out for you to wash them',
        'Looks at a few pages in a book with you',
        'Helps you dress him by pushing arm through sleeve or lifting up foot',
      ],
      'Language/Communication': [
        'Tries to say three or more words besides “mama” or “dada”',
        'Follows one-step directions without any gestures, like giving you the toy when you say, “Give it to me.”',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Copies you doing chores, like sweeping with a broom',
        'Plays with toys in a simple way, like pushing a toy car',
      ],
      'Movement/Physical Development': [
        'Walks without holding on to anyone or anything',
        'Scribbles',
        'Drinks from a cup without a lid and may spill sometimes',
        'Feeds himself with his fingers',
        'Tries to use a spoon',
        'Climbs on and off a couch or chair without help',
      ],
    },
    24: {
      'Social/Emotional': [
        'Notices when others are hurt or upset, like pausing or looking sad when someone is crying',
        'Looks at your face to see how to react in a new situation',
      ],
      'Language/Communication': [
        'Points to things in a book when you ask, like “Where is the bear?”',
        'Says at least two words together, like “More milk.”',
        'Points to at least two body parts when you ask him to show you',
        'Uses more gestures than just waving and pointing, like blowing a kiss or nodding yes',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Holds something in one hand while using the other hand; for example, holding a container and taking the lid off',
        'Tries to use switches, knobs, or buttons on a toy',
        'Plays with more than one toy at the same time, like putting toy food on a toy plate',
      ],
      'Movement/Physical Development': [
        'Kicks a ball',
        'Runs',
        'Walks (not climbs) up a few stairs with or without help',
        'Eats with a spoon',
      ],
    },
    30: {
      'Social/Emotional': [
        'Plays next to other children and sometimes plays with them',
        'Shows you what she can do by saying, “Look at me!”',
        'Follows simple routines when told, like helping to pick up toys when you say, “It’s clean-up time.”',
      ],
      'Language/Communication': [
        'Says about 50 words',
        'Says two or more words together, with one action word, like “Doggie run”',
        'Names things in a book when you point and ask, “What is this?”',
        'Says words like “I,” “me,” or “we”',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Uses things to pretend, like feeding a block to a doll as if it were food',
        'Shows simple problem-solving skills, like standing on a small stool to reach something',
        'Follows two-step instructions like “Put the toy down and close the door.”',
        'Shows he knows at least one color, like pointing to a red crayon when you ask, “Which one is red?”',
      ],
      'Movement/Physical Development': [
        'Uses hands to twist things, like turning doorknobs or unscrewing lids',
        'Takes some clothes off by himself, like loose pants or an open jacket',
        'Jumps off the ground with both feet',
        'Turns book pages, one at a time, when you read to her',
      ],
    },
    36: {
      'Social/Emotional': [
        'Calms down within 10 minutes after you leave her, like at a childcare drop off',
        'Notices other children and joins them to play',
      ],
      'Language/Communication': [
        'Talks with you in conversation using at least two back-and-forth exchanges',
        'Asks “who,” “what,” “where,” or “why” questions, like “Where is mommy/daddy?”',
        'Says what action is happening in a picture or book when asked, like “running,” “eating,” or “playing”',
        'Says first name, when asked',
        'Talks well enough for others to understand, most of the time',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Draws a circle, when you show him how',
        'Avoids touching hot objects, like a stove, when you warn her',
      ],
      'Movement/Physical Development': [
        'Strings items together, like large beads or macaroni',
        'Puts on some clothes by himself, like loose pants or a jacket',
        'Uses a fork',
      ],
    },
    48: {
      'Social/Emotional': [
        'Pretends to be something else during play (teacher, superhero, dog)',
        'Asks to go play with children if none are around, like “Can I play with Alex?”',
        'Comforts others who are hurt or sad, like hugging a crying friend',
        'Avoids danger, like not jumping from tall heights at the playground',
        'Likes to be a “helper”',
        'Changes behavior based on where she is (place of worship, library, playground)',
      ],
      'Language/Communication': [
        'Says sentences with four or more words',
        'Says some words from a song, story, or nursery rhyme',
        'Talks about at least one thing that happened during his day, like “I played soccer.”',
        'Answers simple questions like “What is a coat for?” or “What is a crayon for?”',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Names a few colors of items',
        'Tells what comes next in a well-known story',
        'Draws a person with three or more body parts',
      ],
      'Movement/Physical Development': [
        'Catches a large ball most of the time',
        'Serves herself food or pours water, with adult supervision',
        'Unbuttons some buttons',
        'Holds crayon or pencil between fingers and thumb (not a fist)',
      ],
    },
    60: {
      'Social/Emotional': [
        'Follows rules or takes turns when playing games with other children',
        'Sings, dances, or acts for you',
        'Does simple chores at home, like matching socks or clearing the table after eating',
      ],
      'Language/Communication': [
        'Tells a story she heard or made up with at least two events. For example, a cat was stuck in a tree and a firefighter saved it',
        'Answers simple questions about a book or story after you read or tell it to him',
        'Keeps a conversation going with more than three back-and-forth exchanges',
        'Uses or recognizes simple rhymes (bat-cat, ball-tall)',
      ],
      'Cognitive (learning, thinking, problem-solving)': [
        'Counts to 10',
        'Names some numbers between 1 and 5 when you point to them',
        'Uses words about time, like “yesterday,” “tomorrow,” “morning,” or “night”',
        'Pays attention for 5 to 10 minutes during activities. For example, during story time or making arts and crafts (screen time does not count)',
        'Writes some letters in her name',
        'Names some letters when you point to them',
      ],
      'Movement/Physical Development': [
        'Buttons some buttons',
        'Hops on one foot',
      ],
    },
  };

  static const Map<int, String> sourceUrls = {
    12: 'https://www.cdc.gov/act-early/digital-online-checklist/1-year.html',
    15: 'https://www.cdc.gov/act-early/digital-online-checklist/15-months.html',
    18: 'https://www.cdc.gov/act-early/digital-online-checklist/18-months.html',
    24: 'https://www.cdc.gov/act-early/digital-online-checklist/2-years.html',
    30: 'https://www.cdc.gov/act-early/digital-online-checklist/30-months.html',
    36: 'https://www.cdc.gov/act-early/digital-online-checklist/3-years.html',
    48: 'https://www.cdc.gov/act-early/digital-online-checklist/4-years.html',
    60: 'https://www.cdc.gov/act-early/digital-online-checklist/5-years.html',
  };

  static int checklistAgeFor(int ageInMonths) {
    final ages = _checklists.keys.toList()..sort();
    var selected = ages.first;
    for (final age in ages) {
      if (age > ageInMonths) break;
      selected = age;
    }
    return selected;
  }

  static Map<String, List<String>> checklistForAge(int ageInMonths) {
    final age = checklistAgeFor(ageInMonths);
    return _checklists[age]!;
  }

  static String sourceForAge(int ageInMonths) =>
      sourceUrls[checklistAgeFor(ageInMonths)]!;

  static int checklistAgeMonths(int ageInMonths) =>
      checklistAgeFor(ageInMonths);
}

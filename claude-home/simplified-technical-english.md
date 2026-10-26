# Simplified Technical English (ASD-STE100)

Distilled from ASD-STE100 Issue 9, January 2025 — the controlled-English standard published by the Aerospace, Security and Defence Industries Association of Europe. The full specification is listed in the dotfiles repository under `resources/README.md`, which records where to download it. This file is the working subset: Part 1 (the 65 writing rules) plus the general recommendations. Part 2 is the dictionary and is not reproduced here.

STE exists to make technical text unambiguous for readers whose first language is not English. It governs *what you write*, not how it looks: it deliberately says nothing about typography, numbering, abbreviations, or units of measurement.

## The core idea

- One word, one meaning, one part of speech. The dictionary approves 875 words and lists 1274 unapproved words, each with an approved alternative. Where English offers synonyms, STE picks one: `start`, never `begin`, `commence`, `initiate`, or `originate`. Where a word has several senses, STE approves one: `fall` means "move down by the force of gravity", not "decrease".
- Beyond that core vocabulary, the writer adds **technical nouns** and **technical verbs** — the terms of the domain being documented.
- American English spelling and punctuation, per Merriam-Webster.

## Words — rules 1.1 thru 1.14

- Use only approved dictionary words, technical nouns, and technical verbs (1.1).
- Use an approved word only as its listed part of speech, only with its approved meaning, and only in its approved forms (1.2 thru 1.4).
- A word outside the dictionary is permitted only as a technical noun or part of one (1.5, 1.6). Keep technical nouns short and recognizable, use the terms your field already approves, and never use two different names for the same item (1.8 thru 1.11). No slang, jargon, or regionalisms (1.10).
- Do not use a technical noun as a verb (1.7), and do not use a technical verb as a noun (1.13). Domain verbs are otherwise permitted (1.12).
- Use American English spelling (1.14).

## Multi-word nouns — rules 2.1, 2.2

- A multi-word noun is at most three words (2.1). `Runway light connection` is permitted; `runway light connection resistance calibration` is not — the reader must hold four modifiers before reaching the head noun.
- When a technical term genuinely needs more than three words, write it in full once, then either give a shorter form or hyphenate the words that act as one unit (2.2).
- Break long strings apart with prepositions or a relative clause: not `Remove the engine transmission housing attachment bolts`, but `Remove the bolts that attach the transmission housing to the engine`.

## Verbs — rules 3.1 thru 3.7

- Use only the verb forms the dictionary gives (3.1), and only these: infinitive, imperative, simple present, simple past, simple future, and the past participle used as an adjective (3.2, 3.3).
- Do not build complex constructions out of auxiliary verbs (3.4).
- Use an `-ing` form only as a technical noun or as a modifier inside one (3.5).
- Use the active voice. The passive is permitted only in descriptive writing, and only when the agent is unknown (3.6).
- Describe an action with an approved verb, not with a noun or another part of speech (3.7): `Seal the opening with tool TS9867`, not `Use tool TS9867 to seal the opening` — the primary action is "seal".

## Sentences — rules 4.1 thru 4.5

- Write short, clear sentences (4.1), but do not shorten them by omitting words or using contractions (4.2).
- Use a vertical list when the content is complex (4.3).
- Connect sentences on related topics with connecting words and phrases (4.4).
- Put an article (`the`, `a`, `an`) or a demonstrative adjective (`this`, `these`) before a noun or multi-word noun wherever one applies (4.5).

## Procedural writing — rules 5.1 thru 5.5

- Maximum 20 words per sentence (5.1). Warnings and cautions obey this limit too.
- One instruction per sentence, unless two actions genuinely happen at the same time (5.2).
- Write instructions in the imperative (5.3).
- When the reader must know a condition first, lead with it as a descriptive statement, then a comma, then the command (5.4).
- Notes give information only, never instructions (5.5).

## Descriptive writing — rules 6.1 thru 6.6

- Give information gradually; one subject per sentence (6.1).
- Use key words and key phrases to give the text a logical structure (6.2).
- Maximum 25 words per sentence (6.3).
- A paragraph groups related information, carries exactly one topic, and holds no more than six sentences (6.4 thru 6.6).
- The imperative is not permitted in descriptive text.

## Safety instructions — rules 7.1 thru 7.3

- Identify the level of risk with a word such as `warning` (risk of injury or death) or `caution` (risk of damage to objects) (7.1).
- Start with a clear, accurate command or condition (7.2).
- Then explain the risk or the possible result (7.3).

## Punctuation and word count — rules 8.1 thru 8.7

- All standard English punctuation is permitted except the semicolon (8.1).
- Hyphens join words that are directly related (8.2).
- Parentheses are for references to text or illustrations, item callouts, step identifiers, abbreviations, singular-and-plural forms, short explanations, and alternatives (8.3).
- Counting words against the 20- and 25-word limits: a colon in a vertical list ends a sentence (8.4); parenthetical text counts as one word (8.5); hyphenated words count as one (8.7); and each of these counts as one word — numbers, a number with its unit, abbreviations, alphanumeric identifiers, quoted text, titles, headings, placards, labels, and proper nouns of people, groups, organizations, and geopolitical entities (8.6).

## Writing practices — rules 9.1 thru 9.4

- When a word-for-word replacement will not carry the meaning, recast the sentence (9.1).
- Use each approved word correctly, in its approved sense (9.2).
- Do not combine two words into a phrasal verb (9.3).
- Keep terminology and wording consistent throughout (9.4).

## General recommendations

- **GR-1 — `that`**: keep the conjunction. `Make sure that the valve is open`, not `Make sure the valve is open`. It marks where the main clause ends, and most languages cannot drop its equivalent.
- **GR-2 — `with`**: re-read every sentence containing it. `Install the panel with the green fasteners` has three readings.
- **GR-3 — pronouns**: use only approved ones. If a pronoun could refer to more than one noun, replace it with the noun itself.
- **GR-4 — `this`**: the referent must be unmistakable; restate the context rather than leaning on it.
- **GR-5 — false friends**: a word that resembles one in the reader's language may not mean what it appears to.
- **GR-6 — Latin abbreviations**: write `for example`, `that is`, and `and so on` instead of `e.g.`, `i.e.`, and `etc.`
- **GR-7 — inclusive language**: STE is gender-neutral by construction; `he`, `she`, `man`, and `woman` are not permitted outside contexts that require them.
- **GR-8 — possessive form**: `the manufacturer's instructions` is permitted, but drop it whenever the sentence is not obviously correct — many languages have no equivalent.

## What STE does not cover

Abbreviations, text formatting, and units of measurement are explicitly out of scope, as are general punctuation conventions. STE is not meant to stand alone: it is used alongside a style guide and the applicable publication specification. It was written for technical documentation, not for conversation, though its rules also help in speech.

## Applying it

This is a reference, not an instruction to rewrite everything in it. Reach for it when writing prose that must be unambiguous to a wide or non-native audience — documentation, READMEs, help text, error messages, commit messages, API descriptions. The rules that pay off almost everywhere: active voice, one instruction per sentence, short sentences, consistent terminology, keeping `that`, no Latin abbreviations, and multi-word nouns of three words or fewer.

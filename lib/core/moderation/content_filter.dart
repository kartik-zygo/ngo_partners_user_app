/// Client-side filter for objectionable language in Community posts and
/// replies (App Store guideline 1.2). It stops members from publishing
/// matching text and hides matching content that is already on the server.
///
/// Matching runs on a normalised copy of the text: lower-cased, common
/// look-alike characters mapped back to letters (`$h1t` → `shit`) and
/// stretched letters collapsed (`fuuuck` → `fuck`). Runs of two are kept so
/// that, for example, "Niger" never matches a slur.
class ContentFilter {
  ContentFilter._();

  /// Matched anywhere inside a word, so compounds and inflections are caught
  /// ("motherfucker", "bullshit"). Only stems that never occur inside an
  /// ordinary English or Hinglish word belong here.
  static const _stems = [
    'fuck', 'shit', 'bitch', 'asshole', 'arsehole', 'bastard', 'cocksuck',
    'dickhead', 'blowjob', 'handjob', 'jizz', 'dildo', 'porn', 'faggot',
    'nigger', 'nigga', 'whore', 'slut', 'motherf', 'madarchod', 'maderchod',
    'behenchod', 'bhenchod', 'benchod', 'chutiya', 'chutiye', 'bhosd',
    'haramkhor', 'jhaatu',
  ];

  /// Matched as whole words only (with an optional plural), because each is
  /// also a harmless fragment of longer words.
  static const _words = [
    'cunt', 'twat', 'wank', 'wanker', 'dick', 'pussy', 'retard', 'retarded',
    'tranny', 'dyke', 'spic', 'kike', 'jackass', 'dumbass', 'douche',
    'douchebag', 'bollocks', 'nudes', 'milf', 'chut', 'gandu', 'gaand',
    'lauda', 'lavda', 'lawda', 'lodu', 'randi', 'harami', 'bhadwa',
    'bhadwe', 'chinal', 'chodu', 'kys',
  ];

  /// Matched as whole phrases.
  static const _phrases = [
    'kill yourself', 'kill urself', 'go die', 'i will kill you',
  ];

  static const _lookalikes = {
    '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't',
    '@': 'a', r'$': 's', '!': 'i',
  };

  static final RegExp _pattern = RegExp(
    '(?:${_stems.join('|')})'
    '|\\b(?:${_words.join('|')})(?:s|es)?\\b'
    '|\\b(?:${_phrases.map((p) => p.replaceAll(' ', r'\s+')).join('|')})\\b',
  );

  static final RegExp _stretched = RegExp(r'([a-z])\1{2,}');

  static String _normalise(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_lookalikes[char] ?? char);
    }
    return buffer.toString().replaceAllMapped(_stretched, (m) => m[1]!);
  }

  /// Whether [text] contains language that is not allowed in the Community.
  static bool isObjectionable(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return _pattern.hasMatch(_normalise(text));
  }

  /// Checks several fields at once, e.g. a post's title, body and tags.
  static bool anyObjectionable(Iterable<String?> texts) =>
      texts.any(isObjectionable);
}

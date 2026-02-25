class ArmenianTransliterator {
  static const Map<String, String> _twoCharMap = {
    'ts': '\u056E', // ծ
    'zh': '\u056A', // ժ
    'dz': '\u0571', // ձ
    'tt': '\u0569', // թ
    'pp': '\u0583', // փ
    'rr': '\u057C', // ռ
    'ch': '\u0579', // չ
    'sh': '\u0577', // շ
    'cc': '\u0573', // ճ
    'gh': '\u0572', // ղ
    'ee': '\u0567', // է
    'oo': '\u0585', // օ
    'wo': '\u0578', // ո
    'ew': '\u0587', // և
  };

  static const Map<String, String> _singleCharMap = {
    'a': '\u0561', // ա
    'b': '\u0562', // բ
    'c': '\u0581', // ց
    'd': '\u0564', // դ
    'e': '\u0565', // ե
    'f': '\u0586', // ֆ
    'g': '\u0563', // գ
    'h': '\u0570', // հ
    'i': '\u056B', // ի
    'j': '\u057B', // ջ
    'k': '\u056F', // կ
    'l': '\u056C', // լ
    'm': '\u0574', // մ
    'n': '\u0576', // ն
    'o': '\u0578', // ո
    'p': '\u057A', // պ
    'q': '\u0584', // ք
    'r': '\u0580', // ր
    's': '\u057D', // ս
    't': '\u057F', // տ
    'u': '\u0578\u0582', // ու
    'w': '\u057E', // վ
    'v': '\u057E', // վ
    'x': '\u056D', // խ
    'y': '\u0575', // յ
    'z': '\u0566', // զ
    '@': '\u0568', // ը
  };

  /// Transliterate an English filename to Armenian name.
  /// Follows the same logic as create_json.sh:
  /// 1. Process two-char mappings first
  /// 2. Then single-char mappings
  /// 3. Replace underscores with spaces
  /// 4. Remove trailing digit
  static String transliterateToArmenian(String englishName) {
    String lowercase = englishName.toLowerCase();
    StringBuffer result = StringBuffer();
    int i = 0;
    while (i < lowercase.length) {
      if (i + 1 < lowercase.length) {
        String twoChars = lowercase.substring(i, i + 2);
        if (_twoCharMap.containsKey(twoChars)) {
          result.write(_twoCharMap[twoChars]);
          i += 2;
          continue;
        }
      }
      String oneChar = lowercase[i];
      result.write(_singleCharMap[oneChar] ?? oneChar);
      i++;
    }
    String name = result.toString().replaceAll('_', ' ');
    if (name.isNotEmpty && RegExp(r'[0-9]$').hasMatch(name)) {
      name = name.substring(0, name.length - 1);
    }
    return name.trim();
  }

  /// Rename English filename using the alias simplification rules from rename_names.sh.
  /// Applied in the same order as the sed expressions.
  static String renameAlias(String filename) {
    return filename
        .replaceAll('rr', 'r')
        .replaceAll('tt', 't')
        .replaceAll('cc', 'ch')
        .replaceAll('pp', 'p')
        .replaceAll('gh', 'x')
        .replaceAll('zh', 'j')
        .replaceAll('jj', 'j')
        .replaceAll('ee', 'e')
        .replaceAll('oo', 'o')
        .replaceAll('wo', 'o')
        .replaceAll('ew', 'ev')
        .replaceAll('ts', 'c');
  }

  /// Extract ordering number from filename (trailing digits).
  /// Defaults to 100 if no trailing number found.
  static int extractOrdering(String filenameWithoutExtension) {
    RegExpMatch? match = RegExp(r'(\d+)$').firstMatch(filenameWithoutExtension);
    return match != null ? int.parse(match.group(1)!) : 100;
  }
}

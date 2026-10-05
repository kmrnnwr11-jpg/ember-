/// The listing's own language: English, the one Google falls back to for a
/// country with no page of its own, so it reaches everyone.
const playMainLanguage = 'en-US';

/// Every store language Google Play has (82 besides the main English one),
/// as Google Play names them: the ten languages every Ember app speaks
/// first, then the rest. All on by default: a page in the reader's language
/// costs nothing and sells more. The English variants copy the main text.
const playStoreLanguages = <String, String>{
  'it-IT': 'Italiano',
  'es-ES': 'Español',
  'pt-BR': 'Português (BR)',
  'fr-FR': 'Français',
  'de-DE': 'Deutsch',
  'hi-IN': 'हिन्दी',
  'ar': 'العربية',
  'id': 'Bahasa Indonesia',
  'ru-RU': 'Русский',
  'tr-TR': 'Türkçe',
  'vi': 'Tiếng Việt',
  'th': 'ไทย',
  'ja-JP': '日本語',
  'ko-KR': '한국어',
  'pl-PL': 'Polski',
  'nl-NL': 'Nederlands',
  'fil': 'Filipino',
  'ms': 'Bahasa Melayu',
  'bn-BD': 'বাংলা',
  'ta-IN': 'தமிழ்',
  'te-IN': 'తెలుగు',
  'mr-IN': 'मराठी',
  'uk': 'Українська',
  'es-419': 'Español (Latinoamérica)',
  'zh-TW': '繁體中文',
  'ur': 'اردو',
  'pa': 'ਪੰਜਾਬੀ',
  'zh-CN': '简体中文',
  'zh-HK': '繁體中文 (香港)',
  'pt-PT': 'Português (PT)',
  'es-US': 'Español (EE. UU.)',
  'fr-CA': 'Français (Canada)',
  'gu': 'ગુજરાતી',
  'kn-IN': 'ಕನ್ನಡ',
  'ml-IN': 'മലയാളം',
  'ne-NP': 'नेपाली',
  'si-LK': 'සිංහල',
  'fa': 'فارسی',
  'iw-IL': 'עברית',
  'el-GR': 'Ελληνικά',
  'ro': 'Română',
  'cs-CZ': 'Čeština',
  'sk': 'Slovenčina',
  'hu-HU': 'Magyar',
  'bg': 'Български',
  'sr': 'Српски',
  'hr': 'Hrvatski',
  'sl': 'Slovenščina',
  'mk-MK': 'Македонски',
  'sq': 'Shqip',
  'sv-SE': 'Svenska',
  'da-DK': 'Dansk',
  'no-NO': 'Norsk',
  'fi-FI': 'Suomi',
  'is-IS': 'Íslenska',
  'et': 'Eesti',
  'lv': 'Latviešu',
  'lt': 'Lietuvių',
  'be': 'Беларуская',
  'ka-GE': 'ქართული',
  'hy-AM': 'Հայերեն',
  'az-AZ': 'Azərbaycan',
  'kk': 'Қазақ',
  'ky-KG': 'Кыргызча',
  'mn-MN': 'Монгол',
  'my-MM': 'မြန်မာ',
  'km-KH': 'ខ្មែរ',
  'lo-LA': 'ລາວ',
  'sw': 'Kiswahili',
  'am': 'አማርኛ',
  'zu': 'isiZulu',
  'af': 'Afrikaans',
  'ca': 'Català',
  'eu-ES': 'Euskara',
  'gl-ES': 'Galego',
  'rm': 'Rumantsch',
  'en-GB': 'English (UK)',
  'en-AU': 'English (Australia)',
  'en-CA': 'English (Canada)',
  'en-IN': 'English (India)',
  'en-SG': 'English (Singapore)',
  'en-ZA': 'English (South Africa)',
};

/// The same languages by their English name: a list in eighty scripts is
/// hard to search for someone who reads one of them. Only shown and searched,
/// never sent to Google.
const playLanguageEnglishNames = <String, String>{
  'it-IT': 'Italian',
  'es-ES': 'Spanish (Spain)',
  'pt-BR': 'Portuguese (Brazil)',
  'fr-FR': 'French',
  'de-DE': 'German',
  'hi-IN': 'Hindi',
  'ar': 'Arabic',
  'id': 'Indonesian',
  'ru-RU': 'Russian',
  'tr-TR': 'Turkish',
  'vi': 'Vietnamese',
  'th': 'Thai',
  'ja-JP': 'Japanese',
  'ko-KR': 'Korean',
  'pl-PL': 'Polish',
  'nl-NL': 'Dutch',
  'fil': 'Filipino',
  'ms': 'Malay',
  'bn-BD': 'Bengali',
  'ta-IN': 'Tamil',
  'te-IN': 'Telugu',
  'mr-IN': 'Marathi',
  'uk': 'Ukrainian',
  'es-419': 'Spanish (Latin America)',
  'zh-TW': 'Chinese (Traditional)',
  'ur': 'Urdu',
  'pa': 'Punjabi',
  'zh-CN': 'Chinese (Simplified)',
  'zh-HK': 'Chinese (Hong Kong)',
  'pt-PT': 'Portuguese (Portugal)',
  'es-US': 'Spanish (United States)',
  'fr-CA': 'French (Canada)',
  'gu': 'Gujarati',
  'kn-IN': 'Kannada',
  'ml-IN': 'Malayalam',
  'ne-NP': 'Nepali',
  'si-LK': 'Sinhala',
  'fa': 'Persian',
  'iw-IL': 'Hebrew',
  'el-GR': 'Greek',
  'ro': 'Romanian',
  'cs-CZ': 'Czech',
  'sk': 'Slovak',
  'hu-HU': 'Hungarian',
  'bg': 'Bulgarian',
  'sr': 'Serbian',
  'hr': 'Croatian',
  'sl': 'Slovenian',
  'mk-MK': 'Macedonian',
  'sq': 'Albanian',
  'sv-SE': 'Swedish',
  'da-DK': 'Danish',
  'no-NO': 'Norwegian',
  'fi-FI': 'Finnish',
  'is-IS': 'Icelandic',
  'et': 'Estonian',
  'lv': 'Latvian',
  'lt': 'Lithuanian',
  'be': 'Belarusian',
  'ka-GE': 'Georgian',
  'hy-AM': 'Armenian',
  'az-AZ': 'Azerbaijani',
  'kk': 'Kazakh',
  'ky-KG': 'Kyrgyz',
  'mn-MN': 'Mongolian',
  'my-MM': 'Burmese',
  'km-KH': 'Khmer',
  'lo-LA': 'Lao',
  'sw': 'Swahili',
  'am': 'Amharic',
  'zu': 'Zulu',
  'af': 'Afrikaans',
  'ca': 'Catalan',
  'eu-ES': 'Basque',
  'gl-ES': 'Galician',
  'rm': 'Romansh',
};

/// The languages Ember offered before it offered them all. A listing saved
/// back then lists only the ones the user kept among these: a missing one was
/// switched off on purpose, any other is simply new.
const playLanguagesOfferedFirst = {'it-IT', 'fr-FR', 'es-ES', 'ar', 'de-DE', 'pt-BR', 'tr-TR', 'hi-IN', 'ru-RU'};

/// Store languages written right to left: their text fields are laid out
/// that way whatever language Ember itself is in.
const playRtlLanguages = {'ar', 'ur', 'fa', 'iw-IL'};

bool isRtlStoreLanguage(String code) => playRtlLanguages.contains(code);

/// English pages for other countries say what the main page says: they are
/// copied from it, not translated.
bool copiesMainLanguage(String code) => code.startsWith('en-');

/// Whether [query] finds this language: by its own name, its English name or
/// its code.
bool storeLanguageMatches(String code, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return code.toLowerCase().contains(q) ||
      (playStoreLanguages[code] ?? '').toLowerCase().contains(q) ||
      (playLanguageEnglishNames[code] ?? '').toLowerCase().contains(q);
}

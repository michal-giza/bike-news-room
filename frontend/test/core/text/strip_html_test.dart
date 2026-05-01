import 'package:bike_news_room/core/text/strip_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stripHtml — basics', () {
    test('returns empty for null', () => expect(stripHtml(null), ''));
    test('returns empty for empty', () => expect(stripHtml(''), ''));
    test('passes through plain text', () {
      expect(stripHtml('Pogacar wins'), 'Pogacar wins');
    });
  });

  group('stripHtml — tag stripping', () {
    test('strips simple tags', () {
      expect(stripHtml('<p>hello</p>'), 'hello');
    });

    test('strips nested tags', () {
      expect(
        stripHtml('<p>Pogacar <strong>wins</strong> stage</p>'),
        'Pogacar wins stage',
      );
    });

    test('strips anchor with attributes containing quotes and ?', () {
      // Exact case from the screenshot the user reported.
      const input =
          '<p>Jayco-AlUla is the third team to <a href="https://greenedgecycling.com/2026/ben-oconnor-leads-team-jayco-alula-at-giro-ditalia/?ref=escapecollective.com" rel="noreferrer">confirm its lineup</a> for the first Grand Tour of the season.</p>';
      final result = stripHtml(input);
      expect(result, contains('Jayco-AlUla is the third team to'));
      expect(result, contains('confirm its lineup'));
      expect(result, contains('first Grand Tour'));
      expect(result, isNot(contains('<')));
      expect(result, isNot(contains('>')));
      expect(result, isNot(contains('href=')));
      expect(result, isNot(contains('rel=')));
    });

    test('strips img and figure', () {
      const input =
          '<figure><img src="x.jpg" alt="cover"><figcaption>caption</figcaption></figure>';
      final result = stripHtml(input);
      expect(result, isNot(contains('<')));
      expect(result, contains('caption'));
    });

    test('strips script and its contents entirely', () {
      const input = '<p>safe</p><script>evil(); alert(1);</script><p>more</p>';
      final result = stripHtml(input);
      expect(result, isNot(contains('evil')));
      expect(result, isNot(contains('alert')));
      expect(result, contains('safe'));
      expect(result, contains('more'));
    });

    test('strips style block entirely', () {
      const input = '<p>safe</p><style>.x { color: red; }</style>';
      expect(stripHtml(input), 'safe');
    });

    test('strips HTML comments', () {
      expect(stripHtml('<p>real <!-- hidden --> text</p>'), 'real text');
    });

    test('keeps CDATA contents but drops the wrapper', () {
      expect(stripHtml('<![CDATA[hello world]]>'), 'hello world');
    });

    test('handles multi-line attributes', () {
      const input = '''<a
        href="https://example.com"
        rel="noreferrer"
      >link</a>''';
      expect(stripHtml(input), 'link');
    });

    test('handles malformed self-closing tags', () {
      expect(stripHtml('<br><br/><br /><hr/>'), '');
    });
  });

  group('stripHtml — entity decoding', () {
    test('decodes named entities', () {
      expect(
        stripHtml('Jayco d&apos;Italia &amp; UAE &mdash; the season'),
        "Jayco d'Italia & UAE — the season",
      );
    });

    test("decodes O&apos;Connor (the exact failing case)", () {
      expect(stripHtml('Ben O&apos;Connor'), "Ben O'Connor");
    });

    test('decodes decimal numeric entities', () {
      // &#8217; is right single quote ’
      expect(stripHtml('it&#8217;s'), 'it’s');
    });

    test('decodes hex numeric entities', () {
      // &#x2019; is also ’
      expect(stripHtml('it&#x2019;s'), 'it’s');
    });

    test('decodes accented Latin used by ES/PL feeds', () {
      expect(
        stripHtml('Vuelta a Espa&ntilde;a · Cl&aacute;sica'),
        'Vuelta a España · Clásica',
      );
    });

    test('rejects unpaired surrogate codepoints', () {
      // 0xD800 alone is invalid — should be left as the literal entity.
      final result = stripHtml('safe&#55296;more');
      expect(result, contains('safe'));
      expect(result, contains('more'));
    });

    test('rejects out-of-range numeric entities', () {
      final result = stripHtml('a&#9999999;b');
      // Just must not crash; we don't care exactly what it leaves.
      expect(result, contains('a'));
      expect(result, contains('b'));
    });

    test('leaves unknown named entities alone', () {
      expect(stripHtml('&zzz;'), '&zzz;');
    });
  });

  group('stripHtml — whitespace + control chars', () {
    test('collapses whitespace', () {
      expect(stripHtml('a\n\n\n  b\t\tc'), 'a b c');
    });

    test('drops NUL and other control chars', () {
      expect(stripHtml('hello\x00world\x07!'), 'helloworld!');
    });

    test('preserves regular spaces', () {
      expect(stripHtml('a b c'), 'a b c');
    });
  });

  group('stripHtml — idempotency + regression', () {
    test('idempotent: f(f(x)) == f(x)', () {
      const input =
          '<p>Vuelta a Espa&ntilde;a — d&apos;Italia <a href="x">link</a></p>';
      final once = stripHtml(input);
      final twice = stripHtml(once);
      expect(once, twice);
    });

    test('exact screenshot case ends up clean', () {
      // The full body the user screenshotted, more or less.
      const input =
          '<p>Jayco-AlUla is the third team to <a href="https://greenedgecycling.com/2026/ben-oconnor-leads-team-jayco-alula-at-giro-ditalia/?ref=escapecollective.com" rel="noreferrer">confirm its lineup</a> for the first Grand Tour of the season. The 2026 Giro d&apos;Italia will see Ben O&apos;Connor headline the Australian WorldTeam with Pascal Ackermann also getting support for the sprint stages.</p><p>O&apos;Connor returns to the Giro</p>';
      final result = stripHtml(input);

      // No HTML or entities anywhere in the result.
      expect(result, isNot(contains('<')));
      expect(result, isNot(contains('>')));
      expect(result, isNot(contains('&apos;')));
      expect(result, isNot(contains('&amp;')));
      expect(result, isNot(contains('href=')));
      expect(result, isNot(contains('rel=')));

      // Real curly apostrophe substituted in.
      expect(result, contains("d'Italia"));
      expect(result, contains("O'Connor"));
      expect(result, contains('Jayco-AlUla'));
      expect(result, contains('returns to the Giro'));
    });
  });
}

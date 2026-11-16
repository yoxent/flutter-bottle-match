import 'package:flutter_bottle_match/design_system/tokens/typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('header and body both use the bundled Inter face', () {
    expect(AppFontFamily.header, 'packages/forui/Inter');
    expect(AppFontFamily.body, AppFontFamily.header);
  });

  test(
    'display styles use the header face and reading styles use the body face',
    () {
      const headers = [
        AppTypography.display,
        AppTypography.title,
        AppTypography.headline,
        AppTypography.button,
        AppTypography.stageKicker,
        AppTypography.stageAnnouncement,
        AppTypography.stageOrder,
        AppTypography.stageName,
        AppTypography.stageButton,
      ];
      const reading = [
        AppTypography.body,
        AppTypography.emphasis,
        AppTypography.label,
        AppTypography.stageScore,
        AppTypography.stageNote,
      ];

      for (final style in headers) {
        expect(style.fontFamily, AppFontFamily.header);
      }
      for (final style in reading) {
        expect(style.fontFamily, AppFontFamily.body);
      }

      final theme = AppTypography.textTheme();
      expect(theme.displaySmall?.fontFamily, AppFontFamily.header);
      expect(theme.bodyLarge?.fontFamily, AppFontFamily.body);
    },
  );
}

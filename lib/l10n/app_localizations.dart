import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'FlexiKeys'**
  String get appName;

  /// Welcome screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome to FlexiKeys'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s learn together!'**
  String get welcomeSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @levelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsTitle;

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Keep practising to unlock this level'**
  String get levelLocked;

  /// No description provided for @levelStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get levelStart;

  /// No description provided for @levelContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get levelContinue;

  /// No description provided for @levelCompleted.
  ///
  /// In en, this message translates to:
  /// **'Level completed!'**
  String get levelCompleted;

  /// No description provided for @lessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lesson done!'**
  String get lessonCompleted;

  /// No description provided for @nextLesson.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLesson;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @showHint.
  ///
  /// In en, this message translates to:
  /// **'Show hint'**
  String get showHint;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Learning language'**
  String get languageSetting;

  /// No description provided for @uiLanguageSetting.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get uiLanguageSetting;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUzbek.
  ///
  /// In en, this message translates to:
  /// **'Uzbek'**
  String get languageUzbek;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @parentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Parent Dashboard'**
  String get parentDashboard;

  /// No description provided for @childProgress.
  ///
  /// In en, this message translates to:
  /// **'Child Progress'**
  String get childProgress;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @sessionTime.
  ///
  /// In en, this message translates to:
  /// **'Session time'**
  String get sessionTime;

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracyLabel;

  /// No description provided for @masteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get masteryLabel;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChild;

  /// No description provided for @childName.
  ///
  /// In en, this message translates to:
  /// **'Child\'s name'**
  String get childName;

  /// No description provided for @childAge.
  ///
  /// In en, this message translates to:
  /// **'Birth year'**
  String get childAge;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProfile;

  /// No description provided for @breakSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Take a short break — you\'re doing great!'**
  String get breakSuggestion;

  /// No description provided for @sessionDone.
  ///
  /// In en, this message translates to:
  /// **'Great session today!'**
  String get sessionDone;

  /// No description provided for @mascotGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi there! Ready to learn?'**
  String get mascotGreeting;

  /// No description provided for @mascotEncouraging.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing well, keep going!'**
  String get mascotEncouraging;

  /// No description provided for @mascotEffortPraise.
  ///
  /// In en, this message translates to:
  /// **'Great effort — you\'re improving!'**
  String get mascotEffortPraise;

  /// No description provided for @mascotImproved.
  ///
  /// In en, this message translates to:
  /// **'You got better at that!'**
  String get mascotImproved;

  /// No description provided for @mascotTakeTime.
  ///
  /// In en, this message translates to:
  /// **'Take your time — no rush.'**
  String get mascotTakeTime;

  /// No description provided for @mascotKeepTrying.
  ///
  /// In en, this message translates to:
  /// **'Keep trying — you can do it!'**
  String get mascotKeepTrying;

  /// No description provided for @mascotHighFive.
  ///
  /// In en, this message translates to:
  /// **'Well done today!'**
  String get mascotHighFive;

  /// No description provided for @mascotSleepy.
  ///
  /// In en, this message translates to:
  /// **'Sleepy? Let\'s take a break.'**
  String get mascotSleepy;

  /// No description provided for @mascotWaving.
  ///
  /// In en, this message translates to:
  /// **'See you next time!'**
  String get mascotWaving;

  /// No description provided for @mascotSurprised.
  ///
  /// In en, this message translates to:
  /// **'Wow, that was fast!'**
  String get mascotSurprised;

  /// No description provided for @mascotThinking.
  ///
  /// In en, this message translates to:
  /// **'Hmm, let me think...'**
  String get mascotThinking;

  /// No description provided for @mascotCelebrating.
  ///
  /// In en, this message translates to:
  /// **'You completed a level!'**
  String get mascotCelebrating;

  /// No description provided for @letterTraceInstruction.
  ///
  /// In en, this message translates to:
  /// **'Trace the letter with your finger'**
  String get letterTraceInstruction;

  /// No description provided for @numberTraceInstruction.
  ///
  /// In en, this message translates to:
  /// **'Trace the number with your finger'**
  String get numberTraceInstruction;

  /// No description provided for @shapeTraceInstruction.
  ///
  /// In en, this message translates to:
  /// **'Trace the shape with your finger'**
  String get shapeTraceInstruction;

  /// No description provided for @connectDotsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Connect the dots to complete the picture'**
  String get connectDotsInstruction;

  /// No description provided for @coloringInstruction.
  ///
  /// In en, this message translates to:
  /// **'Color the picture'**
  String get coloringInstruction;

  /// No description provided for @typeThisLetter.
  ///
  /// In en, this message translates to:
  /// **'Type this letter'**
  String get typeThisLetter;

  /// No description provided for @typeThisWord.
  ///
  /// In en, this message translates to:
  /// **'Type this word'**
  String get typeThisWord;

  /// No description provided for @typeThisSentence.
  ///
  /// In en, this message translates to:
  /// **'Type this sentence'**
  String get typeThisSentence;

  /// No description provided for @correctFeedback.
  ///
  /// In en, this message translates to:
  /// **'You did it!'**
  String get correctFeedback;

  /// No description provided for @encouragementFeedback.
  ///
  /// In en, this message translates to:
  /// **'Almost there — give it another go!'**
  String get encouragementFeedback;

  /// No description provided for @progressFeedback.
  ///
  /// In en, this message translates to:
  /// **'You improved on this one!'**
  String get progressFeedback;

  /// No description provided for @keyboardHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap the key shown'**
  String get keyboardHintLabel;

  /// No description provided for @keyboardLargeMode.
  ///
  /// In en, this message translates to:
  /// **'Large keyboard mode active'**
  String get keyboardLargeMode;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Parental Consent'**
  String get consentTitle;

  /// No description provided for @consentText.
  ///
  /// In en, this message translates to:
  /// **'By adding a child profile, you confirm you are the parent or legal guardian and consent to limited, pseudonymised activity data being used to personalise the learning experience. No personal data is shared with third parties.'**
  String get consentText;

  /// No description provided for @consentAccept.
  ///
  /// In en, this message translates to:
  /// **'I consent'**
  String get consentAccept;

  /// No description provided for @consentDecline.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get consentDecline;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Learning Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This assistant provides educational guidance only and is not a substitute for medical or therapeutic advice. Always consult a qualified professional for health concerns.'**
  String get aiAssistantDisclaimer;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Working offline — some features may be limited.'**
  String get errorOfflineMode;

  /// No description provided for @adaptationKeyScaleUp.
  ///
  /// In en, this message translates to:
  /// **'Keyboard keys have been made larger to help your child tap more accurately.'**
  String get adaptationKeyScaleUp;

  /// No description provided for @adaptationDwellTimeUp.
  ///
  /// In en, this message translates to:
  /// **'A small pause before registering a tap has been added to reduce accidental presses.'**
  String get adaptationDwellTimeUp;

  /// No description provided for @adaptationHintLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Hints have been increased to help your child with this letter.'**
  String get adaptationHintLevelUp;

  /// No description provided for @adaptationHintLevelDown.
  ///
  /// In en, this message translates to:
  /// **'Hints have been reduced — your child is doing well!'**
  String get adaptationHintLevelDown;

  /// No description provided for @adaptationBreakSuggested.
  ///
  /// In en, this message translates to:
  /// **'A short break was suggested after signs of tiredness were detected.'**
  String get adaptationBreakSuggested;

  /// No description provided for @adaptationKeySpacingUp.
  ///
  /// In en, this message translates to:
  /// **'Key spacing has been increased to reduce accidental taps.'**
  String get adaptationKeySpacingUp;

  /// No description provided for @adaptationGlobalScaleUp.
  ///
  /// In en, this message translates to:
  /// **'The keyboard has been made larger for easier tapping.'**
  String get adaptationGlobalScaleUp;

  /// No description provided for @storyPageInstruction.
  ///
  /// In en, this message translates to:
  /// **'Listen and type the last word'**
  String get storyPageInstruction;

  /// No description provided for @storyNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get storyNextPage;

  /// No description provided for @storyFinished.
  ///
  /// In en, this message translates to:
  /// **'Story finished!'**
  String get storyFinished;

  /// No description provided for @rewardEarned.
  ///
  /// In en, this message translates to:
  /// **'You earned a reward!'**
  String get rewardEarned;

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'New badge: {badgeName}'**
  String badgeEarned(String badgeName);

  /// No description provided for @levelUnlocked.
  ///
  /// In en, this message translates to:
  /// **'New level unlocked: {levelName}'**
  String levelUnlocked(String levelName);

  /// No description provided for @itemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCountLabel(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @comingSoonSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Coming soon! 🚀'**
  String get comingSoonSnackbar;

  /// No description provided for @tabLearn.
  ///
  /// In en, this message translates to:
  /// **'🎓 Learn'**
  String get tabLearn;

  /// No description provided for @tabDraw.
  ///
  /// In en, this message translates to:
  /// **'🎨 Draw'**
  String get tabDraw;

  /// No description provided for @tabVoice.
  ///
  /// In en, this message translates to:
  /// **'🗣️ My Voice'**
  String get tabVoice;

  /// No description provided for @lockedLevelSnackbar.
  ///
  /// In en, this message translates to:
  /// **'🔒 Finish \"{levelName}\" to unlock!'**
  String lockedLevelSnackbar(String levelName);

  /// No description provided for @drawSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get drawSectionHeader;

  /// No description provided for @paintSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Coloring'**
  String get paintSectionHeader;

  /// No description provided for @levelTitleLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get levelTitleLetters;

  /// No description provided for @levelTitleNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get levelTitleNumbers;

  /// No description provided for @levelTitleColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get levelTitleColors;

  /// No description provided for @levelTitleFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get levelTitleFruits;

  /// No description provided for @levelTitleAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get levelTitleAnimals;

  /// No description provided for @levelTitleFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get levelTitleFood;

  /// No description provided for @drawTitleShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get drawTitleShapes;

  /// No description provided for @drawTitleLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get drawTitleLetters;

  /// No description provided for @drawTitleNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get drawTitleNumbers;

  /// No description provided for @drawTitleObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get drawTitleObjects;

  /// No description provided for @colorTitleFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get colorTitleFruits;

  /// No description provided for @colorTitleAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get colorTitleAnimals;

  /// No description provided for @colorTitleNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get colorTitleNature;

  /// No description provided for @colorTitleTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get colorTitleTransport;

  /// No description provided for @parentDashboardHeader.
  ///
  /// In en, this message translates to:
  /// **'Parent dashboard'**
  String get parentDashboardHeader;

  /// No description provided for @statLettersLabel.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get statLettersLabel;

  /// No description provided for @statNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statNotStarted;

  /// No description provided for @statStage1Done.
  ///
  /// In en, this message translates to:
  /// **'Stage 1 ✓'**
  String get statStage1Done;

  /// No description provided for @statDone.
  ///
  /// In en, this message translates to:
  /// **'Done! ✓'**
  String get statDone;

  /// No description provided for @statStarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get statStarsLabel;

  /// No description provided for @statTimeSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get statTimeSpentLabel;

  /// No description provided for @statTodaySuffix.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get statTodaySuffix;

  /// No description provided for @needsPracticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs practice'**
  String get needsPracticeLabel;

  /// No description provided for @practiceButton.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceButton;

  /// No description provided for @askAiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI Assistant'**
  String get askAiAssistantTitle;

  /// No description provided for @askAiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress insights, reports, and practice tips'**
  String get askAiAssistantSubtitle;

  /// No description provided for @languageMenuButton.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuButton;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @saveProgressButton.
  ///
  /// In en, this message translates to:
  /// **'Save my progress to an account'**
  String get saveProgressButton;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutDialogTitle;

  /// No description provided for @signOutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'All progress will be kept.'**
  String get signOutDialogBody;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutConfirm;

  /// No description provided for @notEnoughStarsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Not enough stars!'**
  String get notEnoughStarsSnackbar;

  /// No description provided for @gotItPraise.
  ///
  /// In en, this message translates to:
  /// **'Hooray! You got it!'**
  String get gotItPraise;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @itemSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get itemSelectedLabel;

  /// No description provided for @itemEquipLabel.
  ///
  /// In en, this message translates to:
  /// **'equip'**
  String get itemEquipLabel;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Small steps. Big progress.'**
  String get splashTagline;

  /// No description provided for @goButton.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get goButton;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'Hi! {name}\nlet\'s play\nwith letters!'**
  String greetingWithName(String name);

  /// No description provided for @greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play\nwith letters!'**
  String get greetingNoName;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select language to start'**
  String get chooseLanguageSubtitle;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter kid\'s name'**
  String get nameRequiredError;

  /// No description provided for @ageRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter kid\'s age'**
  String get ageRequiredError;

  /// No description provided for @profileCreateError.
  ///
  /// In en, this message translates to:
  /// **'Could not create profile — please try again'**
  String get profileCreateError;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registrationTitle;

  /// No description provided for @almostDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'almost done'**
  String get almostDoneSubtitle;

  /// No description provided for @kidNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Kid\'s name'**
  String get kidNameLabel;

  /// No description provided for @kidNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name...'**
  String get kidNameHint;

  /// No description provided for @kidAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Kid\'s age'**
  String get kidAgeLabel;

  /// No description provided for @kidAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Age...'**
  String get kidAgeHint;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @navProgressTab.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgressTab;

  /// No description provided for @navVoiceTab.
  ///
  /// In en, this message translates to:
  /// **'My Voice'**
  String get navVoiceTab;

  /// No description provided for @navAskAiTab.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get navAskAiTab;

  /// No description provided for @todayActivityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s activity'**
  String get todayActivityLoadError;

  /// No description provided for @adaptationsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'What the system adjusted'**
  String get adaptationsSectionHeader;

  /// No description provided for @adaptationsBody.
  ///
  /// In en, this message translates to:
  /// **'FlexiKeys tunes the keyboard automatically based on practice data. Here is what changed recently.'**
  String get adaptationsBody;

  /// No description provided for @noAdjustmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No adjustments yet — keep practicing!'**
  String get noAdjustmentsYet;

  /// No description provided for @feedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load feed'**
  String get feedLoadError;

  /// No description provided for @statTodayPill.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statTodayPill;

  /// No description provided for @statItemsPill.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get statItemsPill;

  /// No description provided for @statStreakPill.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statStreakPill;

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get relativeToday;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String relativeDaysAgo(int n);

  /// No description provided for @chartLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load chart'**
  String get chartLoadError;

  /// No description provided for @letterMasteryHeader.
  ///
  /// In en, this message translates to:
  /// **'Letter Mastery'**
  String get letterMasteryHeader;

  /// No description provided for @masteryLegend.
  ///
  /// In en, this message translates to:
  /// **'Mint = mastered · Yellow = practicing · Lavender = not yet started'**
  String get masteryLegend;

  /// No description provided for @masteryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load mastery data'**
  String get masteryLoadError;

  /// No description provided for @metricAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get metricAccuracy;

  /// No description provided for @metricSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get metricSpeed;

  /// No description provided for @metricTime.
  ///
  /// In en, this message translates to:
  /// **'Time (min)'**
  String get metricTime;

  /// No description provided for @noDataForRange.
  ///
  /// In en, this message translates to:
  /// **'No data for this range'**
  String get noDataForRange;

  /// No description provided for @noSkillsTracked.
  ///
  /// In en, this message translates to:
  /// **'No skills tracked yet.'**
  String get noSkillsTracked;

  /// No description provided for @exportSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully.'**
  String get exportSuccessSnackbar;

  /// No description provided for @deleteChildDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete child account?'**
  String get deleteChildDialogTitle;

  /// No description provided for @deleteChildDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all practice data for this child. This cannot be undone.'**
  String get deleteChildDialogBody;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @sessionLengthHeader.
  ///
  /// In en, this message translates to:
  /// **'Session Length'**
  String get sessionLengthHeader;

  /// No description provided for @sessionLengthHint.
  ///
  /// In en, this message translates to:
  /// **'Suggested session length: 10–15 minutes'**
  String get sessionLengthHint;

  /// No description provided for @sessionLengthBody.
  ///
  /// In en, this message translates to:
  /// **'The system will suggest a break if practice exceeds 7 minutes continuously.'**
  String get sessionLengthBody;

  /// No description provided for @dataPrivacyHeader.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataPrivacyHeader;

  /// No description provided for @exportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my child\'s data'**
  String get exportDataTitle;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a complete JSON archive'**
  String get exportDataSubtitle;

  /// No description provided for @deleteChildAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete child account'**
  String get deleteChildAccountTitle;

  /// No description provided for @deleteChildAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes all practice data'**
  String get deleteChildAccountSubtitle;

  /// No description provided for @dataPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'FlexiKeys collects only the minimum data needed to personalise your child\'s learning. No advertising. No third-party tracking. All telemetry is pseudonymised. You can export or delete all data at any time.'**
  String get dataPrivacyNotice;

  /// No description provided for @promptHowIsChildDoing.
  ///
  /// In en, this message translates to:
  /// **'How is my child doing?'**
  String get promptHowIsChildDoing;

  /// No description provided for @promptExplainReport.
  ///
  /// In en, this message translates to:
  /// **'Explain today\'s report'**
  String get promptExplainReport;

  /// No description provided for @promptWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get promptWeeklySummary;

  /// No description provided for @promptPracticeSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Practice suggestions'**
  String get promptPracticeSuggestions;

  /// No description provided for @promptStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get promptStrengths;

  /// No description provided for @promptWeaknesses.
  ///
  /// In en, this message translates to:
  /// **'Weaknesses'**
  String get promptWeaknesses;

  /// No description provided for @promptDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get promptDailyGoals;

  /// No description provided for @promptLearningTips.
  ///
  /// In en, this message translates to:
  /// **'Learning tips'**
  String get promptLearningTips;

  /// No description provided for @assistantHeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your learning assistant'**
  String get assistantHeroHeadline;

  /// No description provided for @assistantHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Ask about recent practice, get activity ideas, or ask why the keyboard adapted — every answer is grounded in your child\'s actual data.'**
  String get assistantHeroBody;

  /// No description provided for @tryAskingLabel.
  ///
  /// In en, this message translates to:
  /// **'Try asking:'**
  String get tryAskingLabel;

  /// No description provided for @copiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedSnackbar;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your child\'s practice…'**
  String get chatHint;

  /// No description provided for @accuracyUpHeadline.
  ///
  /// In en, this message translates to:
  /// **'Accuracy is up {pct}% this week'**
  String accuracyUpHeadline(int pct);

  /// No description provided for @accuracyDownHeadline.
  ///
  /// In en, this message translates to:
  /// **'Accuracy dipped {pct}% this week'**
  String accuracyDownHeadline(int pct);

  /// No description provided for @accuracyUpBody.
  ///
  /// In en, this message translates to:
  /// **'Keep up the momentum — recent practice is paying off.'**
  String get accuracyUpBody;

  /// No description provided for @accuracyDownBody.
  ///
  /// In en, this message translates to:
  /// **'A dip happens sometimes — ask the assistant for a few at-home exercises.'**
  String get accuracyDownBody;

  /// No description provided for @streakHeadline.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String streakHeadline(int days);

  /// No description provided for @streakBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has practiced {days} days in a row. Nice work!'**
  String streakBody(String name, int days);

  /// No description provided for @noPracticeTodayHeadline.
  ///
  /// In en, this message translates to:
  /// **'No practice yet today'**
  String get noPracticeTodayHeadline;

  /// No description provided for @noPracticeTodayBody.
  ///
  /// In en, this message translates to:
  /// **'A short 5-minute session keeps the streak going.'**
  String get noPracticeTodayBody;

  /// No description provided for @followUpCompareLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Compare to last week'**
  String get followUpCompareLastWeek;

  /// No description provided for @followUpAnyConcerns.
  ///
  /// In en, this message translates to:
  /// **'Any concerns?'**
  String get followUpAnyConcerns;

  /// No description provided for @followUpWhatPracticeNext.
  ///
  /// In en, this message translates to:
  /// **'What should we practice next?'**
  String get followUpWhatPracticeNext;

  /// No description provided for @followUpWhyActivities.
  ///
  /// In en, this message translates to:
  /// **'Why these activities?'**
  String get followUpWhyActivities;

  /// No description provided for @followUpHowLongPractice.
  ///
  /// In en, this message translates to:
  /// **'How long should we practice?'**
  String get followUpHowLongPractice;

  /// No description provided for @followUpHowHelpAtHome.
  ///
  /// In en, this message translates to:
  /// **'How can I help at home?'**
  String get followUpHowHelpAtHome;

  /// No description provided for @followUpIsNormalAge.
  ///
  /// In en, this message translates to:
  /// **'Is this normal for this age?'**
  String get followUpIsNormalAge;

  /// No description provided for @followUpWhyChanged.
  ///
  /// In en, this message translates to:
  /// **'Why did this change?'**
  String get followUpWhyChanged;

  /// No description provided for @followUpWhatElseAdapted.
  ///
  /// In en, this message translates to:
  /// **'What else has adapted?'**
  String get followUpWhatElseAdapted;

  /// No description provided for @followUpHowEncourage.
  ///
  /// In en, this message translates to:
  /// **'How can I encourage without pressure?'**
  String get followUpHowEncourage;

  /// No description provided for @followUpBreakSchedule.
  ///
  /// In en, this message translates to:
  /// **'Suggest a break schedule'**
  String get followUpBreakSchedule;

  /// No description provided for @followUpWhatPracticeToday.
  ///
  /// In en, this message translates to:
  /// **'What should we practice today?'**
  String get followUpWhatPracticeToday;

  /// No description provided for @followUpHowChildOverall.
  ///
  /// In en, this message translates to:
  /// **'How is my child doing overall?'**
  String get followUpHowChildOverall;

  /// No description provided for @myVoiceDashboardSubheader.
  ///
  /// In en, this message translates to:
  /// **'How your child is using their communication cards.'**
  String get myVoiceDashboardSubheader;

  /// No description provided for @aacCategoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get aacCategoryDaily;

  /// No description provided for @aacCategoryNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get aacCategoryNeeds;

  /// No description provided for @aacCategoryFeelings.
  ///
  /// In en, this message translates to:
  /// **'Feelings'**
  String get aacCategoryFeelings;

  /// No description provided for @aacCategoryPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get aacCategoryPeople;

  /// No description provided for @aacCategoryPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get aacCategoryPlaces;

  /// No description provided for @aacMyCardsLabel.
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get aacMyCardsLabel;

  /// No description provided for @manageCardsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage cards'**
  String get manageCardsTooltip;

  /// No description provided for @thisWeekSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekSectionHeader;

  /// No description provided for @weekTrendLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this week\'s trend'**
  String get weekTrendLoadError;

  /// No description provided for @noCardsTappedToday.
  ///
  /// In en, this message translates to:
  /// **'No cards tapped yet today.'**
  String get noCardsTappedToday;

  /// No description provided for @notEnoughWeeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Not enough activity yet for a weekly trend.'**
  String get notEnoughWeeklyActivity;

  /// No description provided for @weekdayMonShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMonShort;

  /// No description provided for @weekdayTueShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTueShort;

  /// No description provided for @weekdayWedShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWedShort;

  /// No description provided for @weekdayThuShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThuShort;

  /// No description provided for @weekdayFriShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFriShort;

  /// No description provided for @weekdaySatShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySatShort;

  /// No description provided for @weekdaySunShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySunShort;

  /// No description provided for @insightsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsSectionHeader;

  /// No description provided for @removeCardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this card?'**
  String get removeCardDialogTitle;

  /// No description provided for @removeCardDialogBody.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be removed.'**
  String removeCardDialogBody(String label);

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @manageCardsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Cards'**
  String get manageCardsAppBarTitle;

  /// No description provided for @addCardButton.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCardButton;

  /// No description provided for @noCustomCardsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No custom cards yet. Add a photo of a family member, pet, or favorite toy to give your child their own words for it.'**
  String get noCustomCardsEmptyState;

  /// No description provided for @chooseFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get chooseFromPhotos;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @editCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Card'**
  String get editCardTitle;

  /// No description provided for @newCardTitle.
  ///
  /// In en, this message translates to:
  /// **'New Card'**
  String get newCardTitle;

  /// No description provided for @addPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhotoLabel;

  /// No description provided for @cardLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get cardLabelField;

  /// No description provided for @cardLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grandma, Rex, blanket'**
  String get cardLabelHint;

  /// No description provided for @voiceOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice (optional)'**
  String get voiceOptionalLabel;

  /// No description provided for @voiceHelperText.
  ///
  /// In en, this message translates to:
  /// **'Record your own voice saying the word, or leave this blank and FlexiKeys will read the label aloud instead.'**
  String get voiceHelperText;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @micPermissionSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record a voice.'**
  String get micPermissionSnackbar;

  /// No description provided for @recordingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording… {seconds}s'**
  String recordingStatusLabel(int seconds);

  /// No description provided for @stopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTooltip;

  /// No description provided for @playTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playTooltip;

  /// No description provided for @voiceRecordedLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice recorded'**
  String get voiceRecordedLabel;

  /// No description provided for @reRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get reRecordButton;

  /// No description provided for @recordVoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get recordVoiceButton;

  /// No description provided for @myVoiceSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Voice Settings'**
  String get myVoiceSettingsTitle;

  /// No description provided for @progressionLevelHeader.
  ///
  /// In en, this message translates to:
  /// **'Progression Level'**
  String get progressionLevelHeader;

  /// No description provided for @cardSizeHeader.
  ///
  /// In en, this message translates to:
  /// **'Card Size'**
  String get cardSizeHeader;

  /// No description provided for @accessibilityHeader.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityHeader;

  /// No description provided for @dwellTimeSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Dwell-time activation'**
  String get dwellTimeSwitchTitle;

  /// No description provided for @dwellTimeSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold instead of tap — for severe motor impairment'**
  String get dwellTimeSwitchSubtitle;

  /// No description provided for @holdDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Hold duration'**
  String get holdDurationLabel;

  /// No description provided for @holdDurationMs.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String holdDurationMs(int ms);

  /// No description provided for @highContrastSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrastSwitchTitle;

  /// No description provided for @highContrastSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solid card background + thicker border'**
  String get highContrastSwitchSubtitle;

  /// No description provided for @reducedMotionSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get reducedMotionSwitchTitle;

  /// No description provided for @reducedMotionSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turns off card animations, even if the device setting is off'**
  String get reducedMotionSwitchSubtitle;

  /// No description provided for @level1Option.
  ///
  /// In en, this message translates to:
  /// **'Level 1 — 6 core words'**
  String get level1Option;

  /// No description provided for @level2Option.
  ///
  /// In en, this message translates to:
  /// **'Level 2 — 12 words'**
  String get level2Option;

  /// No description provided for @level3Option.
  ///
  /// In en, this message translates to:
  /// **'Level 3 — 24 words'**
  String get level3Option;

  /// No description provided for @level4Option.
  ///
  /// In en, this message translates to:
  /// **'Level 4 — full vocabulary + sentence building'**
  String get level4Option;

  /// No description provided for @cardSizeLOption.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get cardSizeLOption;

  /// No description provided for @cardSizeXLOption.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get cardSizeXLOption;

  /// No description provided for @cardSizeXXLOption.
  ///
  /// In en, this message translates to:
  /// **'XXL'**
  String get cardSizeXXLOption;

  /// No description provided for @colorReadyButton.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get colorReadyButton;

  /// No description provided for @traceGoodJobFallback.
  ///
  /// In en, this message translates to:
  /// **'Good job! Keep it up!'**
  String get traceGoodJobFallback;

  /// No description provided for @traceShowMeButton.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get traceShowMeButton;

  /// No description provided for @traceCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get traceCheckButton;

  /// No description provided for @goodJobHeadline.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get goodJobHeadline;

  /// No description provided for @okayButton.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okayButton;

  /// No description provided for @tryAgainHeader.
  ///
  /// In en, this message translates to:
  /// **'Try Again!'**
  String get tryAgainHeader;

  /// No description provided for @retryMascotMessage.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try again!'**
  String get retryMascotMessage;

  /// No description provided for @findAndTapInstruction.
  ///
  /// In en, this message translates to:
  /// **'Find and tap\nthis letter'**
  String get findAndTapInstruction;

  /// No description provided for @findAndTapCaption.
  ///
  /// In en, this message translates to:
  /// **'Find and tap this letter'**
  String get findAndTapCaption;

  /// No description provided for @groupReadyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Group ready!'**
  String get groupReadyHeadline;

  /// No description provided for @goodJobKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Good job! Keep going!'**
  String get goodJobKeepGoing;

  /// No description provided for @shapesPraiseHigh.
  ///
  /// In en, this message translates to:
  /// **'Wonderfully drawn! 🎉'**
  String get shapesPraiseHigh;

  /// No description provided for @shapesPraiseLow.
  ///
  /// In en, this message translates to:
  /// **'Good! Keep going! 💪'**
  String get shapesPraiseLow;

  /// No description provided for @shapesCloseInstruction.
  ///
  /// In en, this message translates to:
  /// **'Go back to close at point 1!'**
  String get shapesCloseInstruction;

  /// No description provided for @shapesStartInstruction.
  ///
  /// In en, this message translates to:
  /// **'Start drawing from point 1!'**
  String get shapesStartInstruction;

  /// No description provided for @shapesProgress.
  ///
  /// In en, this message translates to:
  /// **'{tapped}/{total} dots connected!'**
  String shapesProgress(int tapped, int total);

  /// No description provided for @shapesDoneStatus.
  ///
  /// In en, this message translates to:
  /// **'✓ Done!'**
  String get shapesDoneStatus;

  /// No description provided for @shapesIdleInstruction.
  ///
  /// In en, this message translates to:
  /// **'Trace with your finger'**
  String get shapesIdleInstruction;

  /// No description provided for @shapesNextButton.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get shapesNextButton;

  /// No description provided for @shapesFinishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish ✓'**
  String get shapesFinishButton;

  /// No description provided for @shapesDisabledPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Keep tracing the shape...'**
  String get shapesDisabledPlaceholder;

  /// No description provided for @praiseShapeTraced.
  ///
  /// In en, this message translates to:
  /// **'Nice tracing!'**
  String get praiseShapeTraced;

  /// No description provided for @praiseLetterTraced.
  ///
  /// In en, this message translates to:
  /// **'Great job on that letter!'**
  String get praiseLetterTraced;

  /// No description provided for @praiseLevelComplete.
  ///
  /// In en, this message translates to:
  /// **'You finished the level!'**
  String get praiseLevelComplete;

  /// No description provided for @praiseMidLevelCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Halfway there — keep going!'**
  String get praiseMidLevelCheckpoint;

  /// No description provided for @spellThisNumber.
  ///
  /// In en, this message translates to:
  /// **'Spell this number'**
  String get spellThisNumber;

  /// No description provided for @spellThisColor.
  ///
  /// In en, this message translates to:
  /// **'Spell this color'**
  String get spellThisColor;

  /// No description provided for @spellThisFruit.
  ///
  /// In en, this message translates to:
  /// **'Spell this fruit'**
  String get spellThisFruit;

  /// No description provided for @spellThisAnimal.
  ///
  /// In en, this message translates to:
  /// **'Spell this animal'**
  String get spellThisAnimal;

  /// No description provided for @spellThisFood.
  ///
  /// In en, this message translates to:
  /// **'Spell this food'**
  String get spellThisFood;

  /// No description provided for @coloringSuffix.
  ///
  /// In en, this message translates to:
  /// **'coloring'**
  String get coloringSuffix;

  /// No description provided for @drawingSuffix.
  ///
  /// In en, this message translates to:
  /// **'drawing'**
  String get drawingSuffix;

  /// No description provided for @completionAllAnimalsColored.
  ///
  /// In en, this message translates to:
  /// **'All animals colored!'**
  String get completionAllAnimalsColored;

  /// No description provided for @completionAllFruitsColored.
  ///
  /// In en, this message translates to:
  /// **'All fruits colored!'**
  String get completionAllFruitsColored;

  /// No description provided for @completionAllNatureColored.
  ///
  /// In en, this message translates to:
  /// **'All nature pictures colored!'**
  String get completionAllNatureColored;

  /// No description provided for @completionAllTransportColored.
  ///
  /// In en, this message translates to:
  /// **'All transport colored!'**
  String get completionAllTransportColored;

  /// No description provided for @completionAllLettersDone.
  ///
  /// In en, this message translates to:
  /// **'All letters done!'**
  String get completionAllLettersDone;

  /// No description provided for @completionAllNumbersDone.
  ///
  /// In en, this message translates to:
  /// **'All numbers done!'**
  String get completionAllNumbersDone;

  /// No description provided for @completionAllObjectsDone.
  ///
  /// In en, this message translates to:
  /// **'All objects done!'**
  String get completionAllObjectsDone;

  /// No description provided for @coloringInstructionFor.
  ///
  /// In en, this message translates to:
  /// **'Color {item}!'**
  String coloringInstructionFor(String item);

  /// No description provided for @traceInstructionFor.
  ///
  /// In en, this message translates to:
  /// **'Connect the dots {seq}, then trace {item}!'**
  String traceInstructionFor(String seq, String item);

  /// No description provided for @parentAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent Area'**
  String get parentAreaTitle;

  /// No description provided for @parentGateInstruction.
  ///
  /// In en, this message translates to:
  /// **'Solve to continue:'**
  String get parentGateInstruction;

  /// No description provided for @parentGateWrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get parentGateWrongAnswer;

  /// No description provided for @yourAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswerHint;

  /// No description provided for @chatTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String chatTimeMinutesAgo(int n);

  /// No description provided for @chatTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String chatTimeHoursAgo(int n);

  /// No description provided for @chatTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String chatTimeDaysAgo(int n);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'uz': return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

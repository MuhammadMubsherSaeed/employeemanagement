import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @text_welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get text_welcome_back;

  /// No description provided for @text_login_description.
  ///
  /// In en, this message translates to:
  /// **'Please login with CNIC and Mobile No.'**
  String get text_login_description;

  /// No description provided for @username_required.
  ///
  /// In en, this message translates to:
  /// **'Username Required'**
  String get username_required;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_required;

  /// No description provided for @valid_cnic_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter correct CNIC & Password'**
  String get valid_cnic_password;

  /// No description provided for @please_wait_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Please wait Signing In...'**
  String get please_wait_sign_in;

  /// No description provided for @valid_cnic.
  ///
  /// In en, this message translates to:
  /// **'Enter valid CNIC no.'**
  String get valid_cnic;

  /// No description provided for @valid_mobile_number.
  ///
  /// In en, this message translates to:
  /// **'Enter valid Mobile Number.'**
  String get valid_mobile_number;

  /// No description provided for @valid_password.
  ///
  /// In en, this message translates to:
  /// **'Enter valid password'**
  String get valid_password;

  /// No description provided for @valid_name.
  ///
  /// In en, this message translates to:
  /// **'Enter valid name.'**
  String get valid_name;

  /// No description provided for @password_match.
  ///
  /// In en, this message translates to:
  /// **'Password and Confirm Password not matched'**
  String get password_match;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required*'**
  String get required;

  /// No description provided for @text_alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get text_alert;

  /// No description provided for @text_dialog_logout.
  ///
  /// In en, this message translates to:
  /// **'Do you want to Logout?'**
  String get text_dialog_logout;

  /// No description provided for @text_dialog_internet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get text_dialog_internet;

  /// No description provided for @text_dialog_internet_message.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get text_dialog_internet_message;

  /// No description provided for @text_logging_out.
  ///
  /// In en, this message translates to:
  /// **'Logging Out...'**
  String get text_logging_out;

  /// No description provided for @text_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get text_close;

  /// No description provided for @text_enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get text_enter;

  /// No description provided for @text_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get text_submit;

  /// No description provided for @text_resend.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get text_resend;

  /// No description provided for @text_not_have_account.
  ///
  /// In en, this message translates to:
  /// **'If you don’t have login access'**
  String get text_not_have_account;

  /// No description provided for @text_login_label.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get text_login_label;

  /// No description provided for @text_cnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get text_cnic;

  /// No description provided for @text_mobile_number.
  ///
  /// In en, this message translates to:
  /// **'Mobile No.'**
  String get text_mobile_number;

  /// No description provided for @text_username.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get text_username;

  /// No description provided for @text_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get text_password;

  /// No description provided for @text_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get text_confirm_password;

  /// No description provided for @text_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get text_login;

  /// No description provided for @text_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get text_logout;

  /// No description provided for @text_register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get text_register;

  /// No description provided for @text_register_only.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get text_register_only;

  /// No description provided for @text_register_description.
  ///
  /// In en, this message translates to:
  /// **'Please register yourself here'**
  String get text_register_description;

  /// No description provided for @text_login_already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get text_login_already_have_account;

  /// No description provided for @text_already_have_account.
  ///
  /// In en, this message translates to:
  /// **'You can login if you already registered'**
  String get text_already_have_account;

  /// No description provided for @text_otp.
  ///
  /// In en, this message translates to:
  /// **'One Time Password'**
  String get text_otp;

  /// No description provided for @text_otp_receive.
  ///
  /// In en, this message translates to:
  /// **'Please enter your OTP below'**
  String get text_otp_receive;

  /// No description provided for @text_enter_otp.
  ///
  /// In en, this message translates to:
  /// **'Please enter your OTP'**
  String get text_enter_otp;

  /// No description provided for @text_please_enter_otp.
  ///
  /// In en, this message translates to:
  /// **'Please enter your OTP'**
  String get text_please_enter_otp;

  /// No description provided for @text_drawer_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get text_drawer_dashboard;

  /// No description provided for @text_dashboard.
  ///
  /// In en, this message translates to:
  /// **'You have been registered for'**
  String get text_dashboard;

  /// No description provided for @text_user_name.
  ///
  /// In en, this message translates to:
  /// **'Ahsan Ali'**
  String get text_user_name;

  /// No description provided for @text_contact_soon.
  ///
  /// In en, this message translates to:
  /// **'You will be contacted soon'**
  String get text_contact_soon;

  /// No description provided for @text_ehsas_ration.
  ///
  /// In en, this message translates to:
  /// **'Ehsaas Ration Program'**
  String get text_ehsas_ration;

  /// No description provided for @text_new_user.
  ///
  /// In en, this message translates to:
  /// **'Register New User'**
  String get text_new_user;

  /// No description provided for @text_welcome_user.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ehsas Ration Program'**
  String get text_welcome_user;

  /// No description provided for @enter_password_description.
  ///
  /// In en, this message translates to:
  /// **'Please enter your CNIC and password'**
  String get enter_password_description;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enter_password;

  /// No description provided for @text_new_password.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get text_new_password;

  /// No description provided for @text_create_new_password.
  ///
  /// In en, this message translates to:
  /// **'You can create new password'**
  String get text_create_new_password;

  /// No description provided for @text_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get text_forgot_password;

  /// No description provided for @error_password.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t Remember Password?'**
  String get error_password;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

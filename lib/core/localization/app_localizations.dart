import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppLocalizations provides structured bilingual (English & Hindi) strings
/// for MPS School Management System.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('hi')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'MPS School Management System',
      'welcome': 'Welcome to MPS',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'email': 'Email Address',
      'password': 'Password',
      'phone_number': 'Phone Number',
      'admission_number': 'Admission Number',
      'loading': 'Loading, please wait...',
      'retry': 'Try Again',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'submit': 'Submit',
      'search': 'Search',
      'filter': 'Filter',

      // Roles
      'role_parent': 'Parent',
      'role_teacher': 'Teacher',
      'role_principal': 'Principal',
      'role_accountant': 'Accountant',
      'role_fee_clerk': 'Fee Clerk',

      // Dashboard
      'dashboard': 'Dashboard',
      'overview': 'Overview',
      'students': 'Students',
      'fees': 'Fees & Payments',
      'attendance': 'Attendance',
      'results': 'Academic Results',
      'announcements': 'Announcements',
      'settings': 'Settings',

      // Fees & Payments (Manual / Offline Provider)
      'fee_total_due': 'Total Outstanding Due',
      'fee_total_collected': 'Total Collected',
      'fee_record_payment': 'Record Payment (Cash / Cheque)',
      'fee_breakdown': 'Fee Breakdown',
      'fee_tuition': 'Tuition Fee',
      'fee_transport': 'Transport Fee',
      'fee_library': 'Library & Lab Fee',
      'fee_status_paid': 'Paid',
      'fee_status_unpaid': 'Unpaid',
      'fee_status_pending': 'Pending Verification',
      'fee_receipt': 'Official Receipt',
      'fee_history': 'Payment History',
      'fee_payment_mode': 'Payment Mode (Cash/Cheque/Bank Transfer)',
      'fee_payment_recorded_success':
          'Payment recorded and official receipt generated.',

      // Attendance
      'attendance_rate': 'Attendance Rate',
      'attendance_mark': 'Mark Attendance',
      'attendance_present': 'Present',
      'attendance_absent': 'Absent',
      'attendance_leave': 'On Leave',
      'attendance_save_confirm': 'Attendance recorded and verified',

      // Results
      'results_term': 'Terminal Examination',
      'results_grade': 'Grade',
      'results_marks': 'Marks Obtained',
      'results_published': 'Results Published',
      'results_draft': 'Draft Marks (Under Review)',

      // States
      'empty_students': 'No student records found.',
      'empty_fees': 'No pending fee dues at this moment.',
      'empty_notices': 'No current announcements.',
      'error_network':
          'Network connection lost. Please check your internet connection.',
      'error_auth': 'Authentication session expired. Please sign in again.',
      'error_permission': 'Access denied: You are not authorized to access this class or resource.',
      'error_generic': 'An unexpected error occurred. Please try again.',
      'offline_mode': 'Working in offline mode. Cached records shown.',
    },
    'hi': {
      'app_title': 'एमपीएस स्कूल प्रबंधन प्रणाली',
      'welcome': 'एमपीएस में आपका स्वागत है',
      'sign_in': 'साइन इन करें',
      'sign_out': 'साइन आउट',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड',
      'phone_number': 'फ़ोन नंबर',
      'admission_number': 'प्रवेश संख्या (Admission No.)',
      'loading': 'लोड हो रहा है, कृपया प्रतीक्षा करें...',
      'retry': 'पुनः प्रयास करें',
      'cancel': 'रद्द करें',
      'confirm': 'पुष्टि करें',
      'save': 'सहेजें',
      'submit': 'जमा करें',
      'search': 'खोजें',
      'filter': 'फ़िल्टर',

      // Roles
      'role_parent': 'अभिभावक (Parent)',
      'role_teacher': 'शिक्षक (Teacher)',
      'role_principal': 'प्रधानाचार्य (Principal)',
      'role_accountant': 'लेखापाल (Accountant)',
      'role_fee_clerk': 'शुल्क लिपिक (Fee Clerk)',

      // Dashboard
      'dashboard': 'डैशबोर्ड',
      'overview': 'अवलोकन',
      'students': 'छात्र',
      'fees': 'शुल्क एवं भुगतान',
      'attendance': 'उपस्थिति',
      'results': 'परीक्षा परिणाम',
      'announcements': 'सूचनाएं',
      'settings': 'सेटिंग्स',

      // Fees & Payments (Manual / Offline Provider)
      'fee_total_due': 'कुल देय शुल्क',
      'fee_total_collected': 'कुल प्राप्त शुल्क',
      'fee_record_payment': 'भुगतान दर्ज करें (नकद / चेक)',
      'fee_breakdown': 'शुल्क विवरण',
      'fee_tuition': 'शिक्षण शुल्क (Tuition)',
      'fee_transport': 'परिवहन शुल्क (Transport)',
      'fee_library': 'पुस्तकालय एवं लैब शुल्क',
      'fee_status_paid': 'भुगतान संपन्न (Paid)',
      'fee_status_unpaid': 'अदत्त (Unpaid)',
      'fee_status_pending': 'सत्यापन प्रक्रियाधीन',
      'fee_receipt': 'आधिकारिक रसीद',
      'fee_history': 'भुगतान इतिहास',
      'fee_payment_mode': 'भुगतान माध्यम (नकद/चेक/बैंक ट्रांसफर)',
      'fee_payment_recorded_success':
          'भुगतान सफलतापूर्वक दर्ज किया गया और रसीद जारी हुई।',

      // Attendance
      'attendance_rate': 'उपस्थिति प्रतिशत',
      'attendance_mark': 'उपस्थिति दर्ज करें',
      'attendance_present': 'उपस्थित',
      'attendance_absent': 'अनुपस्थित',
      'attendance_leave': 'अवकाश पर',
      'attendance_save_confirm': 'उपस्थिति सफलता पूर्वक दर्ज की गई',

      // Results
      'results_term': 'सत्र परीक्षा',
      'results_grade': 'श्रेणी (Grade)',
      'results_marks': 'प्राप्तांक',
      'results_published': 'परिणाम प्रकाशित',
      'results_draft': 'प्रारूप अंक (समीक्षाधीन)',

      // States
      'empty_students': 'कोई छात्र रिकॉर्ड नहीं मिला।',
      'empty_fees': 'वर्तमान में कोई बकाया शुल्क नहीं है।',
      'empty_notices': 'वर्तमान में कोई नई सूचना उपलब्ध नहीं है।',
      'error_network':
          'नेटवर्क संपर्क टूट गया। कृपया अपना इंटरनेट कनेक्शन जांचें।',
      'error_auth': 'प्रमाणीकरण सत्र समाप्त हो गया। कृपया पुन: साइन इन करें।',
      'error_permission':
          'पहुँच अस्वीकृत: आप इस कक्षा या संसाधन के लिए अधिकृत नहीं हैं।',
      'error_generic':
          'एक अप्रत्याशित त्रुटि उत्पन्न हुई। कृपया पुन: प्रयास करें।',
      'offline_mode': 'ऑफ़लाइन मोड सक्रिय। कैश्ड रिकॉर्ड प्रदर्शित हैं।',
    },
  };

  String translate(String key) {
    final languageCode = locale.languageCode;
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

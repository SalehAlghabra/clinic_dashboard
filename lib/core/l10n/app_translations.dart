import 'package:flutter/material.dart';

class AppTranslations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Clinic Management System',
      'dashboard': 'Dashboard',
      'overview': 'Overview',
      'doctors': 'Doctors',
      'appointments': 'Appointments',
      'invoices': 'Invoices & Revenue',
      'violations': 'Violations & Penalties',
      'settings': 'Settings',
      'logout': 'Logout',
      'switch_language': 'العربية',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',

      // Dashboard Stats
      'total_patients': 'Total Patients',
      'new_patients_today': 'New Patients Today',
      'total_doctors': 'Active Doctors',
      'total_receptionists': 'Receptionists',
      'total_appointments': 'Total Appointments',
      'today_appointments': 'Today Appointments',
      'pending_appointments': 'Pending Appointments',
      'confirmed_appointments': 'Confirmed',
      'completed_appointments': 'Completed',
      'cancelled_appointments': 'Cancelled',
      'total_revenue': 'Total Revenue',
      'pending_payments': 'Unpaid Invoices',
      'total_penalties': 'Penalty Revenue',
      'total_deposits': 'Wallet Deposits',

      // Actions
      'quick_actions': 'Quick Actions',
      'add_doctor': 'Add New Doctor',
      'create_staff': 'Register Staff',
      'deposit_wallet': 'Wallet Deposit',
      'view_reports': 'View Detailed Reports',
      'filter_date': 'Filter Date',
      'refresh': 'Refresh Data',

      // Data Tables
      'recent_activity': 'Recent Appointments & Activity',
      'doctor_performance': 'Doctor Performance Overview',
      'patient_name': 'Patient Name',
      'doctor_name': 'Doctor Name',
      'specialization': 'Specialization',
      'service': 'Service',
      'date_time': 'Date & Time',
      'status': 'Status',
      'amount': 'Amount',
      'payment_status': 'Payment Status',
      'actions': 'Actions',
      'violation_count': 'Violations',
      'penalty_rate': 'Penalty Rate',

      // Login
      'login_title': 'CMS Admin Portal Login',
      'email': 'Email Address',
      'password': 'Password',
      'login_button': 'Sign In',
      'welcome_back': 'Welcome Back, Admin',
    },
    'ar': {
      'app_title': 'نظام إدارة العيادات الطبية',
      'dashboard': 'لوحة التحكّم',
      'overview': 'نظرة عامة',
      'doctors': 'الأطباء',
      'appointments': 'المواعيد',
      'invoices': 'الفواتير والإيرادات',
      'violations': 'المخالفات والغرامات',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',
      'switch_language': 'English',
      'light_mode': 'الوضع الفاتح',
      'dark_mode': 'الوضع الداكن',

      // Dashboard Stats
      'total_patients': 'إجمالي المرضى',
      'new_patients_today': 'مرضى جدد اليوم',
      'total_doctors': 'الأطباء النشطون',
      'total_receptionists': 'موظفو الاستقبال',
      'total_appointments': 'إجمالي المواعيد',
      'today_appointments': 'مواعيد اليوم',
      'pending_appointments': 'مواعيد قيد الانتظار',
      'confirmed_appointments': 'المواعيد المؤكدة',
      'completed_appointments': 'المواعيد المكتملة',
      'cancelled_appointments': 'المواعيد الملغاة',
      'total_revenue': 'إجمالي الإيرادات',
      'pending_payments': 'فواتير غير مدفوعة',
      'total_penalties': 'إيرادات الغرامات',
      'total_deposits': 'إيداعات المحفظة',

      // Actions
      'quick_actions': 'إجراءات سريعة',
      'add_doctor': 'إضافة طبيب جديد',
      'create_staff': 'تسجيل موظف جديد',
      'deposit_wallet': 'إيداع بالمحفظة',
      'view_reports': 'عرض التقارير التفصيلية',
      'filter_date': 'فلترة بالتاريخ',
      'refresh': 'تحديث البيانات',

      // Data Tables
      'recent_activity': 'أحدث المواعيد والنشاطات',
      'doctor_performance': 'أداء الأطباء',
      'patient_name': 'اسم المريض',
      'doctor_name': 'اسم الطبيب',
      'specialization': 'التخصص',
      'service': 'الخدمة الطبية',
      'date_time': 'التاريخ والوقت',
      'status': 'الحالة',
      'amount': 'المبلغ',
      'payment_status': 'حالة الدفع',
      'actions': 'الإجراءات',
      'violation_count': 'عدد المخالفات',
      'penalty_rate': 'نسبة الغرامة',

      // Login
      'login_title': 'تسجيل دخول لوحة التحكم',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login_button': 'تسجيل الدخول',
      'welcome_back': 'أهلاً بك مجدداً',
    },
  };

  static String translate(String key, String localeCode) {
    return _localizedValues[localeCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

extension BuildContextLoc on BuildContext {
  String tr(String key) {
    final locale = Localizations.localeOf(this).languageCode;
    return AppTranslations.translate(key, locale);
  }

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

// lib/core/constants/locale/app_strings.dart
class AppStrings {
  const AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // Auth
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'no_account': "Don't have an account?",
      'have_account': 'Already have an account?',
      'log_in': 'Log in',
      'continue_google': 'Continue with Google',
      'first_name': 'First Name',
      'second_name': 'Second Name',
      'phone_number': 'Phone Number',
      'verification_code_sent': 'Verification code sent to your email',
      'or': 'OR',

      // Verify Email
      'email_verification': 'Email Verification',
      'password_recovery': 'Password Recovery',
      'enter_code': 'Enter the 6 digit code sent to',
      'didnt_get_email': "Didn't get any email?",
      'resend_code': 'Resend Code',
      'cancel': 'Cancel',

      // Validation
      'enter_email': 'Please enter your email',
      'valid_email': 'Please enter a valid email',
      'enter_password': 'Please enter your password',
      'password_length': 'Password must be at least 6 characters',
      'enter_first_name': 'Enter your first name',
      'enter_second_name': 'Enter your second name',
      'name_length': 'Name must be at least 2 characters',

      // Forgot Password
      'forgot_password_title': 'Forgot Password',
      'enter_email_reset': 'Enter your email to reset your password',
      'send_otp': 'Send OTP',
      'sending': 'Sending...',

      // Change Password
      'change_password': 'Change Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'update_password': 'Update Password',
      'enter_new_password': 'Please enter a new password',
      'confirm_your_password': 'Please confirm your password',
      'passwords_not_match': 'Passwords do not match',
      'password_updated': 'Password updated successfully',

      // Change Name
      'change_name': 'Change Name',
      'new_first_name': 'New First Name',
      'new_second_name': 'New Second Name',
      'update_name': 'Update Name',
      'enter_new_name': 'Please enter a new Name',
      'enter_second_name_field': 'Please enter your Second Name',
      'name_updated': 'Name updated successfully',

      // OTP
      'otp_sent': 'OTP sent to',
      'check_inbox': 'please check your inbox',
      'otp_resent': 'OTP resent to',
      'verification_success': 'Email verified successfully!',
      'recovery_success': 'Email verified! Now set your new password',
      'enter_complete_code': 'Please enter the complete code',
      'verification_failed': 'Verification failed',
      'error_resending': 'Error resending OTP',
      'error_prefix': 'Error',
      'no_email_found': 'No email found',
    },
    'ar': {
      // Auth
      'sign_in': 'تسجيل الدخول',
      'sign_up': 'إنشاء حساب',
      'login': 'دخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'no_account': 'ليس لديك حساب؟',
      'have_account': 'لديك حساب بالفعل؟',
      'log_in': 'تسجيل الدخول',
      'continue_google': 'المتابعة عبر جوجل',
      'first_name': 'الاسم الأول',
      'second_name': 'الاسم الثاني',
      'phone_number': 'رقم الهاتف',
      'verification_code_sent': 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
      'or': 'أو',

      // Verify Email
      'email_verification': 'التحقق من البريد الإلكتروني',
      'password_recovery': 'استعادة كلمة المرور',
      'enter_code': 'أدخل الرمز المكون من 6 أرقام المرسل إلى',
      'didnt_get_email': 'لم تستلم أي بريد إلكتروني؟',
      'resend_code': 'إعادة إرسال الرمز',
      'cancel': 'إلغاء',

      // Validation
      'enter_email': 'يرجى إدخال البريد الإلكتروني',
      'valid_email': 'يرجى إدخال بريد إلكتروني صحيح',
      'enter_password': 'يرجى إدخال كلمة المرور',
      'password_length': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'enter_first_name': 'أدخل اسمك الأول',
      'enter_second_name': 'أدخل اسمك الثاني',
      'name_length': 'يجب أن يكون الاسم حرفين على الأقل',

      // Forgot Password
      'forgot_password_title': 'نسيت كلمة المرور',
      'enter_email_reset': 'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
      'send_otp': 'إرسال الرمز',
      'sending': 'جارٍ الإرسال...',

      // Change Password
      'change_password': 'تغيير كلمة المرور',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_password': 'تأكيد كلمة المرور',
      'update_password': 'تحديث كلمة المرور',
      'enter_new_password': 'يرجى إدخال كلمة مرور جديدة',
      'confirm_your_password': 'يرجى تأكيد كلمة المرور',
      'passwords_not_match': 'كلمتا المرور غير متطابقتين',
      'password_updated': 'تم تحديث كلمة المرور بنجاح',

      // Change Name
      'change_name': 'تغيير الاسم',
      'new_first_name': 'الاسم الأول الجديد',
      'new_second_name': 'الاسم الثاني الجديد',
      'update_name': 'تحديث الاسم',
      'enter_new_name': 'يرجى إدخال اسم جديد',
      'enter_second_name_field': 'يرجى إدخال اسمك الثاني',
      'name_updated': 'تم تحديث الاسم بنجاح',

      // OTP
      'otp_sent': 'تم إرسال الرمز إلى',
      'check_inbox': 'يرجى مراجعة بريدك الوارد',
      'otp_resent': 'أعيد إرسال الرمز إلى',
      'verification_success': 'تم التحقق من البريد الإلكتروني بنجاح!',
      'recovery_success': 'تم التحقق! قم الآن بتعيين كلمة مرور جديدة',
      'enter_complete_code': 'يرجى إدخال الرمز كاملاً',
      'verification_failed': 'فشل التحقق',
      'error_resending': 'خطأ في إعادة إرسال الرمز',
      'error_prefix': 'خطأ',
      'no_email_found': 'لم يتم العثور على البريد الإلكتروني',
    },
  };

  static String get(String key, String languageCode) {
    return _strings[languageCode]?[key] ?? _strings['en']![key] ?? key;
  }
}

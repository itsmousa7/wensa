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
      'continue_apple': 'Continue with Apple',
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

      // Change Phone
      'change_phone': 'Change Phone Number',
      'update_phone': 'Update Phone Number',
      'phone_updated': 'Phone number updated successfully',

      // Change Email
      'change_email': 'Change Email',
      'new_email': 'New Email Address',
      'update_email': 'Update Email',
      'enter_new_email': 'Please enter a new email address',
      'email_same_as_current': 'New email must be different from your current email',
      'email_change_success': 'Email updated successfully!',
      'email_change_otp_sent': 'A verification code was sent to your new email',
      'email_change_title': 'Verify New Email',
      'email_already_registered': 'This email is already linked to another account. Please use a different email address.',

      // OTP
      'otp_sent': 'OTP sent to',
      'check_inbox': 'please check your inbox',
      'otp_resent': 'OTP resent to',
      'verification_success': 'Email verified successfully!',
      'recovery_success': 'Email verified! Now set your new password',
      'enter_complete_code': 'Please enter the complete code',
      'verification_failed': 'Verification failed',
      'otp_expired': 'This code has expired. Tap "Resend Code" to get a new one.',
      'otp_invalid': 'Incorrect code. Please check and try again.',
      'error_resending': 'Error resending OTP',
      'error_prefix': 'Error',
      'no_email_found': 'No email found',

      // Complete Profile
      'complete_profile_title': 'Complete your profile',
      'complete_profile_subtitle':
          'We just need a few details to finish setting up your account.',
      'enter_phone': 'Please enter your phone number',
      'valid_phone': 'Please enter a valid phone number',
      'save': 'Save',
      'sign_out': 'Sign out',

      // Onboarding
      'onboarding_title_1': "Discover what's around you",
      'onboarding_body_1':
          'Farms, parties, restaurants and outings — all in one place.',
      'onboarding_title_2': 'Book courts & grab tickets',
      'onboarding_body_2':
          'Padel, football pitches, events and tickets — reserve them all from your seat.',
      'onboarding_title_3': 'All the fun in one place',
      'onboarding_body_3':
          'One tap to book and enjoy — your good times, made effortless.',
      'onboarding_skip': 'Skip',
      'onboarding_next': 'Next',
      'onboarding_get_started': 'Get Started',
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
      'continue_apple': 'المتابعة عبر آبل',
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

      // Change Phone
      'change_phone': 'تغيير رقم الهاتف',
      'update_phone': 'تحديث رقم الهاتف',
      'phone_updated': 'تم تحديث رقم الهاتف بنجاح',

      // Change Email
      'change_email': 'تغيير البريد الإلكتروني',
      'new_email': 'البريد الإلكتروني الجديد',
      'update_email': 'تحديث البريد الإلكتروني',
      'enter_new_email': 'يرجى إدخال بريد إلكتروني جديد',
      'email_same_as_current': 'يجب أن يكون البريد الجديد مختلفاً عن بريدك الحالي',
      'email_change_success': 'تم تحديث البريد الإلكتروني بنجاح!',
      'email_change_otp_sent': 'تم إرسال رمز التحقق إلى بريدك الإلكتروني الجديد',
      'email_change_title': 'تحقق من البريد الجديد',
      'email_already_registered': 'هذا البريد الإلكتروني مرتبط بحساب آخر. يرجى استخدام بريد إلكتروني مختلف.',

      // OTP
      'otp_sent': 'تم إرسال الرمز إلى',
      'check_inbox': 'يرجى مراجعة بريدك الوارد',
      'otp_resent': 'أعيد إرسال الرمز إلى',
      'verification_success': 'تم التحقق من البريد الإلكتروني بنجاح!',
      'recovery_success': 'تم التحقق! قم الآن بتعيين كلمة مرور جديدة',
      'enter_complete_code': 'يرجى إدخال الرمز كاملاً',
      'verification_failed': 'فشل التحقق',
      'otp_expired': 'انتهت صلاحية هذا الرمز. اضغط على "إعادة إرسال الرمز" للحصول على رمز جديد.',
      'otp_invalid': 'الرمز غير صحيح. يرجى التحقق والمحاولة مجدداً.',
      'error_resending': 'خطأ في إعادة إرسال الرمز',
      'error_prefix': 'خطأ',
      'no_email_found': 'لم يتم العثور على البريد الإلكتروني',

      // Complete Profile
      'complete_profile_title': 'أكمل ملفك الشخصي',
      'complete_profile_subtitle':
          'نحتاج فقط إلى بعض المعلومات لإكمال إعداد حسابك.',
      'enter_phone': 'يرجى إدخال رقم الهاتف',
      'valid_phone': 'يرجى إدخال رقم هاتف صحيح',
      'save': 'حفظ',
      'sign_out': 'تسجيل الخروج',

      // Onboarding — لهجة عراقية
      'onboarding_title_1': 'شوف شكو ماكو داير مدايرك',
      'onboarding_body_1': 'مزارع، حفلات، مطاعم وطلعات... كلها بمكان واحد.',
      'onboarding_title_2': 'احجز ملعبك وتذكرتك',
      'onboarding_body_2':
          'بادل، ملاعب خماسي، فعاليات وتذاكر… احجزها كلها وانت بمكانك.',
      'onboarding_title_3': 'كل الونسة بنفس المكان',
      'onboarding_body_3':
          'بدوسة وحدة تحجز وتتونس... الونسة صارت أسهل من قبل بهواية.',
      'onboarding_skip': 'تخطّي',
      'onboarding_next': 'التالي',
      'onboarding_get_started': 'يلّا نبدأ',
    },
  };

  static String get(String key, String languageCode) {
    return _strings[languageCode]?[key] ?? _strings['en']![key] ?? key;
  }
}

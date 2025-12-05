
class ErrorTranslator {
  static String translate(String technicalError) {
    // Convert Firebase error codes to user-friendly messages
    final errorMap = {
      // Authentication errors
      'INVALID_LOGIN_CREDENTIALS': 'Incorrect email or password. Please try again.',
      'EMAIL_NOT_FOUND': 'No account found with this email address.',
      'INVALID_PASSWORD': 'Incorrect password. Please try again.',
      'USER_DISABLED': 'This account has been disabled. Please contact support.',
      'TOO_MANY_ATTEMPTS_TRY_LATER': 'Too many failed login attempts. Please try again later.',
      'EMAIL_EXISTS': 'An account with this email already exists.',
      'OPERATION_NOT_ALLOWED': 'This operation is not allowed. Please contact support.',
      'WEAK_PASSWORD': 'Password is too weak. Please use at least 6 characters.',
      'INVALID_EMAIL': 'Invalid email address format.',

      // Network errors
      'NETWORK_ERROR': 'Network connection failed. Please check your internet connection.',
      'TIMEOUT': 'Request timed out. Please check your internet connection and try again.',

      // Generic errors
      'Login failed': 'Login failed. Please check your email and password.',
      'Registration failed': 'Registration failed. Please try again.',
      'Failed to send reset email': 'Could not send password reset email. Please check your email address.',
    };

    // Check if we have a translation for this error
    for (var key in errorMap.keys) {
      if (technicalError.contains(key)) {
        return errorMap[key]!;
      }
    }

    // If error starts with "Network error:", make it friendly
    if (technicalError.toLowerCase().contains('network error')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    // Default friendly message
    return 'Something went wrong. Please try again.';
  }
}
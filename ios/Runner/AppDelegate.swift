import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // ============================================
  // Google OAuth Callback Handler (REQUIRED)
  // ============================================
  // Intercepta URLs de callback do Google OAuth
  // Sem este método, o iOS NÃO sabe que o app deve abrir
  // quando Google tenta redirecionar para com.googleusercontent.apps...:/
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Delega para o plugin google_sign_in
    return super.application(app, open: url, options: options)
  }
}

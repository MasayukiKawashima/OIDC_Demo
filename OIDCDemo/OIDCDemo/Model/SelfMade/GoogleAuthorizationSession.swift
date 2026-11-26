//
//  GoogleAuthorizationSession.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/26.
//

import AuthenticationServices
import UIKit

/// 認可リクエストを行うクラス
/// ブラウザでの認可リクエスト1回分。サインインのたびに作り、start() は1回だけ呼ぶ
final class GoogleAuthorizationSession: NSObject {

  // MARK: - Properties

  private let authorizationEndpoint: URL
  private let redirectURI: String
  private let state: String
  private let nonce: String
  private let codeChallenge: String
  private let codeChallengeMethod: String
  private let prefersEphemeral: Bool

  private var session: ASWebAuthenticationSession?
  private var continuation: CheckedContinuation<URL, any Error>?
  private var anchor: ASPresentationAnchor?

  private var hasStarted = false

  // MARK: - Init

  init(
    authorizationEndpoint: URL,
    redirectURI: String,
    state: String,
    nonce: String,
    codeChallenge: String,
    codeChallengeMethod: String,
    prefersEphemeral: Bool = false
  ) {
    self.authorizationEndpoint = authorizationEndpoint
    self.redirectURI = redirectURI
    self.state = state
    self.nonce = nonce
    self.codeChallenge = codeChallenge
    self.codeChallengeMethod = codeChallengeMethod
    self.prefersEphemeral = prefersEphemeral

    super.init()
  }

  // MARK: - Methods
  // MARK: - Start

  /// ブラウザで認可リクエストを行い、リダイレクトで戻ってきた URL を返す。
  func start() async throws -> URL {
    // 同じインスタンスでの2回目の呼び出しを止める
    guard !hasStarted else {
      throw GoogleAuthorizationError.alreadyStarted
    }
    hasStarted = true

    // ブラウザを開く前に、失敗し得る準備をすべて済ませる
    // 表示先のウインドウを探す
    let anchor = try findPresentationAnchor()
    // 認可 URL を組み立てる
    let url = try authorizationRequestURL()
    // redirect_uri からスキーム（逆順クライアントID）を取り出す
    let callbackScheme = try callbackScheme()
    self.anchor = anchor

    // ブラウザを開き、完了ハンドラーで resume されるまで待つ
    // クロージャーの中身はすぐに最後まで実行され、クロージャーを抜けたところで start() は中断する
    // resume されると、withCheckedThrowingContinuation が resume で渡された値を返し（失敗ならエラーを投げ）、
    // ここから再開する。戻り値は callbackURL に入る
    let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in

      // 中断している start() を、後で再開させるための引換券を保持する
      self.continuation = continuation

      // ASWebAuthenticationSession（ブラウザ）を作る
      let session = ASWebAuthenticationSession(
        url: url,
        callback: .customScheme(callbackScheme)
      ) { callbackURL, error in
        // ブラウザでのやり取りが終わったときに呼ばれる
        // （リダイレクトを受け取って自動で閉じたとき、キャンセルしたとき、失敗したとき）
        // handleCompletion → finish で、この結果（成功なら URL、失敗ならエラー）を渡して resume する
        self.handleCompletion(callbackURL: callbackURL, error: error)
      }

      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = prefersEphemeral
      self.session = session

      // ブラウザを開き、開始できたかを戻り値で判定する
      // 開始できなければ完了ハンドラーは呼ばれないため、ここで resume する
      if session.start() {
        print("[Authorization] ブラウザを開いた")
      } else {
        print("[Authorization] 失敗（開始できない）")
        finish(with: .failure(GoogleAuthorizationError.cannotStart))
      }
    }
    return callbackURL
  }

  // MARK: - Completion

  /// 完了ハンドラーの結果を、成功・失敗に振り分ける
  private func handleCompletion(callbackURL: URL?, error: (any Error)?) {
    if let callbackURL {
      print("[Authorization] コールバックを受信")
      finish(with: .success(callbackURL))
    } else if let error {
      let nsError = error as NSError
      print("[Authorization] 失敗（\(nsError.domain) \(nsError.code)）")
      finish(with: .failure(error))
    } else {
      print("[Authorization] 失敗（URL もエラーもない）")
      finish(with: .failure(GoogleAuthorizationError.missingCallbackURL))
    }
  }

  // MARK: - HelperMethods

  /// リクエストURL組み立て
  private func authorizationRequestURL() throws -> URL {
    // ベース
    guard var urlComponents = URLComponents(url: authorizationEndpoint, resolvingAgainstBaseURL: false) else {
      throw GoogleAuthorizationError.invalidAuthorizationURL
    }

    // パラメータ
    let parameters = [
      URLQueryItem(name: "client_id", value: AppConfig.googleClientID),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "scope", value: "openid profile"),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "nonce", value: nonce),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod),
    ]

    // パラメータ埋め込み
    urlComponents.queryItems = (urlComponents.queryItems ?? []) + parameters

    guard let url = urlComponents.url else {
      throw GoogleAuthorizationError.invalidAuthorizationURL
    }
    return url
  }

  /// redirect_uri からスキーム（逆順クライアントID）を取り出す
  /// ASWebAuthenticationSession は、このスキームの URL へリダイレクトされると、ブラウザを閉じて完了ハンドラーを呼ぶ
  private func callbackScheme() throws -> String {
    guard let scheme = URLComponents(string: redirectURI)?.scheme else {
      throw GoogleAuthorizationError.invalidRedirectURI
    }
    return scheme
  }

  /// 前面にあるシーンのキーウインドウを探す
  private func findPresentationAnchor() throws -> ASPresentationAnchor {
    let windowScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }

    guard let window = windowScene?.keyWindow else {
      print("[Authorization] 失敗（表示先のウインドウがない）")
      throw GoogleAuthorizationError.noPresentationAnchor
    }
    return window
  }

  /// continuation を1回だけ resume し、ブラウザを開いている間の状態を片付ける
  private func finish(with result: Result<URL, any Error>) {
    continuation?.resume(with: result)
    continuation = nil
    session = nil
    anchor = nil
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GoogleAuthorizationSession: ASWebAuthenticationPresentationContextProviding {

  /// ASWebAuthenticationSession が、ブラウザを表示する直前に、表示先のウインドウを尋ねるために呼ぶメソッド
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    guard let anchor else {
      preconditionFailure("start() でウインドウを決めてからセッションを開始している")
    }
    return anchor
  }
}

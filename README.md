# OIDC Demo (iOS)

## 概要
Google を IdP として、iOS アプリ側の OpenID Connect（Authorization Code Flow + PKCE）を学習するためのデモアプリです。
Google・iOSアプリ・自社バックエンドの3者構成を想定していますが、この構成のうちアプリ側の処理だけを今回の学習範囲としています。バックエンドは用意しておらずアプリ側にモックを作成してバックエンドの代わりとしています。

> **クローンして利用される場合は、[クローンして利用する場合](#usage) を確認してください。**
### 処理の流れ

1. アプリが Google に認可リクエストを送る（PKCE、state、nonce を付ける）
2. Google がログイン後、認可コードをアプリに返す
3. アプリが認可コードを ID トークンと交換する
4. アプリが ID トークンをモック（バックエンドの代わり）に送る
5. モックが自社のトークンを返し、アプリが Keychain に保存する

### 実装の方針

- `ASWebAuthenticationSession` による自前実装と AppAuth-iOS 版実装の両方を行う
- スコープは `openid` と `profile` のみ。ID トークンは `iss`、`aud`、`exp`、`nonce` を確認する（署名の検証はバックエンドの処理として範囲外）
- Google のトークンは保存せず、自社のトークンだけを Keychain に保存する

<a id="usage"></a>

## クローンして利用する場合

### 1. Google Cloud で OAuth クライアントを作成する

- 同意画面は「テスト中」にし、テストユーザーに自分のアカウントを登録する（スコープは `openid`、`profile`）
- OAuth クライアントは種類に **iOS** を選び、手順 2 と同じバンドル ID を登録する

詳細は [OAuth 2.0 for iOS & Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app) を参照してください。

### 2. `Config.xcconfig` を作成する

```sh
cp Config.sample.xcconfig Config.xcconfig
```

4 つの値を自分の値に書き換えます。

| 設定名 | 書く値 |
| --- | --- |
| `GOOGLE_CLIENT_ID` | クライアント ID |
| `GOOGLE_REVERSED_CLIENT_ID` | iOS URL スキーム |
| `PRODUCT_BUNDLE_IDENTIFIER` | Google Cloud に登録したバンドル ID |
| `DEVELOPMENT_TEAM` | Apple の Team ID（Xcode の Build Settings → Development Team →「Other…」で確認） |

### 3. ビルドする

`OIDCDemo/OIDCDemo.xcodeproj` を開いてビルドします。バンドル ID と Team は Xcode の画面ではなく、`Config.xcconfig` で変更してください（画面で変更すると `project.pbxproj` に値が書き込まれます）。

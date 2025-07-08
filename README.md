# ITSANDBOX - 法政大学 IT Innovation Community

<div align="center">

![ITSANDBOX Logo](https://img.shields.io/badge/ITSANDBOX-法政大学_IT_Innovation-orange?style=for-the-badge&logo=university)

**💡 好きなものを、一緒に作りませんか？**

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange.svg)](https://aws.amazon.com/)
[![React](https://img.shields.io/badge/React-18.x-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green.svg)](https://nodejs.org/)

**法政大学の仲間と一緒に、わくわくするプロジェクトを開発するコミュニティ**

</div>

## 🎯 ITSANDBOXとは

法政大学の仲間と一緒に、わくわくするプロジェクトを開発するコミュニティです！

### 📋 参加資格

✅ **法政大学工学部経営工学科** 卒業生  
✅ **法政大学理工学部経営システム工学科** 卒業生・学生・現職教員・元教員

### 🛠️ 開発環境

- **プラットフォーム**: AWS中心、GitHub開発
- **技術レベル**: Vibeコーディングでリラックス開発！超専門的な技術は不要
- **運用費**: 同窓会費からAWS運用コスト月額100ドル（全プロジェクト合計をサポート）

### 🎯 プロジェクト内容

**「好きなもの、わくわくするものを作る」**

- 🚀 アイデア自由！あなたの「作りたい」を形に
- 👥 最小2名以上のチームで開発（2名集まらない場合でもスタートする場合あり）
- 🎓 法政の仲間と新しいものづくりにチャレンジ

### 🤝 こんな方におすすめ

- 🎓 学生時代の仲間と久しぶりに何か作りたい
- 🆕 新しいことにチャレンジしたい
- 🔧 ものづくりが好き
- 🌐 法政のネットワークを活かしたい

## 🏗️ 技術スタック

### フロントエンド
- **React 18** + **TypeScript**
- **Tailwind CSS** - モダンなUIデザイン
- **React Router** - SPA ナビゲーション
- **Framer Motion** - アニメーション

### バックエンド
- **AWS Lambda** - サーバーレス API
- **API Gateway** - REST API エンドポイント
- **DynamoDB** - NoSQL データベース
- **Node.js** + **TypeScript**

### インフラ・デプロイメント
- **AWS S3** + **CloudFront** - 静的ウェブサイトホスティング
- **Route 53** - ドメイン管理
- **Certificate Manager** - SSL証明書
- **GitHub Actions** - CI/CD

### 開発・運用
- **GitHub** - バージョン管理
- **ESLint** + **Prettier** - コード品質
- **Jest** - テスト
- **AWS CloudWatch** - 監視・ログ

## 📁 プロジェクト構造

```
ITSANDBOX/
├── frontend/                 # React フロントエンド
│   ├── src/
│   │   ├── components/      # 再利用可能なコンポーネント
│   │   ├── pages/          # ページコンポーネント
│   │   ├── hooks/          # カスタムフック
│   │   ├── services/       # API サービス
│   │   └── utils/          # ユーティリティ関数
│   ├── public/             # 静的ファイル
│   └── package.json
├── backend/                 # Node.js バックエンド
│   ├── src/
│   │   ├── handlers/       # Lambda ハンドラー
│   │   ├── services/       # ビジネスロジック
│   │   ├── models/         # データモデル
│   │   └── utils/          # ユーティリティ関数
│   └── package.json
├── infrastructure/          # AWS インフラ設定
│   ├── terraform/          # Terraform 設定
│   └── cloudformation/     # CloudFormation テンプレート
├── docs/                   # ドキュメント
└── README.md
```

## 🚀 クイックスタート

### 前提条件

- Node.js 18+
- AWS CLI（適切な権限で設定済み）
- Git

### 1. プロジェクトのクローン

```bash
git clone https://github.com/hosei-itsandbox/itsandbox-website.git
cd itsandbox-website
```

### 2. 依存関係のインストール

```bash
# フロントエンド
cd frontend
npm install

# バックエンド
cd ../backend
npm install
```

### 3. 開発サーバーの起動

```bash
# フロントエンド（ポート3000）
cd frontend
npm run dev

# バックエンド（ポート3001）
cd ../backend
npm run dev
```

## 💰 コスト分析

### AWS無料利用枠の活用

| サービス | 無料利用枠 | 予想使用量 | 月額コスト |
|----------|------------|------------|------------|
| **S3** | 5GB ストレージ | 1GB | $0.00 |
| **CloudFront** | 1TB データ転送 | 100GB | $0.00 |
| **Lambda** | 100万リクエスト | 10万リクエスト | $0.00 |
| **API Gateway** | 100万リクエスト | 10万リクエスト | $0.00 |
| **DynamoDB** | 25GB ストレージ | 5GB | $0.00 |
| **Route 53** | - | ドメイン管理 | $0.50 |
| **Certificate Manager** | 無料 | SSL証明書 | $0.00 |

**合計月額コスト: $0.50 - $2.00**

## 🎨 デザインコンセプト

### ブランドカラー
- **プライマリ**: オレンジ (#FF6B35) - 活気・創造性
- **セカンダリ**: ネイビー (#2C3E50) - 信頼性・専門性
- **アクセント**: グリーン (#27AE60) - 成長・協力

### UI/UX原則
- **シンプル**: 直感的で使いやすい
- **モダン**: 最新のデザイントレンド
- **アクセシブル**: 誰でも使える
- **レスポンシブ**: デバイス問わず最適表示

## 🔧 開発ガイドライン

### コーディング規約
- **TypeScript** 厳密な型定義
- **ESLint** + **Prettier** 統一されたコードスタイル
- **関数コンポーネント** + **Hooks** 中心
- **カスタムフック** でロジックの再利用

### Git フロー
```bash
# 機能ブランチの作成
git checkout -b feature/new-feature

# コミット
git commit -m "feat: add new feature"

# プッシュ
git push origin feature/new-feature

# プルリクエスト作成
```

## 📞 お問い合わせ

**参加希望・お問い合わせ**:  
📧 [hoseiitsandbox@gmail.com](mailto:hoseiitsandbox@gmail.com)

**SNS・コミュニティ**:  
🐱 [GitHub Organization](https://github.com/hosei-itsandbox)

## 🏆 貢献者

このプロジェクトに貢献してくださった法政大学の皆様に感謝いたします！

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下でライセンスされています。

---

**今すぐ参加して、一緒に面白いものを作りましょう！**

*#法政大学 #ITSANDBOX #プログラミング #ものづくり #AWS #GitHub #同窓会 #エンジニア #開発 #イノベーション*
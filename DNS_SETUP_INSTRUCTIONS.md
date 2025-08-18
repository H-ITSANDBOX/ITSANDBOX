# hosei-itsandbox.com DNS設定手順

## 現在の状況
✅ AWS CloudFront: `https://d1cbsftfdltu35.cloudfront.net/` - 正常動作  
✅ SSL証明書: 発行済み  
✅ Route 53設定: 完了  

## ドメインレジストラーでの設定が必要

### ネームサーバー設定
ドメインレジストラー（お名前.com、ムームードメインなど）で以下のネームサーバーを設定：

```
ns-1004.awsdns-61.net
ns-16.awsdns-02.com  
ns-1409.awsdns-48.org
ns-1876.awsdns-42.co.uk
```

### 確認方法
1. ドメインレジストラーの管理画面にログイン
2. hosei-itsandbox.com のDNS設定を開く
3. ネームサーバーを上記のAWSネームサーバーに変更
4. 保存・適用（通常1-48時間で反映）

### 動作テスト
- CloudFront直接アクセス: https://d1cbsftfdltu35.cloudfront.net/
- Lambda直接アクセス: https://c53ft64qpvtbz65vtnghynf7ne0ziagq.lambda-url.ap-northeast-1.on.aws/
- 目標URL（DNS反映後）: https://hosei-itsandbox.com/

### Route 53設定確認済み
- ホストゾーンID: Z05594992ZJLL5N3ZBRGF
- Aレコード: d1cbsftfdltu35.cloudfront.net へのエイリアス
- SSL証明書: arn:aws:acm:us-east-1:555111848813:certificate/617125a5-01cf-426b-b45f-90a2c9c3ddfa

## 月額コスト
約$4.85（Route 53 $0.50 + CloudFront $3.50 + Lambda $0.85）
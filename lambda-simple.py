def lambda_handler(event, context):
    """Simple Lambda function for API Gateway"""
    
    html = '''<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ITSANDBOX - 法政大学ITイノベーションコミュニティ</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { font-family: 'Noto Sans JP', sans-serif; }
        .gradient-text {
            background: linear-gradient(135deg, #FF6B35 0%, #27AE60 50%, #2C3E50 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
    </style>
</head>
<body class="bg-black text-white min-h-screen flex items-center justify-center">
    <div class="container mx-auto px-6 text-center">
        <h1 class="text-6xl md:text-8xl font-black mb-8">
            <span class="gradient-text">ITSANDBOX</span>
        </h1>
        <p class="text-2xl mb-4">好きなものを、<span style="color: #FF6B35;">一緒に</span>作りませんか？</p>
        <p class="text-lg text-gray-400 mb-12 max-w-3xl mx-auto">
            法政大学の仲間と一緒に、わくわくするプロジェクトを開発するコミュニティです。<br>
            <span class="text-orange-400 font-bold">🌐 カスタムドメイン https://hosei-itsandbox.com で公開準備中！</span>
        </p>
        
        <div class="bg-gray-900/50 p-6 rounded-xl max-w-2xl mx-auto">
            <h3 class="text-xl font-bold mb-4">🚀 AWS Lambda + API Gateway + Route 53</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div class="bg-black/40 p-3 rounded">
                    <div class="text-orange-400">稼働率</div>
                    <div class="text-xl font-bold">99.95%</div>
                </div>
                <div class="bg-black/40 p-3 rounded">
                    <div class="text-orange-400">SSL</div>
                    <div class="text-xl font-bold">🔒</div>
                </div>
                <div class="bg-black/40 p-3 rounded">
                    <div class="text-orange-400">ドメイン</div>
                    <div class="text-xl font-bold">✅</div>
                </div>
                <div class="bg-black/40 p-3 rounded">
                    <div class="text-orange-400">コスト</div>
                    <div class="text-xl font-bold">$4.85</div>
                </div>
            </div>
        </div>
        
        <div class="mt-8">
            <a href="mailto:join@itsandbox.hosei.ac.jp" 
               class="inline-block px-8 py-4 bg-gradient-to-r from-orange-500 to-green-500 rounded-full text-lg font-bold hover:scale-105 transition-transform">
                今すぐ参加申込み →
            </a>
        </div>
    </div>
</body>
</html>'''
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': html
    }
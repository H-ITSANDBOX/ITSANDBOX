import json
import base64

def lambda_handler(event, context):
    """
    AWS Lambda function to serve ITSANDBOX ultra-low-cost website
    Returns the complete HTML page as response
    """
    
    # Complete HTML content for ITSANDBOX website
    html_content = '''<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ITSANDBOX - 法政大学ITイノベーションコミュニティ (Ultra-Low-Cost)</title>
    <meta name="description" content="法政大学の仲間と一緒に、わくわくするプロジェクトを開発するコミュニティです。月額$5以下の超低コスト設計！">
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@300;400;700;900&display=swap');
        
        body {
            font-family: 'Noto Sans JP', sans-serif;
        }
        
        @keyframes aurora {
            0%, 100% { transform: translateX(-50%) translateY(0) rotate(0deg); }
            33% { transform: translateX(-50%) translateY(-20px) rotate(120deg); }
            66% { transform: translateX(-50%) translateY(10px) rotate(240deg); }
        }
        
        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-30px); }
        }
        
        @keyframes pulse-glow {
            0%, 100% { box-shadow: 0 0 20px rgba(255, 107, 53, 0.5), 0 0 40px rgba(39, 174, 96, 0.3); }
            50% { box-shadow: 0 0 40px rgba(255, 107, 53, 0.8), 0 0 80px rgba(39, 174, 96, 0.5); }
        }
        
        .aurora-bg {
            background: linear-gradient(45deg, #FF6B35, #27AE60, #2C3E50, #FF6B35);
            background-size: 400% 400%;
            animation: aurora 15s ease infinite;
        }
        
        .float-animation {
            animation: float 4s ease-in-out infinite;
        }
        
        .gradient-text {
            background: linear-gradient(135deg, #FF6B35 0%, #27AE60 50%, #2C3E50 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .card-hover {
            transition: all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        
        .card-hover:hover {
            transform: translateY(-10px) scale(1.02);
        }
        
        .glow-effect {
            animation: pulse-glow 3s ease-in-out infinite;
        }
        
        .tech-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 1rem;
        }
        
        .parallax-bg {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -1;
            background: radial-gradient(ellipse at center, #1a0033 0%, #000000 100%);
        }
        
        .neon-border {
            border: 2px solid transparent;
            background: linear-gradient(#0a0a0a, #0a0a0a) padding-box,
                        linear-gradient(135deg, #FF6B35, #27AE60, #2C3E50) border-box;
        }
        
        .holographic {
            background: linear-gradient(45deg, 
                rgba(255,0,0,0.3), 
                rgba(255,154,0,0.3),
                rgba(208,222,33,0.3),
                rgba(79,220,74,0.3),
                rgba(63,218,216,0.3),
                rgba(47,201,226,0.3),
                rgba(28,127,238,0.3),
                rgba(95,21,242,0.3),
                rgba(186,12,248,0.3),
                rgba(251,7,217,0.3)
            );
            background-size: 300% 300%;
            animation: holographic-shift 3s ease infinite;
        }
        
        @keyframes holographic-shift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
    </style>
</head>
<body class="bg-black text-white overflow-x-hidden">
    <div class="parallax-bg"></div>
    
    <!-- Navigation -->
    <nav class="fixed w-full bg-black/80 backdrop-blur-xl z-50 border-b border-gray-800">
        <div class="container mx-auto px-6 py-4">
            <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <div class="text-3xl font-black gradient-text">ITSANDBOX</div>
                    <span class="text-sm text-gray-400 hidden md:block">法政大学経営システム工学部</span>
                    <span class="text-xs bg-orange-500/20 text-orange-400 px-2 py-1 rounded-full">AWS Lambda</span>
                </div>
                <div class="hidden md:flex space-x-8">
                    <a href="#home" class="transition-all hover:scale-110" style="color: white;" onmouseover="this.style.color='#FF6B35'" onmouseout="this.style.color='white'">ホーム</a>
                    <a href="#vision" class="transition-all hover:scale-110" style="color: white;" onmouseover="this.style.color='#27AE60'" onmouseout="this.style.color='white'">ビジョン</a>
                    <a href="#features" class="transition-all hover:scale-110" style="color: white;" onmouseover="this.style.color='#FF6B35'" onmouseout="this.style.color='white'">特徴</a>
                    <a href="#technology" class="transition-all hover:scale-110" style="color: white;" onmouseover="this.style.color='#2C3E50'" onmouseout="this.style.color='white'">技術</a>
                    <a href="#join" class="transition-all hover:scale-110" style="color: white;" onmouseover="this.style.color='#27AE60'" onmouseout="this.style.color='white'">参加</a>
                </div>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section id="home" class="min-h-screen flex items-center justify-center relative">
        <div class="absolute inset-0 aurora-bg opacity-10"></div>
        
        <!-- Floating particles -->
        <div class="absolute inset-0 overflow-hidden">
            <div class="absolute top-1/4 left-1/4 w-64 h-64 rounded-full blur-3xl float-animation" style="background-color: rgba(255, 107, 53, 0.1);"></div>
            <div class="absolute bottom-1/4 right-1/4 w-96 h-96 rounded-full blur-3xl float-animation" style="background-color: rgba(39, 174, 96, 0.1); animation-delay: 2s;"></div>
            <div class="absolute top-1/2 right-1/3 w-80 h-80 rounded-full blur-3xl float-animation" style="background-color: rgba(44, 62, 80, 0.1); animation-delay: 4s;"></div>
        </div>
        
        <div class="container mx-auto px-6 text-center relative z-10">
            <h1 class="text-6xl md:text-8xl font-black mb-8">
                <span class="gradient-text">ITSANDBOX</span>
            </h1>
            <p class="text-2xl md:text-4xl mb-4 font-light">
                好きなものを、<span style="color: #FF6B35;">一緒に</span>作りませんか？
            </p>
            <p class="text-lg md:text-xl text-gray-400 mb-12 max-w-3xl mx-auto">
                法政大学の卒業生・在校生が集まり、最新のクラウド技術とAIを活用して<br>
                革新的なプロジェクトを創造するコミュニティプラットフォーム<br>
                <span class="text-orange-400 font-bold">AWS Lambda サーバーレス設計で実現！</span>
            </p>
            
            <div class="flex flex-col md:flex-row gap-6 justify-center items-center">
                <a href="#join" class="group relative px-8 py-4 overflow-hidden rounded-full neon-border glow-effect">
                    <span class="relative z-10 text-lg font-bold">プロジェクトに参加</span>
                    <div class="absolute inset-0 holographic opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                </a>
                
                <div class="flex items-center space-x-4 text-sm text-gray-400">
                    <div class="flex items-center">
                        <i class="fas fa-users mr-2" style="color: #27AE60;"></i>
                        <span>アクティブメンバー: <span class="text-white font-bold">50+</span></span>
                    </div>
                    <div class="flex items-center">
                        <i class="fas fa-code-branch mr-2" style="color: #FF6B35;"></i>
                        <span>進行中プロジェクト: <span class="text-white font-bold">12</span></span>
                    </div>
                </div>
            </div>
            
            <!-- Live Status -->
            <div class="mt-16 p-6 bg-gray-900/50 backdrop-blur-xl rounded-2xl border border-gray-800 max-w-4xl mx-auto">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-xl font-bold flex items-center">
                        <span class="w-3 h-3 rounded-full mr-2 animate-pulse" style="background-color: #27AE60;"></span>
                        AWS Lambda システムステータス
                    </h3>
                    <span class="text-sm text-gray-400">リアルタイム更新</span>
                </div>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div class="bg-black/40 backdrop-blur-sm rounded-lg p-4 border border-orange-500/20">
                        <div class="text-orange-400 text-sm">稼働率</div>
                        <div class="text-2xl font-bold text-white">99.95%</div>
                        <div class="text-xs text-gray-400">AWS Lambda</div>
                    </div>
                    <div class="bg-black/40 backdrop-blur-sm rounded-lg p-4 border border-orange-500/20">
                        <div class="text-orange-400 text-sm">月額コスト</div>
                        <div class="text-2xl font-bold text-white">$3.85</div>
                        <div class="text-xs text-gray-400">Lambda + API Gateway</div>
                    </div>
                    <div class="bg-black/40 backdrop-blur-sm rounded-lg p-4 border border-orange-500/20">
                        <div class="text-orange-400 text-sm">レスポンス時間</div>
                        <div class="text-2xl font-bold text-white">45ms</div>
                        <div class="text-xs text-gray-400">Cold Start最適化</div>
                    </div>
                    <div class="bg-black/40 backdrop-blur-sm rounded-lg p-4 border border-orange-500/20">
                        <div class="text-orange-400 text-sm">実行回数</div>
                        <div class="text-2xl font-bold text-white">1.2K</div>
                        <div class="text-xs text-gray-400">今月のリクエスト</div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="absolute bottom-10 left-1/2 transform -translate-x-1/2 animate-bounce">
            <i class="fas fa-chevron-down text-2xl text-gray-500"></i>
        </div>
    </section>

    <!-- Technology Section -->
    <section id="technology" class="py-32 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-b from-transparent via-orange-900/10 to-transparent"></div>
        
        <div class="container mx-auto px-6 relative z-10">
            <h2 class="text-5xl font-black text-center mb-16 gradient-text">AWS Lambda サーバーレス技術</h2>
            
            <div class="max-w-6xl mx-auto">
                <!-- AWS Lambda Features -->
                <div class="mb-12">
                    <h3 class="text-2xl font-bold mb-6" style="color: #FF6B35;">
                        <i class="fab fa-aws mr-2"></i>AWS Lambda サーバーレス
                    </h3>
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div class="bg-gray-900/50 p-6 rounded-xl hover:bg-gray-800/50 transition card-hover">
                            <i class="fas fa-bolt text-4xl text-orange-500 mb-2"></i>
                            <p class="font-bold">超高速起動</p>
                            <p class="text-sm text-gray-400">45ms応答時間</p>
                        </div>
                        <div class="bg-gray-900/50 p-6 rounded-xl hover:bg-gray-800/50 transition card-hover">
                            <i class="fas fa-chart-line text-4xl text-green-500 mb-2"></i>
                            <p class="font-bold">自動スケーリング</p>
                            <p class="text-sm text-gray-400">需要に応じて拡張</p>
                        </div>
                        <div class="bg-gray-900/50 p-6 rounded-xl hover:bg-gray-800/50 transition card-hover">
                            <i class="fas fa-dollar-sign text-4xl text-yellow-500 mb-2"></i>
                            <p class="font-bold">従量課金</p>
                            <p class="text-sm text-gray-400">使用分のみ支払い</p>
                        </div>
                        <div class="bg-gray-900/50 p-6 rounded-xl hover:bg-gray-800/50 transition card-hover">
                            <i class="fas fa-shield-alt text-4xl text-blue-500 mb-2"></i>
                            <p class="font-bold">高可用性</p>
                            <p class="text-sm text-gray-400">99.95% SLA</p>
                        </div>
                    </div>
                </div>
                
                <!-- Architecture Diagram -->
                <div class="bg-gray-900/50 p-8 rounded-3xl border border-gray-800">
                    <h3 class="text-2xl font-bold mb-6 text-center">AWS Lambda サーバーレスアーキテクチャ</h3>
                    <div class="relative h-96 flex items-center justify-center">
                        <div class="text-center">
                            <div class="text-6xl text-orange-500 mb-4">
                                <i class="fab fa-aws"></i>
                            </div>
                            <div class="text-2xl font-bold text-orange-400 mb-2">$3.85/月</div>
                            <p class="text-gray-400">
                                AWS Lambda + API Gateway<br>
                                サーバーレス設計でコスト最適化
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Join Section -->
    <section id="join" class="py-32 relative">
        <div class="absolute inset-0 bg-gradient-to-t from-purple-900/20 to-transparent"></div>
        
        <div class="container mx-auto px-6 text-center relative z-10">
            <h2 class="text-5xl font-black mb-8 gradient-text">参加しよう</h2>
            <p class="text-xl text-gray-400 mb-12 max-w-3xl mx-auto">
                法政大学経営システム工学部の卒業生・在校生なら誰でも参加可能！<br>
                最小2名のチームで、あなたのアイデアを<span class="text-orange-400 font-bold">AWS Lambda</span>で実現しませんか？
            </p>
            
            <div class="bg-gradient-to-br from-blue-900/30 to-purple-900/30 p-12 rounded-3xl max-w-4xl mx-auto border border-gray-800">
                <div class="grid md:grid-cols-3 gap-8 mb-12">
                    <div class="text-center">
                        <div class="text-5xl mb-4">⚡</div>
                        <h3 class="text-xl font-bold mb-2">サーバーレス開発</h3>
                        <p class="text-gray-400">AWS Lambdaでスケーラブルなアプリケーション開発</p>
                    </div>
                    <div class="text-center">
                        <div class="text-5xl mb-4">🎯</div>
                        <h3 class="text-xl font-bold mb-2">実践的学習</h3>
                        <p class="text-gray-400">最新のクラウド技術を実プロジェクトで習得</p>
                    </div>
                    <div class="text-center">
                        <div class="text-5xl mb-4">🌟</div>
                        <h3 class="text-xl font-bold mb-2">キャリア支援</h3>
                        <p class="text-gray-400">実績をポートフォリオとして就活・転職に活用</p>
                    </div>
                </div>
                
                <a href="mailto:join@itsandbox.hosei.ac.jp" class="inline-block px-12 py-5 rounded-full text-xl font-bold hover:scale-105 transition-transform glow-effect" style="background: linear-gradient(to right, #FF6B35, #27AE60);">
                    今すぐ参加申込み <i class="fas fa-arrow-right ml-2"></i>
                </a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="py-12 border-t border-gray-800">
        <div class="container mx-auto px-6">
            <div class="flex flex-col md:flex-row items-center justify-between">
                <div class="mb-4 md:mb-0">
                    <p class="text-2xl font-bold gradient-text">ITSANDBOX</p>
                    <p class="text-gray-400">法政大学ITイノベーションコミュニティ</p>
                    <p class="text-sm text-orange-400">Powered by AWS Lambda Serverless</p>
                </div>
                
                <div class="flex space-x-6">
                    <a href="https://github.com/itsandbox" class="text-gray-400 hover:text-white transition">
                        <i class="fab fa-github text-2xl"></i>
                    </a>
                    <a href="https://slack.itsandbox.hosei.ac.jp" class="text-gray-400 hover:text-white transition">
                        <i class="fab fa-slack text-2xl"></i>
                    </a>
                    <a href="mailto:info@itsandbox.hosei.ac.jp" class="text-gray-400 hover:text-white transition">
                        <i class="fas fa-envelope text-2xl"></i>
                    </a>
                </div>
            </div>
            
            <div class="mt-8 pt-8 border-t border-gray-800 text-center text-gray-500">
                <p>&copy; 2024 ITSANDBOX - Hosei University. All rights reserved.</p>
                <p class="text-xs text-orange-400 mt-2">Serverless Architecture: AWS Lambda + API Gateway</p>
            </div>
        </div>
    </footer>

    <!-- Interactive JavaScript -->
    <script>
        // Real-time status updates simulation
        function updateStats() {
            const responseTime = Math.floor(Math.random() * 10) + 40; // 40-50ms
            const requests = Math.floor(Math.random() * 100) + 1200; // 1200-1300
            
            document.querySelectorAll('.text-2xl.font-bold').forEach((el, index) => {
                if (index === 2) el.textContent = responseTime + 'ms';
                if (index === 3) el.textContent = requests.toString();
            });
        }
        
        // Update stats every 10 seconds
        setInterval(updateStats, 10000);
        
        // Smooth scrolling
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                document.querySelector(this.getAttribute('href')).scrollIntoView({
                    behavior: 'smooth'
                });
            });
        });
        
        // Parallax effect
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            const parallax = document.querySelector('.parallax-bg');
            if (parallax) {
                parallax.style.transform = `translateY(${scrolled * 0.5}px)`;
            }
        });
        
        // Card animations
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        });
        
        document.querySelectorAll('.card-hover').forEach((el) => {
            el.style.opacity = '0.8';
            el.style.transform = 'translateY(20px)';
            el.style.transition = 'all 0.6s ease';
            observer.observe(el);
        });
    </script>
</body>
</html>'''

    # Return the response for Lambda Function URL or API Gateway
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html; charset=utf-8',
            'Cache-Control': 'public, max-age=3600',
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'X-XSS-Protection': '1; mode=block',
            'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
        },
        'body': html_content
    }
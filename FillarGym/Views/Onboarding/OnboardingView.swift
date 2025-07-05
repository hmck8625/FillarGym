import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingPermissionRequest = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 背景のグラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // スキップボタン
                HStack {
                    Spacer()
                    Button("スキップ") {
                        completeOnboarding()
                    }
                    .foregroundColor(.gray)
                    .padding()
                }
                
                // ページコンテンツ
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    ValuePropositionPage()
                        .tag(1)
                    
                    HowItWorksPage()
                        .tag(2)
                    
                    DemoPage()
                        .tag(3)
                    
                    PermissionPage(showingPermissionRequest: $showingPermissionRequest)
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // ページインジケーター
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding()
                
                // アクションボタン
                Button(action: handleNextAction) {
                    Text(currentPage == 4 ? "はじめる" : "次へ")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingPermissionRequest) {
            MicrophonePermissionView {
                completeOnboarding()
            }
        }
    }
    
    private func handleNextAction() {
        if currentPage < 4 {
            withAnimation {
                currentPage += 1
            }
        } else {
            showingPermissionRequest = true
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - ページコンポーネント

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            Text("FillarGymへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("話し方を改善して、\nより説得力のある\nコミュニケーションを")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
    }
}

struct ValuePropositionPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("フィラー語を減らして\n話し方をレベルアップ")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 25) {
                OnboardingFeatureRow(
                    icon: "mic.fill",
                    title: "簡単録音",
                    description: "ワンタップで録音開始"
                )
                
                OnboardingFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI分析",
                    description: "OpenAI技術で高精度検出"
                )
                
                OnboardingFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "進捗管理",
                    description: "改善状況を可視化"
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct HowItWorksPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("使い方は簡単3ステップ")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack(spacing: 30) {
                StepView(
                    number: "1",
                    title: "録音する",
                    description: "スピーチや会話を録音",
                    color: .blue
                )
                
                StepView(
                    number: "2",
                    title: "分析を待つ",
                    description: "AIが自動でフィラー語を検出",
                    color: .purple
                )
                
                StepView(
                    number: "3",
                    title: "改善する",
                    description: "結果を確認して練習",
                    color: .green
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct DemoPage: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("実際の分析結果")
                .font(.title)
                .fontWeight(.bold)
            
            // デモ結果カード
            VStack(spacing: 20) {
                // フィラー数表示
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: isAnimating ? 0.7 : 0)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5), value: isAnimating)
                    
                    VStack {
                        Text("12")
                            .font(.system(size: 48, weight: .bold))
                        Text("フィラー語")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // フィラー語例
                HStack(spacing: 15) {
                    ForEach(["えー", "あの", "その"], id: \.self) { word in
                        Text(word)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(15)
                    }
                }
                
                Text("前回より15%改善！")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}

struct PermissionPage: View {
    @Binding var showingPermissionRequest: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("マイクへのアクセス")
                .font(.title)
                .fontWeight(.bold)
            
            Text("音声を録音・分析するために\nマイクへのアクセスが必要です")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 15) {
                PermissionPoint(
                    icon: "lock.shield.fill",
                    text: "録音データは端末内で処理"
                )
                
                PermissionPoint(
                    icon: "hand.raised.fill",
                    text: "プライバシーを保護"
                )
                
                PermissionPoint(
                    icon: "checkmark.shield.fill",
                    text: "いつでも設定から変更可能"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - サポートビュー

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct StepView: View {
    let number: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(number)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct PermissionPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct MicrophonePermissionView: View {
    let onComplete: () -> Void
    @State private var permissionGranted = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if permissionGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("準備完了！")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("マイクへのアクセスが\n許可されました")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("マイクアクセスを\n確認中...")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if permissionGranted {
                Button("FillarGymを始める") {
                    onComplete()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .onAppear {
            requestMicrophonePermission()
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                withAnimation {
                    self.permissionGranted = granted
                }
                
                if !granted {
                    // 権限が拒否された場合の処理
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        onComplete()
                        dismiss()
                    }
                }
            }
        }
    }
}
// File: ContentView.swift
// 主界面：VR 全景视图 + 底部提示文字

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // VR 全景容器（纯虚拟空间）
            VRViewContainer()
                .ignoresSafeArea(.all)

            // 上层 UI
            VStack {
                Spacer()
                Text("🔍 转动手机寻找白色小毛球")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ContentView()
}

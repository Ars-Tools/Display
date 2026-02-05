//
//  App.swift
//  Display
//
//  Created by Kota on 2/5/26.
//
@preconcurrency import SwiftUI
@preconcurrency import AVFoundation
@main
struct App: SwiftUI.App {
    @usableFromInline
    let session: AVAudioSession = .sharedInstance()
    @inlinable
    var body: some Scene {
        WindowGroup {
            View()
                .onAppear {
                    do {
                        try session.setCategory(.playAndRecord, mode: .videoRecording)
                    } catch {
                        
                    }
                }
        }
    }
}
struct View: SwiftUI.View {
    @usableFromInline
    let videos: AVCaptureDevice.DiscoverySession = .init(deviceTypes: [.external, .builtInWideAngleCamera], mediaType: .some(.video), position: .unspecified)
    @usableFromInline
    let audios: AVCaptureDevice.DiscoverySession = .init(deviceTypes: [.external, .microphone], mediaType: .some(.audio), position: .unspecified)
    @usableFromInline
    @AppStorage("video") var videoStore: String = ""
    @inlinable
    var videoInput: Optional<AVCaptureDevice> {
        get {
            videos.devices.first {
                $0.uniqueID == videoStore
            }
        }
        nonmutating set {
            videoStore = newValue.map(\.uniqueID) ?? ""
        }
    }
    @inlinable
    var audioInput: Optional<AVCaptureDevice> {
        videoInput.map(\.localizedName).flatMap { localizedName in
            audios.devices.first { $0.localizedName == localizedName }
        }
    }
    @inlinable
    var body: some SwiftUI.View {
        switch videoInput {
        case.some(let video):
            ViewRepresentable(video: video, audio: audioInput).onTapGesture {
                videoInput = .none
            }
        case.none:
            Selector(discovery: videos, video: $videoStore)
        }
    }
}
@usableFromInline
struct Selector: SwiftUI.View {
    @usableFromInline
    let discovery: AVCaptureDevice.DiscoverySession
    @usableFromInline
    @Binding var video: String
    @usableFromInline
    @State var state: AVAuthorizationStatus = .notDetermined
    @usableFromInline
    @Environment(\.dismiss) var dismiss
    @inlinable
    @State var animation: Bool = false
    @inlinable
    var body: some SwiftUI.View {
        GlassEffectContainer(spacing: 40.0) {
            ZStack {
                // Layer 0: Background Color
                Color.black.ignoresSafeArea()
                
                // Layer 1: Ambient Animation
                GeometryReader {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 300, height: 300)
                            .blur(radius: 60)
                            .offset(x: animation ? -100 : 100, y: animation ? -150 : 150)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.4), .mint.opacity(0.3)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: animation ? 150 : -50, y: animation ? 200 : -100)
                    }
                    .frame(width: $0.size.width, height: $0.size.height)
                }
                
                // Layer 2: UI Content
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    Text("Display")
                        .font(.system(size: 64, weight: .black, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: animation ? .top : .leading,
                                endPoint: animation ? .bottom : .trailing
                            )
                        )
                        .glassEffect(.identity)
                        .blur(radius: animation ? 4 : 0)
                    
                    Spacer()
                    
                    switch state {
                    case .notDetermined:
                        Text("Not Determined")
                            .foregroundStyle(.white.opacity(0.8))
                            .onAppear {
                                Task {
                                    state = await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
                                }
                            }
                    case .restricted:
                        Text("Restricted").foregroundStyle(.red)
                    case .denied:
                        Text("Denied").foregroundStyle(.red)
                    case .authorized:
                        switch discovery.devices {
                        case .init():
                            Button("No Video Device Found", action: dismiss.callAsFunction)
                                .buttonStyle(.glass)
                        case let devices:
                            GlassEffectContainer {
                                VStack(spacing: 16) {
                                    ForEach(devices, id: \.uniqueID) { device in
                                        Button(device.localizedName) {
                                            video = device.uniqueID
                                            dismiss.callAsFunction()
                                        }
                                        .buttonStyle(.glass)
                                        .frame(maxWidth: .some(.infinity))
                                    }
                                }
                            }
                            .frame(width: .some(880))
                        }
                    @unknown default:
                        preconditionFailure()
                    }
                    Spacer()
                    
                    // Layer 4
                    Text("© 2026 Ars Tools. All rights reserved.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                animation.toggle()
            }
        }
    }
}
final class Audio {
    
}
@usableFromInline
struct ViewRepresentable: UIViewRepresentable {
    @usableFromInline
    let video: AVCaptureDevice
    @usableFromInline
    let audio: Optional<AVCaptureDevice>
    @usableFromInline
    struct Coordinator {
        @usableFromInline
        let session: AVCaptureSession
    }
    @usableFromInline
    final class UIViewType: UIView {
        @inlinable
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
    }
    @usableFromInline
    func makeCoordinator() -> Coordinator {
        try!.init(video: .init(device: video), audio: audio.map(AVCaptureDeviceInput.init(device:)))
    }
    @inlinable
    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType()
        switch view.layer {
        case let layer as AVCaptureVideoPreviewLayer:
            layer.session = context.coordinator.session
            layer.videoGravity = .resizeAspect
        default:
            break
        }
        return view
    }
    @inlinable
    func updateUIView(_ uiView: UIViewType, context: Context) {
        switch (uiView.isHidden, context.coordinator.session.isRunning) {
        case((false, false)):
            context.coordinator.session.startRunning()
        case((true, true)):
            context.coordinator.session.stopRunning()
        case((false, true)), ((true, false)):
            break
        }
    }
}
extension ViewRepresentable.Coordinator {
    @inlinable
    init(video: AVCaptureDeviceInput, audio: Optional<AVCaptureDeviceInput>) throws {
        session = .init()
        session.beginConfiguration()
        session.sessionPreset = .high
        session.addInput(video)
        if case.some(let audio) = audio {
            session.addInput(audio)
        }
        session.commitConfiguration()
    }
}

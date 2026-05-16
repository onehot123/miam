// File: VRViewContainer.swift
// 纯 VR 360° 全景空间 | RealityKit .nonAR + CoreMotion
// 不需要相机权限

import SwiftUI
import RealityKit
import CoreMotion
import simd

struct VRViewContainer: UIViewRepresentable {

    let arView = ARView(frame: .zero)
    let motionManager = CMMotionManager()
    private var cameraPivot: Entity?

    // MARK: - 生命周期

    func makeUIView(context: Context) -> ARView {
        arView.cameraMode = .nonAR
        arView.environment.blending = .opaque
        let bg = ExperienceBackgroundResources()
        bg.color.tint = Color(red: 12 / 255, green: 12 / 255, blue: 30 / 255)
        bg.intensity = 0.5
        arView.environment.background = .experience(bg)
        let ambient = LightingEntity()
        ambient.type = .ambient(color: .white, intensity: 100)
        arView.scene.addEntity(ambient)
        let dir = LightingEntity()
        dir.type = .directional(color: .white, intensity: 200, direction: SIMD3<Float>(0, -1, -0.5))
        arView.scene.addEntity(dir)
        let pivot = Entity()
        arView.scene.addEntity(pivot)
        cameraPivot = pivot
        buildRoom()
        addFurBall()
        startMotion()
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
    func teardownUIView(_ uiView: ARView) {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - 房间

    private func buildRoom() {
        let half: Float = 10
        let step: Float = 2
        let n = Int((half * 2) / step)
        let fm = umat(r: 0.25, g: 0.25, b: 0.6, a: 0.8)
        let wm = umat(r: 0.15, g: 0.15, b: 0.4, a: 0.5)
        let cm = umat(r: 0.1,  g: 0.1,  b: 0.3, a: 0.35)

        func fl(p: Float) {
            ml(a: SIMD3<Float>(p, -half, -half), b: SIMD3<Float>(p, -half, half), m: fm)
            ml(a: SIMD3<Float>(-half, -half, p), b: SIMD3<Float>(half, -half, p), m: fm)
        }
        func cl(p: Float) {
            ml(a: SIMD3<Float>(p, half, -half), b: SIMD3<Float>(p, half, half), m: cm)
            ml(a: SIMD3<Float>(-half, half, p), b: SIMD3<Float>(half, half, p), m: cm)
        }
        func fw(p: Float) {
            ml(a: SIMD3<Float>(p, -half, -half), b: SIMD3<Float>(p, half, -half), m: wm)
            ml(a: SIMD3<Float>(-half, p, -half), b: SIMD3<Float>(half, p, -half), m: wm)
        }
        func bw(p: Float) {
            ml(a: SIMD3<Float>(p, -half, half), b: SIMD3<Float>(p, half, half), m: wm)
            ml(a: SIMD3<Float>(-half, p, half), b: SIMD3<Float>(half, p, half), m: wm)
        }
        func lw(p: Float) {
            ml(a: SIMD3<Float>(-half, -half, p), b: SIMD3<Float>(-half, half, p), m: wm)
            ml(a: SIMD3<Float>(-half, p, -half), b: SIMD3<Float>(-half, p, half), m: wm)
        }
        func rw(p: Float) {
            ml(a: SIMD3<Float>(half, -half, p), b: SIMD3<Float>(half, half, p), m: wm)
            ml(a: SIMD3<Float>(half, p, -half), b: SIMD3<Float>(half, p, half), m: wm)
        }

        for i in 0...n {
            let p = -half + Float(i) * step
            fl(p: p); cl(p: p); fw(p: p); bw(p: p); lw(p: p); rw(p: p)
        }

        let ring = ModelEntity(
            mesh: .generateTorus(ringRadius: 0.4, tubeRadius: 0.025),
            materials: [SimpleMaterial(color: .white, roughness: 0.3, isMetallic: false)]
        )
        ring.position = SIMD3<Float>(0, -half + 0.02, 0)
        ring.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        arView.scene.addEntity(ring)
    }

    // MARK: - 线

    private func ml(a: SIMD3<Float>, b: SIMD3<Float>, m: UnlitMaterial) {
        let d = b - a
        let len = simd_length(d)
        guard len > 0 else { return }
        let axis = d / len
        let mid = (a + b) / 2
        let box = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.02, len, 0.02)),
            materials: [m]
        )
        box.position = mid
        let up = SIMD3<Float>(0, 1, 0)
        let dot = simd_dot(up, axis)
        if abs(dot) < 0.9999 {
            let c = simd_cross(up, axis)
            let cl = simd_length(c)
            box.orientation = simd_quatf(vector: SIMD4<Float>(c.x / cl, c.y / cl, c.z / cl, dot + 1))
        }
        arView.scene.addEntity(box)
    }

    private func umat(r: Float, g: Float, b: Float, a: Float) -> UnlitMaterial {
        UnlitMaterial(color: MaterialColorParams(color: SIMD4<Float>(r, g, b, a)), isOpaque: false)
    }

    // MARK: - 小毛球

    private func addFurBall() {
        let r: Float = 0.15
        let ball = ModelEntity(
            mesh: .generateSphere(radius: r, segments: 24),
            materials: [SimpleMaterial(color: .white, roughness: 0.9, isMetallic: false)]
        )
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            let theta = Float.random(in: 0 ..< 2 * .pi, using: &rng)
            let phi = Float.random(in: 0 ..< .pi, using: &rng)
            let dist = r * (1.0 + Float.random(in: 0.15 ..< 0.5, using: &rng))
            let spike = ModelEntity(
                mesh: .generateSphere(radius: r * 0.12, segments: 6),
                materials: [SimpleMaterial(color: .white, roughness: 0.95, isMetallic: false)]
            )
            spike.position = SIMD3<Float>(
                dist * sin(phi) * cos(theta),
                dist * cos(phi),
                dist * sin(phi) * sin(theta)
            )
            ball.addChild(spike)
        }
        let er: Float = 0.018
        let e1 = ModelEntity(mesh: .generateSphere(radius: er, segments: 8), materials: [SimpleMaterial(color: .black, isMetallic: false)])
        e1.position = SIMD3<Float>(-0.04, 0.03, -r * 0.88)
        ball.addChild(e1)
        let e2 = ModelEntity(mesh: .generateSphere(radius: er, segments: 8), materials: [SimpleMaterial(color: .black, isMetallic: false)])
        e2.position = SIMD3<Float>(0.04, 0.03, -r * 0.88)
        ball.addChild(e2)
        let pl = LightingEntity()
        pl.type = .point(color: .white, intensity: 20, distance: 1.5)
        ball.addChild(pl)
        var rng2 = SystemRandomNumberGenerator()
        let bx = Float.random(in: -5 ..< 5, using: &rng2)
        let by = Float.random(in: -3 ..< 4, using: &rng2)
        let bz = Float.random(in: -5 ..< 0, using: &rng2)
        ball.position = SIMD3<Float>(bx, by, bz)
        let baseY = by
        let t0 = Date().timeIntervalSinceReferenceDate
        let timer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { timer in
            ball.position = SIMD3<Float>(bx, baseY + sin((Date().timeIntervalSinceReferenceDate - t0) * 2) * 0.15, bz)
        }
        RunLoop.main.add(timer, forMode: .common)
        let rot = AnimationResource.makeRotation(around: SIMD3<Float>(0, 1, 0), by: Float.pi * 2, duration: 10)
        ball.playAnimation(rot, transition: .immediate(duration: 0.5), repeat: .infinite)
        arView.scene.addEntity(ball)
    }

    // MARK: - 陀螺仪

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, error in
            guard let s = self, let att = motion?.attitude else { return }
            let qp = simd_quatf(angle: -att.pitch, axis: SIMD3<Float>(1, 0, 0))
            let qy = simd_quatf(angle: -att.yaw, axis: SIMD3<Float>(0, 1, 0))
            let qr = simd_quatf(angle: -att.roll, axis: SIMD3<Float>(0, 0, 1))
            let q0 = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 0, 1))
            s.cameraPivot?.orientation = q0 * qy * qp * qr
        }
    }
}

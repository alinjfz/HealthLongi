import SceneKit
import SwiftUI

struct HumanBodySceneView: UIViewRepresentable {
    let regionColors: [BodyRegion: Color]
    var onRegionTapped: (BodyRegion) -> Void

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.scene
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        context.coordinator.scnView = view
        context.coordinator.onRegionTapped = onRegionTapped
        context.coordinator.applyColors(regionColors)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onRegionTapped = onRegionTapped
        context.coordinator.applyColors(regionColors)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        let scene = SCNScene()
        var scnView: SCNView?
        var onRegionTapped: ((BodyRegion) -> Void)?
        private var regionNodes: [BodyRegion: SCNNode] = [:]

        override init() {
            super.init()
            buildScene()
        }

        func applyColors(_ colors: [BodyRegion: Color]) {
            for (region, node) in regionNodes {
                let uiColor = UIColor(colors[region] ?? .gray)
                node.geometry?.firstMaterial?.diffuse.contents = uiColor.withAlphaComponent(0.85)
                node.geometry?.firstMaterial?.emission.contents = uiColor.withAlphaComponent(0.35)
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = scnView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.closest.rawValue])
            for hit in hits {
                if let region = regionForNode(hit.node) {
                    onRegionTapped?(region)
                    return
                }
            }
        }

        private func regionForNode(_ node: SCNNode) -> BodyRegion? {
            var current: SCNNode? = node
            while let candidate = current {
                if let name = candidate.name, let region = BodyRegion(rawValue: name) {
                    return region
                }
                current = candidate.parent
            }
            return nil
        }

        private func buildScene() {
            let root = scene.rootNode

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.position = SCNVector3(0, 1.2, 3.8)
            camera.look(at: SCNVector3(0, 0.9, 0))
            root.addChildNode(camera)

            let keyLight = SCNNode()
            keyLight.light = SCNLight()
            keyLight.light?.type = .omni
            keyLight.position = SCNVector3(2, 3, 4)
            root.addChildNode(keyLight)

            let rim = SCNNode()
            rim.light = SCNLight()
            rim.light?.type = .ambient
            rim.light?.intensity = 250
            root.addChildNode(rim)

            let torso = capsuleNode(name: "torso", radius: 0.28, height: 0.9, position: SCNVector3(0, 1.0, 0))
            torso.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.35)
            root.addChildNode(torso)

            addRegion(.brain, sphere(radius: 0.18), position: SCNVector3(0, 1.75, 0))
            addRegion(.heart, sphere(radius: 0.12), position: SCNVector3(0.05, 1.25, 0.12))
            addRegion(.lungs, box(width: 0.34, height: 0.22, length: 0.16), position: SCNVector3(0, 1.32, 0.02))
            addRegion(.abdomen, sphere(radius: 0.16), position: SCNVector3(0, 0.88, 0.1))
            addRegion(.leftShoulder, sphere(radius: 0.1), position: SCNVector3(-0.36, 1.42, 0))
            addRegion(.rightHip, sphere(radius: 0.1), position: SCNVector3(0.22, 0.62, 0.02))
            addRegion(.leftKnee, sphere(radius: 0.09), position: SCNVector3(-0.12, 0.28, 0.05))

            let leftLeg = capsuleNode(name: nil, radius: 0.1, height: 0.7, position: SCNVector3(-0.12, 0.45, 0))
            let rightLeg = capsuleNode(name: nil, radius: 0.1, height: 0.7, position: SCNVector3(0.12, 0.45, 0))
            leftLeg.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.3)
            rightLeg.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.3)
            root.addChildNode(leftLeg)
            root.addChildNode(rightLeg)
        }

        private func addRegion(_ region: BodyRegion, _ geometry: SCNGeometry, position: SCNVector3) {
            let node = SCNNode(geometry: geometry)
            node.name = region.rawValue
            node.position = position
            geometry.firstMaterial?.lightingModel = .physicallyBased
            regionNodes[region] = node
            scene.rootNode.addChildNode(node)
        }

        private func sphere(radius: CGFloat) -> SCNSphere {
            let geometry = SCNSphere(radius: radius)
            geometry.segmentCount = 24
            return geometry
        }

        private func box(width: CGFloat, height: CGFloat, length: CGFloat) -> SCNBox {
            SCNBox(width: width, height: height, length: length, chamferRadius: 0.03)
        }

        private func capsuleNode(name: String?, radius: CGFloat, height: CGFloat, position: SCNVector3) -> SCNNode {
            let geometry = SCNCapsule(capRadius: radius, height: height)
            let node = SCNNode(geometry: geometry)
            node.name = name
            node.position = position
            return node
        }
    }
}

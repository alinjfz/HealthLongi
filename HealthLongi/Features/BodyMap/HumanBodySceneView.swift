import SceneKit
import SwiftUI

/// Renders a realistic anatomy asset when `HumanAnatomy.usdz` or
/// `HumanAnatomy.scn` is bundled with the app. If no asset exists yet, the view
/// falls back to a procedural anatomical placeholder.
///
/// For a real model, name organ/joint nodes with these identifiers somewhere in
/// the node name: brain, heart, lung, abdomen/stomach, shoulder, hip, knee.
/// Those meshes are colorized from `regionColors`.
struct HumanBodySceneView: UIViewRepresentable {
    let regionColors: [BodyRegion: Color]
    var onRegionTapped: (BodyRegion) -> Void

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.scene
        view.backgroundColor = .clear
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true

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

        /// A region can be backed by more than one node (e.g. two lung lobes).
        private var regionNodes: [BodyRegion: [SCNNode]] = [:]

        override init() {
            super.init()
            buildScene()
        }

        // MARK: - Color updates

        func applyColors(_ colors: [BodyRegion: Color]) {
            for (region, nodes) in regionNodes {
                let uiColor = UIColor(colors[region] ?? .gray)
                for node in nodes {
                    guard let material = node.geometry?.firstMaterial else { continue }
                    material.diffuse.contents = uiColor
                    material.emission.contents = uiColor.withAlphaComponent(0.55)
                }
            }
        }

        // MARK: - Hit testing

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = scnView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
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

        // MARK: - Scene construction

        private func buildScene() {
            let root = scene.rootNode

            // Subtle dark vignette background so the colored organs glow.
            scene.background.contents = UIColor(red: 0.03, green: 0.05, blue: 0.09, alpha: 1)

            // Camera, framed on the upper body where most organs sit.
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.fieldOfView = 45
            camera.camera?.wantsHDR = true
            camera.position = SCNVector3(0, 0.95, 4.4)
            camera.look(at: SCNVector3(0, 0.85, 0))
            root.addChildNode(camera)

            addLighting(to: root)

            // A container we slowly rotate for a "showcase" feel. Camera control
            // by the user still works on top of this idle animation.
            let body = SCNNode()
            body.name = "bodyContainer"
            root.addChildNode(body)
            addIdleRotation(to: body)

            if !loadBundledAnatomyAsset(into: body) {
                buildSkeletonOfSkin(on: body)
                buildOrgans(on: body)
            }
        }

        /// Loads a real anatomy mesh if the project contains one. This is the
        /// only way to get a truly realistic human anatomy model; SceneKit code
        /// can color and animate a mesh, but it cannot synthesize medical-grade
        /// anatomy detail on its own.
        private func loadBundledAnatomyAsset(into body: SCNNode) -> Bool {
            guard let assetURL = anatomyAssetURL(),
                  let assetScene = try? SCNScene(url: assetURL, options: nil)
            else {
                return false
            }

            let assetRoot = SCNNode()
            for child in assetScene.rootNode.childNodes {
                assetRoot.addChildNode(child.clone())
            }

            body.addChildNode(assetRoot)
            normalize(assetRoot, targetHeight: 2.0)
            registerAssetRegionNodes(in: assetRoot)

            // A model without named organ nodes would look realistic, but could
            // not show health status by body part.
            if regionNodes.isEmpty {
                assetRoot.removeFromParentNode()
                return false
            }

            return true
        }

        private func anatomyAssetURL() -> URL? {
            if let url = Bundle.main.url(forResource: "HumanAnatomy", withExtension: "usdz") {
                return url
            }
            return Bundle.main.url(forResource: "HumanAnatomy", withExtension: "scn")
        }

        private func normalize(_ node: SCNNode, targetHeight: Float) {
            guard let bounds = worldBounds(for: node) else { return }

            let height = bounds.max.y - bounds.min.y
            guard height > 0 else { return }

            let scale = targetHeight / height
            let center = SCNVector3(
                (bounds.min.x + bounds.max.x) / 2,
                (bounds.min.y + bounds.max.y) / 2,
                (bounds.min.z + bounds.max.z) / 2
            )

            node.scale = SCNVector3(scale, scale, scale)
            node.position = SCNVector3(-center.x * scale, 0.75 - center.y * scale, -center.z * scale)
        }

        private func worldBounds(for root: SCNNode) -> (min: SCNVector3, max: SCNVector3)? {
            var result: (min: SCNVector3, max: SCNVector3)?

            root.enumerateChildNodes { node, _ in
                guard node.geometry != nil else { return }

                let bounds = node.boundingBox
                let corners = [
                    SCNVector3(bounds.min.x, bounds.min.y, bounds.min.z),
                    SCNVector3(bounds.min.x, bounds.min.y, bounds.max.z),
                    SCNVector3(bounds.min.x, bounds.max.y, bounds.min.z),
                    SCNVector3(bounds.min.x, bounds.max.y, bounds.max.z),
                    SCNVector3(bounds.max.x, bounds.min.y, bounds.min.z),
                    SCNVector3(bounds.max.x, bounds.min.y, bounds.max.z),
                    SCNVector3(bounds.max.x, bounds.max.y, bounds.min.z),
                    SCNVector3(bounds.max.x, bounds.max.y, bounds.max.z)
                ]

                for corner in corners {
                    let point = node.convertPosition(corner, to: root)
                    if let current = result {
                        result = (
                            min: SCNVector3(
                                Swift.min(current.min.x, point.x),
                                Swift.min(current.min.y, point.y),
                                Swift.min(current.min.z, point.z)
                            ),
                            max: SCNVector3(
                                Swift.max(current.max.x, point.x),
                                Swift.max(current.max.y, point.y),
                                Swift.max(current.max.z, point.z)
                            )
                        )
                    } else {
                        result = (point, point)
                    }
                }
            }

            return result
        }

        private func registerAssetRegionNodes(in root: SCNNode) {
            root.enumerateChildNodes { node, _ in
                guard node.geometry != nil, let region = regionForAssetNode(node) else { return }

                node.name = region.rawValue
                configureAssetMaterial(for: node)
                regionNodes[region, default: []].append(node)

                if region == .heart {
                    addPulse(to: node)
                }
            }
        }

        private func regionForAssetNode(_ node: SCNNode) -> BodyRegion? {
            let name = (node.name ?? "").lowercased()

            if name.contains("brain") || name.contains("cerebr") { return .brain }
            if name.contains("heart") || name.contains("cardiac") { return .heart }
            if name.contains("lung") || name.contains("pulmonary") { return .lungs }
            if name.contains("abdomen") || name.contains("stomach") || name.contains("liver") || name.contains("intestin") { return .abdomen }
            if name.contains("shoulder") || name.contains("deltoid") { return .leftShoulder }
            if name.contains("hip") || name.contains("pelvis") { return .rightHip }
            if name.contains("knee") || name.contains("patella") { return .leftKnee }

            return nil
        }

        private func configureAssetMaterial(for node: SCNNode) {
            guard let geometry = node.geometry else { return }
            if geometry.materials.isEmpty {
                geometry.firstMaterial = SCNMaterial()
            }

            for material in geometry.materials {
                material.lightingModel = .physicallyBased
                material.emission.contents = UIColor.gray.withAlphaComponent(0.55)
                material.metalness.contents = 0.0
                material.roughness.contents = 0.42
            }
        }

        private func addLighting(to root: SCNNode) {
            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.intensity = 750
            key.light?.color = UIColor(white: 1.0, alpha: 1)
            key.position = SCNVector3(3, 4, 5)
            key.look(at: SCNVector3(0, 0.8, 0))
            root.addChildNode(key)

            let fill = SCNNode()
            fill.light = SCNLight()
            fill.light?.type = .directional
            fill.light?.intensity = 350
            fill.light?.color = UIColor(red: 0.6, green: 0.75, blue: 1.0, alpha: 1)
            fill.position = SCNVector3(-4, 2, 3)
            fill.look(at: SCNVector3(0, 0.8, 0))
            root.addChildNode(fill)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 220
            ambient.light?.color = UIColor(white: 0.5, alpha: 1)
            root.addChildNode(ambient)
        }

        private func addIdleRotation(to node: SCNNode) {
            let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 28)
            node.runAction(SCNAction.repeatForever(rotate))
        }

        // MARK: Skin silhouette (translucent, non-interactive)

        /// Builds the recognizable human outline. Everything here uses the
        /// translucent "skin" material so the colored organs read through it.
        private func buildSkeletonOfSkin(on body: SCNNode) {
            // Head + neck
            body.addChildNode(skin(sphere(0.135), at: SCNVector3(0, 1.66, 0), scale: SCNVector3(0.92, 1.08, 1.0)))
            body.addChildNode(skin(capsule(radius: 0.06, height: 0.16), at: SCNVector3(0, 1.5, 0)))

            // Torso: tapered chest + narrower abdomen, flattened front-to-back.
            body.addChildNode(skin(capsule(radius: 0.215, height: 0.5), at: SCNVector3(0, 1.18, 0), scale: SCNVector3(1.18, 1.0, 0.62)))
            body.addChildNode(skin(capsule(radius: 0.17, height: 0.34), at: SCNVector3(0, 0.86, 0), scale: SCNVector3(1.0, 1.0, 0.6)))

            // Pelvis
            body.addChildNode(skin(capsule(radius: 0.18, height: 0.24), at: SCNVector3(0, 0.62, 0), scale: SCNVector3(1.12, 1.0, 0.62)))

            // Shoulders (deltoid caps)
            body.addChildNode(skin(sphere(0.105), at: SCNVector3(-0.3, 1.36, 0)))
            body.addChildNode(skin(sphere(0.105), at: SCNVector3(0.3, 1.36, 0)))

            // Arms: upper arm + forearm + hand, angled slightly outward.
            addArm(on: body, side: -1)
            addArm(on: body, side: 1)

            // Legs: thigh + calf + foot.
            addLeg(on: body, side: -1)
            addLeg(on: body, side: 1)
        }

        private func addArm(on body: SCNNode, side: Float) {
            let x = 0.3 * side
            let upper = skin(capsule(radius: 0.062, height: 0.36), at: SCNVector3(x + 0.02 * side, 1.16, 0))
            upper.eulerAngles = SCNVector3(0, 0, -0.18 * side)
            body.addChildNode(upper)

            let fore = skin(capsule(radius: 0.052, height: 0.34), at: SCNVector3(x + 0.08 * side, 0.82, 0.02))
            fore.eulerAngles = SCNVector3(0, 0, -0.12 * side)
            body.addChildNode(fore)

            body.addChildNode(skin(sphere(0.055), at: SCNVector3(x + 0.12 * side, 0.62, 0.03)))
        }

        private func addLeg(on body: SCNNode, side: Float) {
            let x = 0.1 * side
            body.addChildNode(skin(capsule(radius: 0.085, height: 0.42), at: SCNVector3(x, 0.36, 0), scale: SCNVector3(1.0, 1.0, 0.85)))
            body.addChildNode(skin(capsule(radius: 0.07, height: 0.4), at: SCNVector3(x, 0.04, 0), scale: SCNVector3(1.0, 1.0, 0.85)))
            // Foot
            let foot = skin(capsule(radius: 0.05, height: 0.16), at: SCNVector3(x, -0.17, 0.06))
            foot.eulerAngles = SCNVector3(Float.pi / 2.2, 0, 0)
            body.addChildNode(foot)
        }

        // MARK: Organs / joints (colorized by health status)

        private func buildOrgans(on body: SCNNode) {
            // Brain — inside the head.
            addRegion(.brain, [organNode(sphere(0.1), at: SCNVector3(0, 1.69, 0.01), scale: SCNVector3(1.0, 0.9, 1.05))], on: body)

            // Lungs — two lobes flanking the heart.
            let leftLung = organNode(sphere(0.1), at: SCNVector3(-0.1, 1.26, 0.02), scale: SCNVector3(0.85, 1.5, 0.7))
            let rightLung = organNode(sphere(0.1), at: SCNVector3(0.1, 1.26, 0.02), scale: SCNVector3(0.85, 1.5, 0.7))
            addRegion(.lungs, [leftLung, rightLung], on: body)

            // Heart — slightly left of center, with a gentle pulse.
            let heart = organNode(sphere(0.075), at: SCNVector3(-0.045, 1.24, 0.07), scale: SCNVector3(1.0, 1.15, 1.0))
            addPulse(to: heart)
            addRegion(.heart, [heart], on: body)

            // Abdomen / stomach.
            addRegion(.abdomen, [organNode(sphere(0.11), at: SCNVector3(0.02, 0.9, 0.05), scale: SCNVector3(1.1, 0.95, 0.8))], on: body)

            // Joints.
            addRegion(.leftShoulder, [organNode(sphere(0.075), at: SCNVector3(-0.3, 1.36, 0.02))], on: body)
            addRegion(.rightHip, [organNode(sphere(0.075), at: SCNVector3(0.1, 0.58, 0.03))], on: body)
            addRegion(.leftKnee, [organNode(sphere(0.06), at: SCNVector3(-0.1, 0.16, 0.04))], on: body)
        }

        private func addRegion(_ region: BodyRegion, _ nodes: [SCNNode], on parent: SCNNode) {
            for node in nodes {
                node.name = region.rawValue
                parent.addChildNode(node)
            }
            regionNodes[region] = nodes
        }

        private func addPulse(to node: SCNNode) {
            let up = SCNAction.scale(by: 1.12, duration: 0.45)
            up.timingMode = .easeInEaseOut
            let down = SCNAction.scale(by: 1 / 1.12, duration: 0.55)
            down.timingMode = .easeInEaseOut
            node.runAction(SCNAction.repeatForever(SCNAction.sequence([up, down])))
        }

        // MARK: - Materials & primitives

        /// Translucent skin part that is part of the silhouette but not tappable.
        private func skin(_ geometry: SCNGeometry, at position: SCNVector3, scale: SCNVector3 = SCNVector3(1, 1, 1)) -> SCNNode {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor(red: 0.83, green: 0.86, blue: 0.93, alpha: 1)
            material.metalness.contents = 0.0
            material.roughness.contents = 0.35
            material.transparency = 0.16
            material.blendMode = .alpha
            material.writesToDepthBuffer = false
            material.isDoubleSided = true
            geometry.firstMaterial = material

            let node = SCNNode(geometry: geometry)
            node.position = position
            node.scale = scale
            node.renderingOrder = 10 // draw after organs so they show through
            node.castsShadow = false
            return node
        }

        /// Solid, emissive organ/joint node that is colorized by health status.
        private func organNode(_ geometry: SCNGeometry, at position: SCNVector3, scale: SCNVector3 = SCNVector3(1, 1, 1)) -> SCNNode {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor.gray
            material.emission.contents = UIColor.gray.withAlphaComponent(0.55)
            material.metalness.contents = 0.0
            material.roughness.contents = 0.5
            geometry.firstMaterial = material

            let node = SCNNode(geometry: geometry)
            node.position = position
            node.scale = scale
            return node
        }

        private func sphere(_ radius: CGFloat) -> SCNSphere {
            let geometry = SCNSphere(radius: radius)
            geometry.segmentCount = 48
            return geometry
        }

        private func capsule(radius: CGFloat, height: CGFloat) -> SCNCapsule {
            let geometry = SCNCapsule(capRadius: radius, height: height)
            geometry.radialSegmentCount = 36
            return geometry
        }
    }
}

import XCTest
@testable import SafeScreenCore

final class MatrixAnimationModelTests: XCTestCase {
    func testDefaultConfigurationMatchesProductPlan() {
        let configuration = SafeScreenConfiguration()

        XCTAssertEqual(configuration.idleThreshold, 20)
        XCTAssertEqual(configuration.layoutChangeInterval, 20)
        XCTAssertEqual(configuration.streamCount, 5)
        XCTAssertGreaterThan(configuration.transitionDuration, 0)
    }

    func testGeneratedStreamsStayInsideCanvasBounds() {
        let model = MatrixAnimationModel(seed: 42)
        let size = MatrixCanvasSize(width: 1440, height: 900)

        let layout = model.layout(for: 0, in: size)

        XCTAssertEqual(layout.streams.count, 5)
        for stream in layout.streams {
            XCTAssertGreaterThanOrEqual(stream.x, 0)
            XCTAssertLessThanOrEqual(stream.x + stream.glyphSize, size.width)
            XCTAssertGreaterThan(stream.speed, 0)
            XCTAssertGreaterThan(stream.glyphCount, 0)
        }
    }

    func testLayoutChangesAfterConfiguredInterval() {
        let model = MatrixAnimationModel(seed: 42)
        let size = MatrixCanvasSize(width: 1440, height: 900)

        let firstLayout = model.renderLayers(elapsedTime: 19.9, canvasSize: size).last?.layout
        let secondLayout = model.renderLayers(elapsedTime: 20.1, canvasSize: size).last?.layout

        XCTAssertNotEqual(firstLayout?.generation, secondLayout?.generation)
        XCTAssertNotEqual(firstLayout?.streams.map(\.x), secondLayout?.streams.map(\.x))
    }

    func testTransitionBlendsOutgoingAndIncomingLayouts() {
        let model = MatrixAnimationModel(seed: 42)
        let size = MatrixCanvasSize(width: 1440, height: 900)

        let layers = model.renderLayers(elapsedTime: 22, canvasSize: size)

        XCTAssertEqual(layers.count, 2)
        XCTAssertEqual(layers[0].layout.generation, 0)
        XCTAssertEqual(layers[1].layout.generation, 1)
        XCTAssertGreaterThan(layers[0].opacity, 0)
        XCTAssertGreaterThan(layers[1].opacity, 0)
        XCTAssertEqual(layers[0].opacity + layers[1].opacity, 1, accuracy: 0.0001)
        XCTAssertGreaterThan(layers[0].verticalOffset, 0)
        XCTAssertLessThan(layers[1].verticalOffset, 0)
    }

    func testTransitionCompletesBeforeNextLayoutRotation() {
        let model = MatrixAnimationModel(seed: 42)
        let size = MatrixCanvasSize(width: 1440, height: 900)

        let layers = model.renderLayers(elapsedTime: 25, canvasSize: size)

        XCTAssertEqual(layers.count, 1)
        XCTAssertEqual(layers[0].layout.generation, 1)
        XCTAssertEqual(layers[0].opacity, 1)
        XCTAssertEqual(layers[0].verticalOffset, 0)
    }
}

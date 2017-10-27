@testable import CommonMark
import XCTest

class CommonMarkTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMarkdownToHTML() {
        let markdown = "*Hello World*"
        let html = markdownToHtml(string: markdown)
        XCTAssertEqual(html, "<p><em>Hello World</em></p>\n")
    }

    func testMarkdownToNode() {
        let markdown = "*Hello World*"
        let rootNode = Node(markdown: markdown)
        XCTAssertNotNil(rootNode)
    }

    func testMarkdownToArrayOfBlocks() {
        let markdown = """
            # Heading

            ## Subheading

            Lorem ipsum _dolor sit_ amet.

            * List item 1
            * List item 2
            """
        let rootNode = Node(markdown: markdown)!
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 4)
    }
}

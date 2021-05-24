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
        let html = markdowntoHTML(string: markdown)
        XCTAssertEqual(html, "<p><em>Hello World</em></p>\n")
    }

    func testMarkdownToNode() {
        let markdown = "*Hello World*"
        let rootNode = Node(markdown: markdown)
        XCTAssertEqual(rootNode.elements.count, 1)
    }
    
    func testExtensions() {
        let markdown = """
        | foo | bar *test* |
        | --- | --- |
        | baz | bim |
        """
        let result = Node(markdown: markdown, extensions: [.table]).elements
        guard case let .table(headers, rows) = result[0] else {
            XCTFail()
            return
        }
        print(headers)
        guard headers.count == 1 else { XCTFail(); return }
        guard rows.count == 1 else { XCTFail(); return }
    }

    func testMarkdownToArrayOfBlocks() {
        let markdown = """
            # Heading

            ## Subheading

            Lorem ipsum _dolor sit_ amet.

            * List item 1
            * List item 2
            """
        let rootNode = Node(markdown: markdown)
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 4)
    }

    func testReadMarkdownFromNonInvalidFilenameReturnsNil() {
        let nonExistentFilename = "/lkjhgfdsa"
        let rootNode = Node(filename: nonExistentFilename)
        XCTAssertNil(rootNode)
    }
}

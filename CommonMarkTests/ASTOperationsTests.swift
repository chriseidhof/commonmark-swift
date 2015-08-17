import Foundation
import XCTest
import CommonMark

class ASTOperationsTests: XCTestCase {

    var elements: [Block]!

    override func setUp() {
        let filename = "cats.md"
        let markdown = loadFileInBundle(filename)
        guard let document = Node(markdown: markdown)
            else { fatalError("Failed to parse Markdown") }
        elements = document.elements
    }

    // MARK: Tests

    func testDeepCollectWithBlockElements() {
        let headerLevels = deepCollect(elements) { (block: Block) -> [Int] in
            switch block {
            case let .Header(_, level):
                return [level]
            default:
                return []
            }
        }

        XCTAssertEqual(headerLevels, [1,2,2,3,3,3,3,3,2,3,3,2,3,3])
    }

    func testDeepCollectWithInlineElements() {
        let linkTitles = deepCollect(elements) { (element: InlineElement) -> [String] in
            switch element {
            case let .Link(_ , title, _):
                return [title ?? "(no title)"]
            default:
                return []
            }
        }

        XCTAssertEqual(linkTitles, ["Wikipedia: Tiger", "Wikipedia: Lion", "Wikipedia: Jaguar", "Wikipedia: Leopard", "Wikipedia: Snow Leopard", "Wikipedia: Cougar", "Wikipedia: Cheetah", "Wikipedia: Clouded Leopard", "Wikipedia: Domestic Cat"])
    }

    func testDeepFilterWithBlockElements() {
        let isParagraph: Block -> Bool = { element in
            if case .Paragraph(_) = element { return true }
            else { return false }
        }
        let paragraphs = deepFilter(isParagraph)(elements: elements)

        XCTAssertEqual(paragraphs.count, 30)
        for element in paragraphs {
            XCTAssertTrue(isParagraph(element))
        }
    }

    func testDeepFilterInlineElements() {
        let isImage: InlineElement -> Bool = { element in
            if case .Image(_, _, _) = element { return true }
            else { return false }
        }
        let images = deepFilter(isImage)(elements: elements)

        XCTAssertEqual(images.count, 9)
        guard case let .Image(_, _, url) = images[0] else { XCTFail(); return }
        XCTAssertEqual(url, "https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Tigress_at_Jim_Corbett_National_Park.jpg/440px-Tigress_at_Jim_Corbett_National_Park.jpg")
    }

    // MARK: Helpers

    func loadFileInBundle(filename: String) -> String {
        let bundle = NSBundle(forClass: self.dynamicType)
        let url = urlForFile(filename, inBundle: bundle)
        let contents = try! NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
        return contents
    }

    func urlForFile(filename: String, inBundle bundle: NSBundle) -> NSURL {
        guard let url = bundle.URLForResource(filename, withExtension: nil)
            else { fatalError("Could not find file \(filename) in bundle \(bundle)") }
        return url
    }
}

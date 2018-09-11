import Aztec
import XCTest
@testable import WordPressEditor

class GutenbergInputHTMLTreeProcessorTests: XCTestCase {
    
    let parser = HTMLParser()
    let processor = GutenbergInputHTMLTreeProcessor()
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    // MARK: Regular Gutenberg Tags
    
    private func encode(blockString: String) -> String {
        let data = blockString.data(using: .utf16)!
        let base64String = data.base64EncodedString()
        
        return base64String
    }
    
    private func htmlComment(withContent content: String) -> String {
        return "<!--\(content)-->"
    }
    
    /// Verifies that a Gutenberg paragraph block is properly encoded.
    ///
    func testParagraphBlock() {
        let openingCommentText = " wp:paragraph "
        let closingCommentText = " /wp:paragraph "
        let openingGutentag = htmlComment(withContent: openingCommentText)
        let closingGutentag = htmlComment(withContent: closingCommentText)
        let text = "Hello there!"
        
        let input = "\(openingGutentag)\n<p>\(text)</p>\n\(closingGutentag)"
        
        let encodedOpeningComment = encode(blockString: openingCommentText)
        let encodedClosingComment = encode(blockString: closingCommentText)
        
        let rootNode = parser.parse(input)
        processor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        guard let gutenblock = rootNode.children[0] as? ElementNode,
            gutenblock.type == .gutenblock else {
                XCTFail()
                return
        }
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockOpener
                && attribute.value.toString() == encodedOpeningComment
        }))
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockCloser
                && attribute.value.toString() == encodedClosingComment
        }))
        
        XCTAssertEqual(gutenblock.children.count, 2)
        guard let paragraph = gutenblock.children[0] as? ElementNode else {
            XCTFail()
            return
        }

        XCTAssertEqual(paragraph.children.count, 1)
        guard let textNode = paragraph.children[0] as? TextNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(textNode.text(), text)
    }
    
    /// Verifies that a Gutenberg paragraph block with attributes is properly encoded.
    ///
    func testParagraphBlockWithAttributes() {
        let openingCommentText = " wp:paragraph {\"fontColor\": red, \"fontSize\": 12} "
        let closingCommentText = " /wp:paragraph "
        let openingGutentag = htmlComment(withContent: openingCommentText)
        let closingGutentag = htmlComment(withContent: closingCommentText)
        let text = "Hello there!"
        
        let input = "\(openingGutentag)\n<p>\(text)</p>\n\(closingGutentag)"
        
        let encodedOpeningComment = encode(blockString: openingCommentText)
        let encodedClosingComment = encode(blockString: closingCommentText)
        
        let rootNode = parser.parse(input)
        processor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        guard let gutenblock = rootNode.children[0] as? ElementNode,
            gutenblock.type == .gutenblock else {
                XCTFail()
                return
        }
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockOpener
                && attribute.value.toString() == encodedOpeningComment
        }))
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockCloser
                && attribute.value.toString() == encodedClosingComment
        }))
        
        XCTAssertEqual(gutenblock.children.count, 2)
        guard let paragraph = gutenblock.children[0] as? ElementNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(paragraph.children.count, 1)
        guard let textNode = paragraph.children[0] as? TextNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(textNode.text(), text)
    }
    
    // MARK: - Self-Closing Gutenberg Tags
    
    /// Verifies that a self closing block is properly processed
    ///
    func testSelfClosedBlock() {
        let selfClosingCommentText = " wp:latest-posts /"
        let openingCommentText = " wp:paragraph {\"fontColor\": red, \"fontSize\": 12} "
        let closingCommentText = " /wp:paragraph "
        let selfClosingGutentag = htmlComment(withContent: selfClosingCommentText)
        let openingGutentag = htmlComment(withContent: openingCommentText)
        let closingGutentag = htmlComment(withContent: closingCommentText)
        let text = "Hello there!"
        
        let input = "\(openingGutentag)\n<p>\(text)</p>\(selfClosingGutentag)\n\(closingGutentag)"
        
        let selfClosingComment = encode(blockString: selfClosingCommentText)
        let encodedOpeningComment = encode(blockString: openingCommentText)
        let encodedClosingComment = encode(blockString: closingCommentText)
        
        let rootNode = parser.parse(input)
        processor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        guard let gutenblock = rootNode.children[0] as? ElementNode,
            gutenblock.type == .gutenblock else {
                XCTFail()
                return
        }
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockOpener
                && attribute.value.toString() == encodedOpeningComment
        }))
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockCloser
                && attribute.value.toString() == encodedClosingComment
        }))
        
        XCTAssertEqual(gutenblock.children.count, 3)
        guard let paragraph = gutenblock.children[0] as? ElementNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(paragraph.rawText(), text)
        
        guard let gutenpack = gutenblock.children[1] as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(gutenpack.type, .gutenpack)
        
        XCTAssert(gutenpack.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.selfCloser
                && attribute.value.toString() == selfClosingComment
        }))
    }
}

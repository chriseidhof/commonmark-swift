//
//  SwiftAST.swift
//  CommonMark
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import cmark

// <<ListTypeEnum>>
public enum ListType {
    case Unordered
    case Ordered
}
// <</ListTypeEnum>>

// <<InlineElementEnum>>
public enum InlineElement {
    case Text(text: String)
    case SoftBreak
    case LineBreak
    case Code(text: String)
    case InlineHtml(text: String)
    case Emphasis(children: [InlineElement])
    case Strong(children: [InlineElement])
    case Link(children: [InlineElement], title: String?, url: String?)
    case Image(children: [InlineElement], title: String?, url: String?)
}
// <</InlineElementEnum>>

extension InlineElement : StringLiteralConvertible {
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(stringLiteral: StringLiteralType) {
        self = InlineElement.Text(text: stringLiteral)
    }
}

// <<BlockEnum>>
public enum Block {
    case List(items: [[Block]], type: ListType)
    case BlockQuote(items: [Block])
    case CodeBlock(text: String, language: String?)
    case Html(text: String)
    case Paragraph(text: [InlineElement])
    case Header(text: [InlineElement], level: Int)
    case HorizontalRule
}
// <</BlockEnum>>

// <<ParseInlineElement>>
extension Node {
    func inlineElement() -> InlineElement {
        let parseChildren = { self.children.map { $0.inlineElement() } }
        switch type {
        case CMARK_NODE_TEXT:
            return .Text(text: literal!)
        case CMARK_NODE_SOFTBREAK:
            return .SoftBreak
        case CMARK_NODE_LINEBREAK:
            return .LineBreak
        case CMARK_NODE_CODE:
            return .Code(text: literal!)
        case CMARK_NODE_INLINE_HTML:
            return .InlineHtml(text: literal!)
        case CMARK_NODE_EMPH:
            return .Emphasis(children: parseChildren())
        case CMARK_NODE_STRONG:
            return .Strong(children: parseChildren())
        case CMARK_NODE_LINK:
            return .Link(children: parseChildren(), title: title,
                url: urlString)
        case CMARK_NODE_IMAGE:
            return .Image(children: parseChildren(), title: title,
                url: urlString)
        default:
            fatalError("Expected inline element, got \(typeString)")
        }
    }
}
// <</ParseInlineElement>>

extension Node {
    public func parseListItem() -> [Block] {
        switch type {
        case CMARK_NODE_ITEM:
            return children.map { $0.block() }
        default:
            fatalError("Unrecognized node \(typeString), expected a list item")
        }
    }
}

// <<ParseBlock>>
extension Node {
    public func block() -> Block {
        let parseInlineChildren = { self.children.map { $0.inlineElement() } }
        let parseBlockChildren = { self.children.map { $0.block() } }
        switch type {
        case CMARK_NODE_PARAGRAPH:
            return .Paragraph(text: parseInlineChildren())
        case CMARK_NODE_BLOCK_QUOTE:
            return .BlockQuote(items: parseBlockChildren())
        case CMARK_NODE_LIST:
            let type = listType == CMARK_BULLET_LIST ?
                ListType.Unordered : ListType.Ordered
            return .List(items: children.map { $0.parseListItem() }, type: type)
        case CMARK_NODE_CODE_BLOCK:
            return .CodeBlock(text: literal!, language: fenceInfo)
        case CMARK_NODE_HTML:
            return .Html(text: literal!)
        case CMARK_NODE_HEADER:
            return .Header(text: parseInlineChildren(), level: headerLevel)
        case CMARK_NODE_HRULE:
            return .HorizontalRule
        default:
            fatalError("Unrecognized node: \(typeString)")
        }
    }
}
// <</ParseBlock>>

// <<NodeBuildingInits>>
extension Node {
    convenience init(type: cmark_node_type, literal: String) {
        self.init(type: type)
        self.literal = literal
    }
    convenience init(type: cmark_node_type, blocks: [Block]) {
        self.init(type: type, children: blocks.map { $0.node() })
    }
    convenience init(type: cmark_node_type, elements: [InlineElement]) {
        self.init(type: type, children: elements.map { $0.node() })
    }
}
// <</NodeBuildingInits>>

// <<NodeWithBlocks>>
extension Node {
    public convenience init(blocks: [Block]) {
        self.init(type: CMARK_NODE_DOCUMENT, blocks: blocks)
    }
}
// <</NodeWithBlocks>>

extension Node {
    /// The abstract syntax tree representation of a Markdown document.
    /// - returns: an array of block-level elements.
    public var elements: [Block] {
        return children.map { $0.block() }
    }
}

// <<ToNodeInline>>
extension InlineElement {
    func node() -> Node {
        let node: Node
        switch self {
        case .Text(let text):
            node = Node(type: CMARK_NODE_TEXT, literal: text)
        case .Emphasis(let children):
            node = Node(type: CMARK_NODE_EMPH, elements: children)
        case .Code(let text):
            node = Node(type: CMARK_NODE_CODE, literal: text)
        case .Strong(let children):
            node = Node(type: CMARK_NODE_STRONG, elements: children)
        case .InlineHtml(let text):
            node = Node(type: CMARK_NODE_INLINE_HTML, literal: text)
        case let .Link(children, title, url):
            node = Node(type: CMARK_NODE_LINK, elements: children)
            node.title = title
            node.urlString = url
        case let .Image(children, title, url):
            node = Node(type: CMARK_NODE_IMAGE, elements: children)
            node.title = title
            node.urlString = url
        case .SoftBreak: node = Node(type: CMARK_NODE_SOFTBREAK)
        case .LineBreak: node = Node(type: CMARK_NODE_LINEBREAK)
        }
        return node
    }

}
// <</ToNodeInline>>

// <<ToNodeBlock>>
extension Block {
    func node() -> Node {
       let node: Node
       switch self {
       case .Paragraph(let children):
         node = Node(type: CMARK_NODE_PARAGRAPH, elements: children)
       case let .List(items, type):
         let listItems = items.map { Node(type: CMARK_NODE_ITEM, blocks: $0) }
         node = Node(type: CMARK_NODE_LIST, children: listItems)
         node.listType = type == .Unordered ? CMARK_BULLET_LIST : CMARK_ORDERED_LIST
       case .BlockQuote(let items):
         node = Node(type: CMARK_NODE_BLOCK_QUOTE, blocks: items)
       case let .CodeBlock(text, language):
         node = Node(type: CMARK_NODE_CODE_BLOCK, literal: text)
         node.fenceInfo = language
       case .Html(let text):
         node = Node(type: CMARK_NODE_HTML, literal: text)
       case let .Header(text, level):
         node = Node(type: CMARK_NODE_HEADER, elements: text)
         node.headerLevel = level
       case .HorizontalRule:
         node = Node(type: CMARK_NODE_HRULE)
       }
       return node
    }
}
// <</ToNodeBlock>>
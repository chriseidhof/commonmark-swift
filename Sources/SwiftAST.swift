//
//  SwiftAST.swift
//  CommonMark
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import Ccmark

/// The type of a list in Markdown, represented by `Block.List`.
public enum ListType {
    case Unordered
    case Ordered
}

/// An inline element in a Markdown abstract syntax tree.
public enum Inline {
    case text(text: String)
    case softBreak
    case lineBreak
    case code(text: String)
    case html(text: String)
    case emphasis(children: [Inline])
    case strong(children: [Inline])
    case custom(literal: String)
    case link(children: [Inline], title: String?, url: String?)
    case image(children: [Inline], title: String?, url: String?)
}

extension Inline: ExpressibleByStringLiteral {
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(stringLiteral: StringLiteralType) {
        self = Inline.text(text: stringLiteral)
    }
}

/// A block-level element in a Markdown abstract syntax tree.
public enum Block {
    case list(items: [[Block]], type: ListType)
    case blockQuote(items: [Block])
    case codeBlock(text: String, language: String?)
    case html(text: String)
    case paragraph(text: [Inline])
    case heading(text: [Inline], level: Int)
    case custom(literal: String)
    case thematicBreak
}

extension Node {
    var inline: Inline {
        let inlineChildren = { self.children.map { $0.inline } }
        switch type {
        case CMARK_NODE_TEXT: return .text(text: literal!)
        case CMARK_NODE_SOFTBREAK: return .softBreak
        case CMARK_NODE_LINEBREAK: return .lineBreak
        case CMARK_NODE_CODE: return .code(text: literal!)
        case CMARK_NODE_HTML_INLINE: return .html(text: literal!)
        case CMARK_NODE_CUSTOM_INLINE: return .custom(literal: literal!)
        case CMARK_NODE_EMPH: return .emphasis(children: inlineChildren())
        case CMARK_NODE_STRONG: return .strong(children: inlineChildren())
        case CMARK_NODE_LINK: return .link(children: inlineChildren(), title: title, url: urlString)
        case CMARK_NODE_IMAGE: return .image(children: inlineChildren(), title: title, url: urlString)
        default:
            fatalError("Expected inline element, got \(typeString)")
        }
        
    }
    
    var listItem: [Block] {
        switch type {
        case CMARK_NODE_ITEM:
            return children.map { $0.block }
        default:
            fatalError("Unrecognized node \(typeString), expected a list item")
        }
    }
    
    var block: Block {
        let parseInlineChildren = { self.children.map { $0.inline } }
        let parseBlockChildren = { self.children.map { $0.block } }
        switch type {
        case CMARK_NODE_PARAGRAPH:
            return .paragraph(text: parseInlineChildren())
        case CMARK_NODE_BLOCK_QUOTE:
            return .blockQuote(items: parseBlockChildren())
        case CMARK_NODE_LIST:
            let type = listType == CMARK_BULLET_LIST ? ListType.Unordered : ListType.Ordered
            return .list(items: children.map { $0.listItem }, type: type)
        case CMARK_NODE_CODE_BLOCK:
            return .codeBlock(text: literal!, language: fenceInfo)
        case CMARK_NODE_HTML_BLOCK:
            return .html(text: literal!)
        case CMARK_NODE_CUSTOM_BLOCK:
            return .custom(literal: literal!)
        case CMARK_NODE_HEADING:
            return .heading(text: parseInlineChildren(), level: headerLevel)
        case CMARK_NODE_THEMATIC_BREAK:
            return .thematicBreak
        default:
            fatalError("Unrecognized node: \(typeString)")
        }
    }


}


extension Node {
    convenience init(type: cmark_node_type, literal: String) {
        self.init(type: type)
        self.literal = literal
    }
    convenience init(type: cmark_node_type, blocks: [Block]) {
        self.init(type: type, children: blocks.map(Node.init))
    }
    convenience init(type: cmark_node_type, elements: [Inline]) {
        self.init(type: type, children: elements.map(Node.init))
    }

    public convenience init(blocks: [Block]) {
        self.init(type: CMARK_NODE_DOCUMENT, blocks: blocks)
    }
}

extension Node {
    /// The abstract syntax tree representation of a Markdown document.
    /// - returns: an array of block-level elements.
    public var elements: [Block] {
        return children.map { $0.block }
    }
}

extension Node {
    convenience init(element: Inline) {
        switch element {
        case .text(let text):
            self.init(type: CMARK_NODE_TEXT, literal: text)
        case .emphasis(let children):
            self.init(type: CMARK_NODE_EMPH, elements: children)
        case .code(let text):
            self.init(type: CMARK_NODE_CODE, literal: text)
        case .strong(let children):
            self.init(type: CMARK_NODE_STRONG, elements: children)
        case .html(let text):
            self.init(type: CMARK_NODE_HTML_INLINE, literal: text)
        case .custom(let literal):
            self.init(type: CMARK_NODE_CUSTOM_INLINE, literal: literal)
        case let .link(children, title, url):
            self.init(type: CMARK_NODE_LINK, elements: children)
            self.title = title
            self.urlString = url
        case let .image(children, title, url):
            self.init(type: CMARK_NODE_IMAGE, elements: children)
            self.title = title
            urlString = url
        case .softBreak:
            self.init(type: CMARK_NODE_SOFTBREAK)
        case .lineBreak:
            self.init(type: CMARK_NODE_LINEBREAK)
        }
    }
    convenience init(block: Block) {
        switch block {
        case .paragraph(let children):
            self.init(type: CMARK_NODE_PARAGRAPH, elements: children)
        case let .list(items, type):
            let listItems = items.map { Node(type: CMARK_NODE_ITEM, blocks: $0) }
            self.init(type: CMARK_NODE_LIST, children: listItems)
            listType = type == .Unordered ? CMARK_BULLET_LIST : CMARK_ORDERED_LIST
        case .blockQuote(let items):
            self.init(type: CMARK_NODE_BLOCK_QUOTE, blocks: items)
        case let .codeBlock(text, language):
            self.init(type: CMARK_NODE_CODE_BLOCK, literal: text)
            fenceInfo = language
        case .html(let text):
            self.init(type: CMARK_NODE_HTML_BLOCK, literal: text)
        case .custom(let literal):
            self.init(type: CMARK_NODE_CUSTOM_BLOCK, literal: literal)
        case let .heading(text, level):
            self.init(type: CMARK_NODE_HEADING, elements: text)
            headerLevel = level
        case .thematicBreak:
            self.init(type: CMARK_NODE_THEMATIC_BREAK)
        }
    }
   
    
}

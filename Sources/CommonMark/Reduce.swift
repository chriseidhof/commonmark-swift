//
//  Reduce.swift
//  CommonMark
//
//  Created by Chris Eidhof on 02.04.19.
//

import Foundation
import Ccmark

/// An algebra for a block-level element
public struct InlineAlgebra<A> {
    public var text: (_ text: String) -> A
    public var softBreak: A
    public var lineBreak: A
    public var code: (_ text: String) -> A
    public var html: (_ text: String) -> A
    public var emphasis: (_ children: [A]) -> A
    public var strong: (_ children: [A]) -> A
    public var custom: (_ literal: String) -> A
    public var link: (_ children: [A], _ title: String?,  _ url: String?) -> A
    public var image: (_ children: [A], _ title: String?, _ url: String?) -> A
}

/// An algebra for a block-level element
public struct BlockAlgebra<A> {
    public var inline: InlineAlgebra<A>
    public var list: (_ items: [A], _ type: ListType) -> A
    public var listItem: (_ children: [A]) -> A
    public var blockQuote: (_ items: [A]) -> A
    public var codeBlock: (_ text: String, _ language: String?) -> A
    public var html: (_ text: String) -> A
    public var paragraph: (_ text: [A]) -> A
    public var heading: (_ text: [A], _ level: Int) -> A
    public var custom: (_ literal: String) -> A
    public var thematicBreak: A
    public var document: (_ children: [A]) -> A
    public var defaultValue: A
}

extension Node {
    public func reduce<R>(_ b: BlockAlgebra<R>) -> R {
        func r(_ node: Node) -> R {
            var children: [R] { return node.children.map(r) }
            var lit: String { return node.literal ?? "" }
            switch node.type {
            case CMARK_NODE_DOCUMENT: return b.document(children)
            case CMARK_NODE_BLOCK_QUOTE: return b.blockQuote(children)
            case CMARK_NODE_LIST: return b.list(children, node.listType == CMARK_BULLET_LIST ? .unordered : .ordered)
            case CMARK_NODE_ITEM: return b.listItem(children)
            case CMARK_NODE_CODE_BLOCK: return b.codeBlock(lit, node.fenceInfo)
            case CMARK_NODE_HTML_BLOCK: return b.html(lit)
            case CMARK_NODE_CUSTOM_BLOCK: return b.custom(lit)
            case CMARK_NODE_PARAGRAPH: return b.paragraph(children)
            case CMARK_NODE_HEADING: return b.heading(children, node.headerLevel)
            case CMARK_NODE_THEMATIC_BREAK: return b.thematicBreak
            case CMARK_NODE_FIRST_BLOCK: return b.defaultValue
            case CMARK_NODE_LAST_BLOCK: return b.defaultValue
                
                /* Inline */
            case CMARK_NODE_TEXT: return b.inline.text(lit)
            case CMARK_NODE_SOFTBREAK: return b.inline.softBreak
            case CMARK_NODE_LINEBREAK: return b.inline.lineBreak
            case CMARK_NODE_CODE: return b.inline.code(lit)
            case CMARK_NODE_HTML_INLINE: return b.inline.html(lit)
            case CMARK_NODE_CUSTOM_INLINE: return b.inline.custom(lit)
            case CMARK_NODE_EMPH: return b.inline.emphasis(children)
            case CMARK_NODE_STRONG: return b.inline.strong(children)
            case CMARK_NODE_LINK: return b.inline.link(children, node.title, node.urlString)
            case CMARK_NODE_IMAGE: return b.inline.image(children, node.title, node.urlString)
            default:
                return b.defaultValue
            }
        }
        return r(self)
    }
}

public protocol Monoid {
    init()
    static func +(lhs: Self, rhs: Self) -> Self
    mutating func append(_ value: Self)
}

extension Monoid {
    public mutating func append(_ value: Self) {
        self = self + value
    }
}

extension Array: Monoid { }

extension Array where Element: Monoid {
    public func flatten() -> Element {
        return reduce(into: .init(), { $0.append($1) })
    }
}

extension String: Monoid { }

/// This collects all elements into a result `M`.
///
/// For example, to collect all links in a document:
///
///     var links: BlockAlgebra<[String]> = collect()
///     links.inline.link = { _, _, url in url.map { [$0] } ?? [] }
///     let allLinks = Node(markdown: string)!.reduce(links)
public func collect<M: Monoid>() -> BlockAlgebra<M> {
    let inline: InlineAlgebra<M> = InlineAlgebra<M>(text: { _ in .init() }, softBreak: .init(), lineBreak: .init(), code: { _ in .init()}, html: { _ in .init() }, emphasis: { $0.flatten() }, strong: { $0.flatten() }, custom: { _ in .init() }, link: { x,_,_ in x.flatten() }, image: { x,_, _ in x.flatten() })
    
    return BlockAlgebra<M>(inline: inline, list: { x, _ in x.flatten() }, listItem: { $0.flatten() }, blockQuote: { $0.flatten() }, codeBlock: { _,_ in .init() }, html: { _ in .init() }, paragraph: { $0.flatten() }, heading: { x,_ in x.flatten() }, custom: { _ in .init() }, thematicBreak: .init(), document: { $0.flatten() }, defaultValue: .init())
}

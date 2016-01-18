//
//  ASTOperations.swift
//  CommonMark
//
//  Created by Chris Eidhof on 23/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation

func flatten<A>(x: [[A]]) -> [A] {
    return x.flatMap { $0 }
}

/// Apply a transformation to each block-level element in a Markdown document.
/// Performs a deep traversal of the element tree.
///
/// - parameter elements: The Markdown document you want to transform, 
///   represented as an array of block-level elements.
/// - parameter f: The transformation function that will be recursively applied
///   to each block-level element in `elements`.
///
///   The function returns an array of elements, which allows you to transform
///   one element into several (or none). Return an array containing only the
///   unchanged element to not transform that element at all. Return an empty
///   array to delete an element from the result.
/// - returns: A Markdown document containing the results of the transformation,
///   represented as an array of block-level elements.
public func deepApply(elements: [Block],  _ f: Block throws -> [Block]) rethrows -> [Block] {
    return try elements.flatMap {
        try deepApply(f)(element: $0)
    }
}

/// Apply a transformation to each inline element in a Markdown document.
/// Performs a deep traversal of the element tree.
///
/// - parameter elements: The Markdown document you want to transform,
///   represented as an array of block-level elements.
/// - parameter f: The transformation function that will be recursively applied
///   to each inline element in `elements`.
///
///   The function returns an array of elements, which allows you to transform
///   one element into several (or none). Return an array containing only the
///   unchanged element to not transform that element at all. Return an empty 
///   array to delete an element from the result.
/// - returns: A Markdown document containing the results of the transformation,
///   represented as an array of block-level elements.
public func deepApply(elements: [Block],  _ f: InlineElement throws -> [InlineElement]) rethrows -> [Block] {
    return try elements.flatMap {
        try deepApply(f)(element: $0)
    }
}

private func deepApply(@noescape f: Block throws -> [Block])(element: Block) rethrows -> [Block] {
   let recurse: Block throws -> [Block] = deepApply(f)
   switch element {
   case let .List(items, type):
     let mapped = Block.List(items: try items.map { try $0.flatMap(recurse) }, type: type)
     return try f(mapped)
   case .BlockQuote(let items):
    return try f(Block.BlockQuote(items: try items.flatMap { try recurse($0) }))
   default:
     return try f(element)
   }
}

private func deepApply(@noescape f: InlineElement throws -> [InlineElement])(element: Block) rethrows -> [Block] {
    let recurse: Block throws -> [Block] = deepApply(f)
    let applyInline: InlineElement throws -> [InlineElement] = deepApply(f)
    switch element {
    case .Paragraph(let children):
        return [Block.Paragraph(text: try children.flatMap { try applyInline($0) })]
    case let .List(items, type):
        return [Block.List(items: try items.map { try $0.flatMap { try recurse($0) } }, type: type)]
    case .BlockQuote(let items):
        return [Block.BlockQuote(items: try items.flatMap { try recurse($0) })]
    case let .Heading(text, level):
        return [Block.Heading(text: try text.flatMap { try applyInline($0) }, level: level)]
    default:
        return [element]
    }
}

private func deepApply(@noescape f: InlineElement throws -> [InlineElement])(element: InlineElement) rethrows -> [InlineElement] {
    let recurse: InlineElement throws -> [InlineElement] = deepApply(f)
    switch element {
    case .Emphasis(let children):
        return try f(InlineElement.Emphasis(children: try children.flatMap { try recurse($0) }))
    case .Strong(let children):
        return try f(InlineElement.Strong(children: try children.flatMap { try recurse($0) }))
    case let .Link(children, title, url):
        return try f(InlineElement.Link(children: try children.flatMap { try recurse($0) }, title: title, url: url))
    case let .Image(children, title, url):
        return try f(InlineElement.Image(children: try children.flatMap  { try recurse($0) }, title: title, url: url))
    default:
        return try f(element)
    }
}


/// Performs a deep 'flatMap' operation over all _block-level elements_ in a
/// Markdown document. Performs a deep traversal over all block-level elements
/// in the element tree, applies `f` to each element, and returns the flattened
/// results.
///
/// Use this function to extract data from a Markdown document. E.g. you could
/// extract the texts and levels of all headers in a document to build a table
/// of contents.
///
/// - parameter elements: The Markdown document you want to transform,
///   represented as an array of block-level elements.
/// - parameter f: The function that will be recursively applied to each 
///   block-level element in `elements`.
///
///   The function returns an array, which allows you to extract zero, one, or
///   multiple pieces of data from each element. Return an empty array to ignore
///   this element in the result.
/// - returns: A flattened array of the results of all invocations of `f`.
public func deepCollect<A>(elements: [Block], @noescape _ f: Block -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

/// Performs a deep 'flatMap' operation over all _inline elements_ in a Markdown
/// document. Performs a deep traversal over all inline elements in the element
/// tree, applies `f` to each element, and returns the flattened results.
///
/// Use this function to extract data from a Markdown document. E.g. you could
/// extract the URLs from all links in a document.
///
/// - parameter elements: The Markdown document you want to transform,
///   represented as an array of block-level elements.
/// - parameter f: The function that will be recursively applied to each
///   inline element in `elements`.
///
///   The function returns an array, which allows you to extract zero, one, or
///   multiple pieces of data from each element. Return an empty array to ignore
///   this element in the result.
/// - returns: A flattened array of the results of all invocations of `f`.
public func deepCollect<A>(elements: [Block], @noescape _ f: InlineElement -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

private func deepCollect<A>(@noescape f: Block -> [A])(element: Block) -> [A] {
   let recurse: Block -> [A] = deepCollect(f)
   switch element {
   case .List(let items, _):
    return flatten(items).flatMap(recurse) + f(element)
   case .BlockQuote(let items):
     return items.flatMap(recurse) + f(element)
   default:
     return f(element)
   }
}

private func deepCollect<A>(@noescape f: InlineElement -> [A])(element: Block) -> [A] {
    let collectInline: InlineElement -> [A] = deepCollect(f)
    let recurse: Block -> [A] = deepCollect(f)
    switch element {
    case .Paragraph(let children):
        return children.flatMap(collectInline)
    case let .List(items, _):
        return flatten(items).flatMap(recurse)
    case .BlockQuote(let items):
        return items.flatMap(recurse)
    case let .Heading(text, _):
        return text.flatMap(collectInline)
    default:
        return []
    }
}

private func deepCollect<A>(@noescape f: InlineElement -> [A])(element: InlineElement) -> [A] {
    let recurse: InlineElement -> [A] = deepCollect(f)
    switch element {
    case .Emphasis(let children):
        return children.flatMap(recurse) + f(element)
    case .Strong(let children):
        return children.flatMap(recurse) + f(element)
    case let .Link(children, _, _):
        return children.flatMap(recurse) + f(element)
    case let .Image(children, _, _):
        return children.flatMap(recurse) + f(element)
    default:
        return f(element)
    }
}


/// Return all block-level elements in a Markdown document that satisfy the
/// predicate `f`. Performs a deep traversal of the element tree.
///
/// - parameter elements: The Markdown document you want to filter, represented
///   as an array of block-level elements.
/// - parameter f: The predicate. Return `true` if the element should be
///   included in the results, `false` otherwise.
/// - returns: A Markdown document containing the filtered results, represented
///   as an array of block-level elements.
public func deepFilter(@noescape f: Block -> Bool)(elements: [Block]) -> [Block] {
    return elements.flatMap(deepFilter(f))
}

private func deepFilter(@noescape f: Block -> Bool) -> Block -> [Block] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}

/// Return all inline elements in a Markdown document that satisfy the predicate
/// `f`. Performs a deep traversal of the element tree.
///
/// - parameter elements: The Markdown document you want to filter, represented
///   as an array of block-level elements.
/// - parameter f: The predicate. Return `true` if the element should be
///   included in the results, `false` otherwise.
/// - returns: An array containing the filtered results.
public func deepFilter(@noescape f: InlineElement -> Bool)(elements: [Block]) -> [InlineElement] {
    return elements.flatMap(deepFilter(f))
}

private func deepFilter(@noescape f: InlineElement -> Bool) -> Block -> [InlineElement] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}

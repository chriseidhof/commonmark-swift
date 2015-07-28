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

extension SequenceType {
    func tmap<T>(@noescape transform: (Self.Generator.Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        for x in self {
            try result.append(transform(x))
        }
        return result

    }

    func flatMap<S : SequenceType>(@noescape transform: (Self.Generator.Element) throws -> S) rethrows -> [S.Generator.Element] {
        var result: [S.Generator.Element] = []
        for values in try self.tmap(transform) {
          result.extend(values)
        }
        return result
    }
}

public func deepApply(elements: [Block], _ f: Block throws -> [Block]) rethrows -> [Block] {
    return try elements.flatMap {
        try deepApply(f)(element: $0)
    }
}

public func deepApply(elements: [Block], _ f: InlineElement throws -> [InlineElement]) rethrows -> [Block] {
    return try elements.flatMap {
        try deepApply(f)(element: $0)
    }
}


public func deepApply(f: Block throws -> [Block])(element: Block) rethrows -> [Block] {
   let recurse: Block throws -> [Block] = deepApply(f)
   switch element {
   case let .List(items, type):
     let mapped = Block.List(items: try items.tmap { try $0.flatMap(recurse) }, type: type)
     return try f(mapped)
   case .BlockQuote(let items):
    return try f(Block.BlockQuote(items: try items.flatMap { try recurse($0) }))
   default:
     return try f(element)
   }
}

public func deepApply(f: InlineElement throws -> [InlineElement])(element: Block) rethrows -> [Block] {
    let recurse: Block throws -> [Block] = deepApply(f)
    let applyInline: InlineElement throws -> [InlineElement] = deepApply(f)
    switch element {
    case .Paragraph(let children):
        return [Block.Paragraph(text: try children.flatMap { try applyInline($0) })]
    case let .List(items, type):
        return [Block.List(items: try items.tmap { try $0.flatMap { try recurse($0) } }, type: type)]
    case .BlockQuote(let items):
        return [Block.BlockQuote(items: try items.flatMap { try recurse($0) })]
    case let .Header(text, level):
        return [Block.Header(text: try text.flatMap { try applyInline($0) }, level: level)]
    default:
        return [element]
    }
}


public func deepApply(f: InlineElement throws -> [InlineElement])(element: InlineElement) rethrows -> [InlineElement] {
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


public func deepCollect<A>(elements: [Block], _ f: Block -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

public func deepCollect<A>(elements: [Block], _ f: InlineElement -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

private func deepCollect<A>(f: Block -> [A])(element: Block) -> [A] {
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

private func deepCollect<A>(f: InlineElement -> [A])(element: Block) -> [A] {
    let collectInline: InlineElement -> [A] = deepCollect(f)
    let recurse: Block -> [A] = deepCollect(f)
    switch element {
    case .Paragraph(let children):
        return children.flatMap(collectInline)
    case let .List(items, _):
        return flatten(items).flatMap(recurse)
    case .BlockQuote(let items):
        return items.flatMap(recurse)
    case let .Header(text, _):
        return text.flatMap(collectInline)
    default:
        return []
    }
}

private func deepCollect<A>(f: InlineElement -> [A])(element: InlineElement) -> [A] {
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

public func deepFilter(f: Block -> Bool)(elements: [Block]) -> [Block] {
    return elements.flatMap(deepFilter(f))
}

private func deepFilter(f: Block -> Bool) -> Block -> [Block] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}

public func deepFilter(f: InlineElement -> Bool)(elements: [Block]) -> [InlineElement] {
    return elements.flatMap(deepFilter(f))
}

private func deepFilter(f: InlineElement -> Bool) -> Block -> [InlineElement] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}

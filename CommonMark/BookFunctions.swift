//
//  BookFunctions.swift
//  CommonMark
//
//  Created by Chris Eidhof on 05/01/16.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import Foundation

// <<TableOfContents>>
func tableOfContents(document: String) -> [Block] {
    let blocks = Node(markdown: document)?.children.map { $0.block() } ?? []
    return blocks.filter {
        switch $0 {
        case .Header(_, let level) where level < 3: return true
        default: return false
        }
    }
}
// <</TableOfContents>>

// <<StripLink>>
func stripLink(element: InlineElement) -> [InlineElement] {
    switch element {
    case let .Link(children, _, _):
        return children
    default:
        return [element]
    }
}
// <</StripLink>>

// <<AddFootnote>>
func addFootnote(inout counter: Int) ->
    InlineElement -> [InlineElement]
{
    return { element in
        switch element {
        case let .Link(children, _, _):
            counter++
            return children +
                [InlineElement.InlineHtml(text: "<sup>\(counter)</sup>")]
        default:
            return [element]
        }
    }
}
// <</AddFootnote>>

var elements: [Block] = []
// <<AddFootnoteExample>>
var counter = 0
let newElements = deepApply(elements, addFootnote(&counter))
// <</AddFootnoteExample>>

// <<AddFootnote2>>
func addFootnote2() -> InlineElement -> [InlineElement] {
    var counter = 0
    return { element in
        switch element {
        case let .Link(children, _, _):
            counter++
            return children + [InlineElement.InlineHtml(text: "<sup>\(counter)</sup>")]
        default:
            return [element]
        }
    }
}
// <</AddFootnote2>>

// <<LinkURL>>
func linkURL(blocks: [Block]) -> [String?] {
    return deepCollect(blocks) { (element: InlineElement) -> [String?] in
        switch element {
        case let .Link(_, _, url):
            return [url]
        default:
            return []
        }
    }
}
// <</LinkURL>>
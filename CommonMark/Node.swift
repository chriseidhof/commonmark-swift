//
//  CommonMark.swift
//  CommonMark
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import cmark

func stringUnlessNil(p: UnsafePointer<Int8>) -> String? {
    return p == nil ? nil : String(UTF8String: p)
}

extension String {
    /// Converts Markdown text to HTML.
    /// - returns: The HTML representation of `markdown`, or `nil` if the conversion fails.
    public func markdownToHTML() -> String? {
        let outString = cmark_markdown_to_html(self, self.utf8.count, 0)
        return String(UTF8String: outString)
    }
}


extension COpaquePointer {
    func mapIfNonNil<U>(transform: COpaquePointer->U) -> U? {
        if self == nil {
            return nil
        } else {
            return transform(self)
        }
    }
}

/// A node in a Markdown document.
///
/// Can represent a full Markdown document (i.e. the document's root node) or
/// just some part of a document.
public class Node: CustomStringConvertible {
    let node: COpaquePointer
    
    init(node: COpaquePointer) {
        self.node = node
    }
    
    public init?(filename: String) {
        node = cmark_parse_file(fopen(filename, "r"), 0)
        if node == nil { return nil}
    }

    public init?(markdown: String) {
        node = cmark_parse_document(markdown, markdown.utf8.count, 0)
        if node == nil { return nil }
    }

    init(type: cmark_node_type, children: [Node] = []) {
        node = cmark_node_new(type)
        for child in children {
            cmark_node_append_child(node, child.node)
        }
    }
    
    deinit {
        guard type == CMARK_NODE_DOCUMENT else { return }
        cmark_node_free(node)
    }
    
    var type: cmark_node_type {
        return cmark_node_get_type(node)
    }
    
    var listType: cmark_list_type {
        get { return cmark_node_get_list_type(node) }
        set { cmark_node_set_list_type(node, newValue) }
    }
    
    var listStart: Int {
        get { return Int(cmark_node_get_list_start(node)) }
        set { cmark_node_set_list_start(node, Int32(newValue)) }
    }
    
    var typeString: String {
        return String(UTF8String: cmark_node_get_type_string(node))!
    }
    
    var literal: String? {
        get { return stringUnlessNil(cmark_node_get_literal(node)) }
        set {
          if let value = newValue {
              cmark_node_set_literal(node, value)
          } else {
              cmark_node_set_literal(node, nil)
          }
        }
    }
    
    var headerLevel: Int {
        get { return Int(cmark_node_get_heading_level(node)) }
        set { cmark_node_set_heading_level(node, Int32(newValue)) }
    }
    
    var fenceInfo: String? {
        get { return stringUnlessNil(cmark_node_get_fence_info(node)) }
        set {
          if let value = newValue {
              cmark_node_set_fence_info(node, value)
          } else {
              cmark_node_set_fence_info(node, nil)
          }
        }
    }
    
    var urlString: String? {
        get { return stringUnlessNil(cmark_node_get_url(node)) }
        set {
          if let value = newValue {
              cmark_node_set_url(node, value)
          } else {
              cmark_node_set_url(node, nil)
          }
        }
    }
    
    var title: String? {
        get { return stringUnlessNil(cmark_node_get_title(node)) }
        set {
          if let value = newValue {
              cmark_node_set_title(node, value)
          } else {
              cmark_node_set_title(node, nil)
          }
        }
    }
    
    var children: [Node] {
        var result: [Node] = []
        var child = cmark_node_first_child(node)
        while child != nil {
            result.append(Node(node: child))
            child = cmark_node_next(child)
        }
        return result
    }

    /// Renders the HTML representation
    public var html: String {
        return stringUnlessNil(cmark_render_html(node, 0))!
    }
    
    /// Renders the XML representation
    public var xml: String {
        return stringUnlessNil(cmark_render_xml(node, 0))!
    }
    
    /// Renders the CommonMark representation
    public var commonMark: String {
        return stringUnlessNil(cmark_render_commonmark(node, CMARK_OPT_DEFAULT, 80))!
    }
    
    /// Renders the LaTeX representation
    public var latex: String {
        return stringUnlessNil(cmark_render_latex(node, CMARK_OPT_DEFAULT, 80))!
    }

    public var description: String {
        return "\(typeString) {\n \(literal ?? String())\(Array(children).description ?? String()) \n}"
    }
}

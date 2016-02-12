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

// <<MarkdownToHTML>>
extension String {
    public func markdownToHTML() -> String {
        let outString = cmark_markdown_to_html(self, self.utf8.count, 0)
        return String(UTF8String: outString)!
    }
}
// <</MarkdownToHTML>>


extension COpaquePointer {
    func mapIfNonNil<U>(transform: COpaquePointer->U) -> U? {
        if self == nil {
            return nil
        } else {
            return transform(self)
        }
    }
}

// <<NodeClass>>
public class Node: CustomStringConvertible {
    let node: COpaquePointer
    
    init(node: COpaquePointer) {
        self.node = node
    }
    
    deinit {
        guard type == CMARK_NODE_DOCUMENT else { return }
        cmark_node_free(node)
    }
}
// <</NodeClass>>

extension Node {
    public convenience init?(filename: String) {
        let node = cmark_parse_file(fopen(filename, "r"), 0)
        guard node != nil else { return nil}
        self.init(node: node)
    }

    // <<MarkdownInit>>
    public convenience init?(markdown: String) {
        let node = cmark_parse_document(markdown, markdown.utf8.count, 0)
        guard node != nil else { return nil }
        self.init(node: node)
    }
    // <</MarkdownInit>>

    // <<NodeWithChildrenInit>>
    convenience init(type: cmark_node_type, children: [Node] = []) {
        let node = cmark_node_new(type)
        for child in children {
            cmark_node_append_child(node, child.node)
        }
        self.init(node: node)
    }
    // <</NodeWithChildrenInit>>
    
    // <<NodeType>>
    var type: cmark_node_type {
        return cmark_node_get_type(node)
    }
    // <</NodeType>>
    
    // <<ListType>>
    var listType: cmark_list_type {
        get { return cmark_node_get_list_type(node) }
        set { cmark_node_set_list_type(node, newValue) }
    }
    // <</ListType>>
    
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
        get { return Int(cmark_node_get_header_level(node)) }
        set { cmark_node_set_header_level(node, Int32(newValue)) }
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
    
    // <<NodeChildrenSequence>>
    var childrenS: AnySequence<Node> {
        return AnySequence { () -> AnyGenerator<Node> in
            var child = cmark_node_first_child(self.node)
            return AnyGenerator {
                let result: Node? = child == nil ? nil : Node(node: child)
                child = cmark_node_next(child)
                return result
            }
        }
    }
    // <</NodeChildrenSequence>>


    // <<NodeChildren>>
    var children: [Node] {
        var result: [Node] = []
        var child = cmark_node_first_child(node)
        while child != nil {
            result.append(Node(node: child))
            child = cmark_node_next(child)
        }
        return result
    }
    // <</NodeChildren>>

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

//
//  EvergreenElement.swift
//
//
//  Created by Brian Hasenstab on 4/10/20.
//

public class EvergreenElement {
    var elementType: String
    var children: [EvergreenElement] = []
    
    var id: String?
    var classes: [String] = []
    
    init(elementType: String) {
        self.elementType = elementType
    }
}

public class DivEvergreenElement: EvergreenElement {
    var identifier: String
    var parentDiv: DivEvergreenElement?
    
    init(elementType: String, identifier: String) {
        self.identifier = identifier
        
        super.init(elementType: elementType)
    }
}

public class TextEvergreenElement: EvergreenElement {
    var text: String
    
    // Anchor elements
    var links: [LinkEvergreenElement] = []
    
    init(elementType: String, text: String) {
        self.text = text
        
        super.init(elementType: elementType)
    }
}

public class ImageEvergreenElement: EvergreenElement {
    var src: String
    var alt: String
    var title: String?
    
    init(elementType: String, src: String, alt: String, title: String?) {
        self.src = src
        self.alt = alt
        self.title = title
        
        super.init(elementType: elementType)
    }
}

public class ListEvergreenElement: EvergreenElement {
    var parentList: ListEvergreenElement?
    
    init(elementType: String, parentList: ListEvergreenElement? = nil) {
        if let parentList = parentList {
            self.parentList = parentList
        }
        
        super.init(elementType: elementType)
    }
}

public class ListItemEvergreenElement: TextEvergreenElement {
    init(_ text: String) {
        super.init(elementType: "li", text: text)
    }
}

public class BlockquoteEvergreenElement: EvergreenElement {
    var parentQuote: BlockquoteEvergreenElement?
    
    init(parentQuote: BlockquoteEvergreenElement? = nil) {
        if let parentQuote = parentQuote {
            self.parentQuote = parentQuote
        }
        
        super.init(elementType: "blockquote")
    }
}

public class LinkEvergreenElement {
    var text: String
    var href: String
    var title: String?
    
    init(text: String, href: String, title: String? = nil) {
        self.text = text
        self.href = href
        self.title = title
    }
}

public typealias Elements = [EvergreenElement]

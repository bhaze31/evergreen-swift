# Evergreen

Evergreen is a data formatter that converts between Markdown, opinionated JSON, HTML, and XML. The basics of Evergreen is an individual Evergreen element. This element is related to an HTML element, in that it contains classes, ids, and a type. However, this element can also have subchildren, which are also Evergreen elements. The remaining structure is as follows:

```
{
    metadata: Information to be 
    content: The root evergreen element
}
```

Each Evergreen element has the following properties:

```
{
    identifier: A unique identifier for the particular element
    elementType: The HTML element equivalent,
    parent: The optional parent to the current element,
    children: An array of Evergreen elements,
    
    classes: Classes to be used for the HTML element,
    id: An optional ID for the HTML element
    divIdentifier: An identifier to displa
   
}
``` 

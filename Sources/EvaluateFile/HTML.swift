import Foundation
import JavaScriptCore

public extension EvaluateFile {
    func verifyHTMLSyntax(scriptContent: String) -> Bool {
        let voidTags: Set<String> = [
            "area", "base", "br", "col", "embed", "hr", "img",
            "input", "link", "meta", "param", "source", "track", "wbr"
        ]
        
        var stack: [(String, Int)] = []
        var isValid = true
        
        let lines = scriptContent.components(separatedBy: .newlines)
        
        let tagRegex = try! NSRegularExpression(pattern: #"<\s*(/?)([a-zA-Z0-9]+)([^<>]*)\s*(/?)>"#, options: [])
        
        for (lineIndex, line) in lines.enumerated() {
            let nsLine = line as NSString
            let matches = tagRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            
            for match in matches {
                let isClosing = nsLine.substring(with: match.range(at: 1)) == "/"
                let tagName = nsLine.substring(with: match.range(at: 2)).lowercased()
                let attrString = nsLine.substring(with: match.range(at: 3))
                let isSelfClosing = nsLine.substring(with: match.range(at: 4)) == "/"
                
                // Vérifier nom de balise
                if (tagName.range(of: #"^[a-z][a-z0-9-]*$"#, options: .regularExpression) == nil) {
                    print("❌ Ligne \(lineIndex+1) : nom de balise invalide : <\(isClosing ? "/" : "")\(tagName)>")
                    isValid = false
                    continue
                }
                
                // Ne pas vérifier fermeture si void tag ou balise auto-fermée
                if voidTags.contains(tagName) || isSelfClosing {
                    continue
                }
                
                // Vérification des attributs
                if !attrString.trimmingCharacters(in: .whitespaces).isEmpty {
                    let attrRegex = try! NSRegularExpression(pattern: #"(\w+)(\s*=\s*(".*?"|'.*?'|[^'"\s>]+))?"#)
                    let attrMatches = attrRegex.matches(in: attrString, range: NSRange(location: 0, length: attrString.utf16.count))
                    
                    if attrMatches.isEmpty {
                        print("❌ Ligne \(lineIndex+1) : attributs mal formés dans la balise <\(tagName)> : \(attrString.trimmingCharacters(in: .whitespaces))")
                        isValid = false
                    }
                }
                
                if isClosing {
                    if let last = stack.last, last.0 == tagName {
                        stack.removeLast()
                    } else {
                        print("❌ Ligne \(lineIndex+1) : balise fermante inattendue : </\(tagName)>")
                        isValid = false
                    }
                } else {
                    stack.append((tagName, lineIndex + 1))
                }
            }
        }
        
        if !stack.isEmpty {
            for (unclosedTag, line) in stack {
                print("❌ Ligne \(line) : balise non fermée détectée : <\(unclosedTag)>")
            }
            isValid = false
        }
        
        return isValid
    }
}

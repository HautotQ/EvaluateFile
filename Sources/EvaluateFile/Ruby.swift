import SwiftUI

public extension EvaluateFile {
    func verifyRubySyntax(scriptContent: String) -> Bool {
        var isValid = true
        var blockStack: [String] = []
        
        let openingKeywords = ["class", "module", "def", "if", "unless", "case", "begin", "while", "until", "for", "do"]
        let closingKeyword = "end"
        
        func isBalanced(_ text: String, openChar: Character, closeChar: Character) -> Bool {
            var count = 0
            var insideString = false
            var escapeNext = false
            for char in text {
                if char == "\"" || char == "'" {
                    if !escapeNext {
                        insideString.toggle()
                    }
                }
                if insideString {
                    escapeNext = (char == "\\")
                    continue
                }
                if char == openChar {
                    count += 1
                } else if char == closeChar {
                    count -= 1
                    if count < 0 { return false }
                }
            }
            return count == 0
        }
        
        func isQuotesBalanced(_ text: String, quoteChar: Character) -> Bool {
            var count = 0
            var escapeNext = false
            for char in text {
                if char == quoteChar && !escapeNext {
                    count += 1
                }
                escapeNext = (char == "\\")
            }
            return count % 2 == 0
        }
        
        // Vérification des délimiteurs simples
        if !isBalanced(scriptContent, openChar: "{", closeChar: "}") {
            print("❌ Accolades non équilibrées.")
            isValid = false
        }
        if !isBalanced(scriptContent, openChar: "(", closeChar: ")") {
            print("❌ Parenthèses non équilibrées.")
            isValid = false
        }
        if !isBalanced(scriptContent, openChar: "[", closeChar: "]") {
            print("❌ Crochets non équilibrés.")
            isValid = false
        }
        if !isQuotesBalanced(scriptContent, quoteChar: "'") {
            print("❌ Chaînes de caractères simples non fermées.")
            isValid = false
        }
        if !isQuotesBalanced(scriptContent, quoteChar: "\"") {
            print("❌ Chaînes de caractères doubles non fermées.")
            isValid = false
        }
        
        // Vérification des commentaires multilignes
        let beginCount = scriptContent.components(separatedBy: "=begin").count - 1
        let endCount = scriptContent.components(separatedBy: "=end").count - 1
        if beginCount != endCount {
            print("❌ Commentaires multilignes (=begin/=end) non équilibrés.")
            isValid = false
        }
        
        // Analyse ligne par ligne
        let lines = scriptContent.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() {
            let index = i + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Gestion des blocs imbriqués
            for keyword in openingKeywords {
                if trimmed.hasPrefix(keyword + " ") || trimmed == keyword {
                    blockStack.append(keyword)
                    break
                }
            }
            
            if trimmed == closingKeyword {
                if blockStack.isEmpty {
                    print("❌ Ligne \(index) : 'end' sans bloc ouvert.")
                    isValid = false
                } else {
                    _ = blockStack.removeLast()
                }
            }
            
            // Vérification des erreurs communes
            if trimmed.hasPrefix("elsif") {
                if blockStack.last != "if" {
                    print("❌ Ligne \(index) : 'elsif' sans 'if'.")
                    isValid = false
                }
            }
            
            if trimmed.hasPrefix("else") || trimmed.hasPrefix("when") {
                if blockStack.isEmpty || (!blockStack.contains("if") && !blockStack.contains("case")) {
                    print("❌ Ligne \(index) : '\(trimmed)' mal positionné.")
                    isValid = false
                }
            }
            
            if trimmed.contains(";") {
                print("⚠️ Ligne \(index) : point-virgule détecté (inutile en Ruby).")
            }
            
            if trimmed.hasPrefix("def") && !trimmed.contains("(") && !trimmed.contains(" ")
                && !trimmed.contains("=") {
                print("⚠️ Ligne \(index) : méthode sans parenthèses ni arguments.")
            }
        }
        
        if !blockStack.isEmpty {
            print("❌ Bloc(s) non fermé(s) : \(blockStack.joined(separator: ", "))")
            isValid = false
        }
        
        if isValid {
            print("✅ Syntaxe Ruby valide.")
        } else {
            print("❌ Des erreurs de syntaxe Ruby ont été détectées.")
        }
        
        return isValid
    }
}

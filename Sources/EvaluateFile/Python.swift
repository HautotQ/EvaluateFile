import Foundation
import JavaScriptCore

public extension EvaluateFile {
    func verifyPythonSyntax(scriptContent: String) -> Bool {
        var isValid = true
        let lines = scriptContent.components(separatedBy: .newlines)
        
        var indentLevels: [Int] = []
        var expectedIndentAfterControl = false
        var openParensStack: [Character] = []
        var openQuotes: Character? = nil
        
        func matchingBracket(for char: Character) -> Character? {
            switch char {
            case "(": return ")"
            case "[": return "]"
            case "{": return "}"
            default: return nil
            }
        }
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                // Ligne vide ou commentaire : on ignore
                continue
            }
            
            // Gestion des quotes ouvertes / fermées
            for char in trimmed {
                if openQuotes == nil && (char == "\"" || char == "'") {
                    openQuotes = char
                } else if openQuotes == char {
                    openQuotes = nil
                }
            }
            if openQuotes != nil {
                print("❌ Ligne \(index + 1) : chaîne non fermée détectée")
                isValid = false
            }
            
            // Vérification indentation
            let indent = line.prefix { $0 == " " }.count
            
            if let lastIndent = indentLevels.last {
                if indent > lastIndent {
                    // On s’attend à une indentation + grande uniquement si ligne précédente attendait bloc
                    if !expectedIndentAfterControl {
                        print("❌ Ligne \(index + 1) : indentation inattendue")
                        isValid = false
                    }
                    indentLevels.append(indent)
                    expectedIndentAfterControl = false
                } else if indent == lastIndent {
                    // même niveau OK
                    expectedIndentAfterControl = false
                } else {
                    // indent < lastIndent : on revient à un niveau précédent
                    while let last = indentLevels.last, last > indent {
                        indentLevels.removeLast()
                    }
                    if indentLevels.last != indent {
                        print("❌ Ligne \(index + 1) : indentation incohérente")
                        isValid = false
                    }
                    expectedIndentAfterControl = false
                }
            } else {
                // Première ligne, on ajoute l’indentation
                indentLevels.append(indent)
            }
            
            // Vérification des lignes de contrôle nécessitant un ":" et un bloc indenté
            let controlKeywords = ["if", "for", "while", "def", "class", "elif", "else", "try", "except", "finally", "with"]
            let firstWord = trimmed.split(separator: " ").first?.lowercased() ?? ""
            
            if controlKeywords.contains(firstWord) {
                if !trimmed.hasSuffix(":") {
                    print("❌ Ligne \(index + 1) : instruction '\(firstWord)' doit se terminer par ':'")
                    isValid = false
                }
                expectedIndentAfterControl = true
            }
            
            // Vérification appariement parenthèses, crochets, accolades
            for char in trimmed {
                if openQuotes != nil {
                    // Si on est dans une chaîne, on ignore les parenthèses
                    continue
                }
                if "([{".contains(char) {
                    openParensStack.append(char)
                } else if ")]}".contains(char) {
                    if let lastOpen = openParensStack.last {
                        if matchingBracket(for: lastOpen) == char {
                            openParensStack.removeLast()
                        } else {
                            print("❌ Ligne \(index + 1) : parenthèse fermante '\(char)' ne correspond pas à '\(lastOpen)'")
                            isValid = false
                        }
                    } else {
                        print("❌ Ligne \(index + 1) : parenthèse fermante '\(char)' sans ouverture correspondante")
                        isValid = false
                    }
                }
            }
        }
        
        // Vérification finale si parenthèses ouvertes non fermées
        if !openParensStack.isEmpty {
            print("❌ Parenthèses non fermées détectées : \(openParensStack)")
            isValid = false
        }
        
        // Vérification finale si chaîne ouverte non fermée
        if openQuotes != nil {
            print("❌ Chaîne non fermée détectée à la fin du fichier")
            isValid = false
        }
        
        if isValid {
            print("✅ Vérification avancée syntaxe Python réussie")
        } else {
            print("⚠️ Des erreurs de syntaxe Python ont été détectées")
        }
        
        return isValid
    }
}

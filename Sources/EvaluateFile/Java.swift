import Foundation
import JavaScriptCore

public extension EvaluateFile {
    func verifyJavaSyntax(scriptContent: String) -> Bool {
        var isValid = true
        
        // Fonction utilitaire pour vérifier équilibre de caractères (ex: {}, (), [], "", '')
        func isBalanced(_ text: String, openChar: Character, closeChar: Character) -> Bool {
            var count = 0
            var insideString = false
            var escapeNext = false
            for char in text {
                if char == "\"" || char == "'" {
                    // Ignore équilibrage inside string literals
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
        
        // 1. Vérifier accolades {}, parenthèses (), crochets []
        if !isBalanced(scriptContent, openChar: "{", closeChar: "}") {
            print("❌ Accolades { } non équilibrées.")
            isValid = false
        }
        if !isBalanced(scriptContent, openChar: "(", closeChar: ")") {
            print("❌ Parenthèses ( ) non équilibrées.")
            isValid = false
        }
        if !isBalanced(scriptContent, openChar: "[", closeChar: "]") {
            print("❌ Crochets [ ] non équilibrés.")
            isValid = false
        }
        
        // 2. Vérifier guillemets "" et apostrophes '' équilibrés (chaînes et caractères)
        func isQuotesBalanced(_ text: String, quoteChar: Character) -> Bool {
            var count = 0
            var escapeNext = false
            for char in text {
                if char == quoteChar && !escapeNext {
                    count += 1
                }
                escapeNext = (char == "\\")
            }
            // Pour une bonne fermeture, le nombre doit être pair
            return count % 2 == 0
        }
        if !isQuotesBalanced(scriptContent, quoteChar: "\"") {
            print("❌ Chaînes de caractères \" non fermées.")
            isValid = false
        }
        if !isQuotesBalanced(scriptContent, quoteChar: "'") {
            print("❌ Caractères littéraux ' non fermés.")
            isValid = false
        }
        
        // 3. Vérifier commentaires multilignes /* ... */
        let openMultiComments = scriptContent.components(separatedBy: "/*").count - 1
        let closeMultiComments = scriptContent.components(separatedBy: "*/").count - 1
        if openMultiComments != closeMultiComments {
            print("❌ Commentaires multilignes /* */ non fermés correctement.")
            isValid = false
        }
        
        // 4. Analyse ligne par ligne
        let lines = scriptContent.components(separatedBy: .newlines)
        let identifierPattern = #"^[a-zA-Z_][a-zA-Z0-9_]*$"#
        let identifierRegex = try! NSRegularExpression(pattern: identifierPattern, options: [])
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ignorer lignes vides et commentaires
            if trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") {
                continue
            }
            
            // 4.a. Vérifier import se terminant par ';'
            if trimmed.hasPrefix("import ") && !trimmed.hasSuffix(";") {
                print("❌ Ligne \(index + 1) : import mal formé (manque point-virgule) : \(trimmed)")
                isValid = false
            }
            
            // 4.b. Vérifier présence d'instruction terminée par ';' sauf :
            // déclaration classe, interface, méthode (finit par {), ou lignes d'accolades seules
            if !trimmed.hasSuffix(";") && !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") {
                // exception si ligne contient uniquement annotations (@Override, etc)
                if !trimmed.hasPrefix("@") {
                    print("❌ Ligne \(index + 1) : instruction probablement mal terminée (pas de point-virgule) : \(trimmed)")
                    isValid = false
                }
            }
            
            // 4.x. Vérifier que les blocs if/while/for/switch utilisent bien des parenthèses
            let controlKeywords = ["if", "while", "for", "switch"]
            for keyword in controlKeywords {
                if trimmed.hasPrefix(keyword + " ") || trimmed.hasPrefix(keyword + "{") {
                    // Vérifie présence de parenthèses juste après le mot-clé
                    let keywordRange = trimmed.range(of: keyword)!
                    let afterKeyword = trimmed[keywordRange.upperBound...].trimmingCharacters(in: .whitespaces)
                    if !afterKeyword.hasPrefix("(") {
                        print("❌ Ligne \(index + 1) : mot-clé `\(keyword)` sans parenthèses autour de la condition.")
                        isValid = false
                    }
                }
            }
            
            // 4.c. Vérifier doublons de ;; (rare mais erreur fréquente)
            if trimmed.contains(";;") {
                print("❌ Ligne \(index + 1) : double point-virgule détecté.")
                isValid = false
            }
            
            // 4.d. Vérifier noms d'identifiants (variables, classes, méthodes)
            // exemple simple : chercher les mots clés class, interface, enum, void, etc
            if trimmed.hasPrefix("class ") || trimmed.hasPrefix("interface ") || trimmed.hasPrefix("enum ") {
                // Extraire le nom qui suit
                let parts = trimmed.components(separatedBy: .whitespaces)
                if parts.count > 1 {
                    let name = parts[1]
                    let range = NSRange(location: 0, length: name.utf16.count)
                    if identifierRegex.firstMatch(in: name, options: [], range: range) == nil {
                        print("❌ Ligne \(index + 1) : nom de classe ou interface invalide : \(name)")
                        isValid = false
                    }
                } else {
                    print("❌ Ligne \(index + 1) : déclaration de classe/interface/enum incomplète.")
                    isValid = false
                }
            }
            
            // 4.e. Vérifier signatures de méthode simples (ex: public void foo() { )
            if trimmed.contains("(") && trimmed.contains(")") && trimmed.hasSuffix("{") {
                // Pas trop complexe ici, juste vérifie qu'il y a un nom de méthode avant la parenthèse
                let methodPart = trimmed.components(separatedBy: "(")[0].trimmingCharacters(in: .whitespaces)
                let tokens = methodPart.components(separatedBy: .whitespaces)
                if let fullMethodName = tokens.last {
                    // On découpe par '.' et on garde seulement la dernière partie
                    let parts = fullMethodName.components(separatedBy: ".")
                    if let methodName = parts.last {
                        let range = NSRange(location: 0, length: methodName.utf16.count)
                        if identifierRegex.firstMatch(in: methodName, options: [], range: range) == nil {
                            print("❌ Ligne \(index + 1) : nom de méthode invalide : \(methodName)")
                            isValid = false
                        }
                    }
                } else {
                    print("❌ Ligne \(index + 1) : signature de méthode mal formée.")
                    isValid = false
                }
            }
        }
        
        // 5. Vérifier qu'il y a au moins une déclaration de classe valide
        let classRegex = try! NSRegularExpression(pattern: "\\bclass\\s+[a-zA-Z_][a-zA-Z0-9_]*", options: [])
        let matches = classRegex.matches(in: scriptContent, options: [], range: NSRange(location: 0, length: scriptContent.utf16.count))
        if matches.isEmpty {
            print("❌ Aucun déclaration de classe valide détectée (mot-clé 'class' manquant ou mal formé).")
            isValid = false
        }
        
        if isValid {
            print("✅ Syntaxe Java valide (vérification avancée).")
        } else {
            print("❌ Syntaxe Java invalide détectée.")
        }
        
        return isValid
    }
}

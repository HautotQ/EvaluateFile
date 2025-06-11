import SwiftUI

public extension EvaluateFile {
    func verifyPerlSyntax(scriptContent: String) -> Bool {
        var isValid = true
        var blockStack: [Int] = []  // On garde la ligne d'ouverture de chaque bloc
        
        // Helper pour ignorer les chaînes et commentaires
        func stripStringsAndComments(_ text: String) -> String {
            var result = ""
            var inSingle = false, inDouble = false
            var escape = false
            let chars = Array(text)
            var i = 0
            while i < chars.count {
                let char = chars[i]
                
                if inSingle {
                    if char == "'" && !escape {
                        inSingle = false
                    }
                    escape = (char == "\\")
                    result.append(" ")
                } else if inDouble {
                    if char == "\"" && !escape {
                        inDouble = false
                    }
                    escape = (char == "\\")
                    result.append(" ")
                } else {
                    if char == "#" {
                        result += String(repeating: " ", count: chars.count - i)
                        break
                    } else if char == "'" {
                        inSingle = true
                        result.append(" ")
                    } else if char == "\"" {
                        inDouble = true
                        result.append(" ")
                    } else {
                        result.append(char)
                    }
                }
                i += 1
            }
            return result
        }
        
        // Vérifie équilibre général (parenthèses, crochets, accolades)
        func isBalanced(_ text: String, open: Character, close: Character) -> Bool {
            var count = 0
            let stripped = stripStringsAndComments(text)
            for char in stripped {
                if char == open { count += 1 }
                else if char == close { count -= 1 }
                if count < 0 { return false }
            }
            return count == 0
        }
        
        if !isBalanced(scriptContent, open: "{", close: "}") {
            print("❌ Accolades non équilibrées.")
            isValid = false
        }
        if !isBalanced(scriptContent, open: "(", close: ")") {
            print("❌ Parenthèses non équilibrées.")
            isValid = false
        }
        if !isBalanced(scriptContent, open: "[", close: "]") {
            print("❌ Crochets non équilibrés.")
            isValid = false
        }
        
        // Vérifie équilibrage =pod/=cut
        let podCount = scriptContent.components(separatedBy: "=pod").count - 1
        let cutCount = scriptContent.components(separatedBy: "=cut").count - 1
        if podCount != cutCount {
            print("❌ Commentaires multilignes =pod/=cut non équilibrés.")
            isValid = false
        }
        
        let lines = scriptContent.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() {
            let lineNumber = i + 1
            let stripped = stripStringsAndComments(line)
            
            let openCount = stripped.filter { $0 == "{" }.count
            let closeCount = stripped.filter { $0 == "}" }.count
            
            for _ in 0..<openCount {
                blockStack.append(lineNumber)
            }
            
            for _ in 0..<closeCount {
                if blockStack.isEmpty {
                    print("❌ Ligne \(lineNumber) : accolade fermante sans ouverture.")
                    isValid = false
                } else {
                    _ = blockStack.removeLast()
                }
            }
            
            // Vérifie variables valides
            let varPattern = #"(?<!\\)[\$\@\%][a-zA-Z_][a-zA-Z0-9_]*"#
            let regex = try! NSRegularExpression(pattern: varPattern)
            let matches = regex.matches(in: stripped, range: NSRange(stripped.startIndex..., in: stripped))
            for match in matches {
                let varName = (stripped as NSString).substring(with: match.range)
                if varName.count < 2 {
                    print("❌ Ligne \(lineNumber) : nom de variable suspect '\(varName)'")
                    isValid = false
                }
            }
            
            // Usage inutile de ;
            if stripped == "};" {
                print("⚠️ Ligne \(lineNumber) : point-virgule inutile après une accolade fermante.")
            }
        }
        
        if !blockStack.isEmpty {
            let blocLignes = blockStack.map { "ligne \($0)" }
            print("❌ Blocs non fermés détectés à \(blocLignes.joined(separator: ", "))")
            isValid = false
        }
        
        if isValid {
            print("✅ Syntaxe Perl valide.")
        } else {
            print("❌ Des erreurs Perl ont été détectées.")
        }
        
        return isValid
    }
}

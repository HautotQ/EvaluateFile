import Foundation
import JavaScriptCore

public extension EvaluateFile {
    func verifyShellSyntax(scriptContent: String) -> Bool {
        let lines = scriptContent.components(separatedBy: .newlines)
        var isValid = true
        var ifCount = 0
        var fiCount = 0
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Vérification simple guillemets appariés
            let quotesCount = trimmedLine.filter { $0 == "\"" }.count
            if quotesCount % 2 != 0 {
                print("❌ Ligne \(index + 1) : guillemets non appariés")
                isValid = false
            }
            
            // Compter if et fi pour vérifier la correspondance
            if trimmedLine.hasPrefix("if ") || trimmedLine == "if" {
                ifCount += 1
                // Vérifier que "then" est présent dans la même ligne ou sur la suivante
                if !trimmedLine.contains("then") {
                    // Regarder la ligne suivante si possible
                    if index + 1 < lines.count {
                        let nextLine = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                        if nextLine != "then" {
                            print("❌ Ligne \(index + 1) : 'if' sans 'then' immédiatement après")
                            isValid = false
                        }
                    } else {
                        print("❌ Ligne \(index + 1) : 'if' sans 'then'")
                        isValid = false
                    }
                }
            }
            
            if trimmedLine == "fi" {
                fiCount += 1
            }
        }
        
        if ifCount != fiCount {
            print("❌ Nombre de 'if' (\(ifCount)) différent du nombre de 'fi' (\(fiCount))")
            isValid = false
        }
        
        if isValid {
            print("✅ Syntaxe shell basique vérifiée sans erreur")
        } else {
            print("⚠️ Erreurs détectées dans la syntaxe shell")
        }
        
        return isValid
    }
}

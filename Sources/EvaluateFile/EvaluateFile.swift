import Foundation
import JavaScriptCore

public class EvaluateFile {
    var fileExtension: String
    var files: [String] = []
    var context: JSContext = JSContext()!
    
    public init(fileExtension: String, files: [String]) {
        self.fileExtension = fileExtension
        self.files = files
        executeFiles(files)
    }
    
    public init(filename: String, fileExtension: String) {
        self.fileExtension = fileExtension
        executeFile(filename)
    }
    
    private func setupExceptionHandler() {
        context.exceptionHandler = { context, exception in
            if let exception = exception {
                let message = exception.toString() ?? "Erreur inconnue"
                let row = exception.objectForKeyedSubscript("line")?.toInt32() ?? -1
                print("⚠️ Erreur: \(message)")
                if row != -1 {
                    print("📍 Emplacement: ligne \(row)")
                } else {
                    print("📍 Emplacement non disponible")
                }
            }
        }
    }
    
    private func executeFile(_ filename: String) {
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("❌ Fichier \(filename).\(fileExtension) introuvable")
            return
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            setupExceptionHandler()
            processContent(filename: filename, content: content)
        } catch {
            print("❌ Erreur de lecture du fichier \(filename).\(fileExtension): \(error.localizedDescription)")
        }
    }
    
    func executeFiles(_ files: [String]) {
        setupExceptionHandler()
        
        for file in files {
            guard let fileURL = Bundle.main.url(forResource: file, withExtension: fileExtension) else {
                print("❌ Fichier \(file).\(fileExtension) introuvable")
                continue
            }
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                processContent(filename: file, content: content)
            } catch {
                print("❌ Erreur de lecture du fichier \(file).\(fileExtension): \(error.localizedDescription)")
            }
        }
    }
    
    private func processContent(filename: String, content: String) {
        switch fileExtension {
        case "js":
            // Redéfinition de console.log
            let consoleLog: @convention(block) (String) -> Void = { message in
                print(message)
            }
            context.objectForKeyedSubscript("console").setObject(consoleLog, forKeyedSubscript: "log" as NSString)
            
            let result = context.evaluateScript(content)
            
            if let result = result, !result.isUndefined {
                print("✅ Résultat final du script : \(result)")
            } else {
                print("⚠️ Résultat final du script vide ou undefined.")
            }
        case "sh":
            print("🔍 Vérification de la syntaxe de \(filename).sh...")
            let isValid = verifyShellSyntax(scriptContent: content)
            if isValid {
                print("✅ Syntaxe correcte pour \(filename).sh")
            } else {
                print("❌ Syntaxe incorrecte pour \(filename).sh")
            }
        case "py":
            print("🔍 Vérification de la syntaxe Python de \(filename).py...")
            if verifyPythonSyntax(scriptContent: content) {
                print("✅ Syntaxe Python valide pour \(filename).py")
            } else {
                print("❌ Syntaxe Python invalide détectée dans \(filename).py")
            }
        case "pl":
            print("🔍 Vérification de la syntaxe Perl de \(filename).pl...")
            if verifyPerlSyntax(scriptContent: content) {
                print("✅ Syntaxe Perl valide pour \(filename).pl")
            } else {
                print("❌ Syntaxe Perl invalide détectée dans \(filename).pl")
            }
        case "java":
            print("🔍 Vérification de la syntaxe Java de \(filename).java...")
            if verifyJavaSyntax(scriptContent: content) {
                print("✅ Syntaxe Java valide pour \(filename).java")
            } else {
                print("❌ Syntaxe Java invalide détectée dans \(filename).java")
            }
        case "rb", "rbw":
            print("🔍 Vérification de la syntaxe Ruby de \(filename).\(fileExtension)...")
            if verifyRubySyntax(scriptContent: content) {
                print("✅ Syntaxe Ruby valide pour \(filename).\(fileExtension)")
            } else {
                print("❌ Syntaxe Ruby invalide détectée dans \(filename).\(fileExtension)")
            }
        case "html":
            print("🔍 Vérification de la syntaxe HTML de \(filename).html ...")
            if verifyHTMLSyntax(scriptContent: content) {
                print("✅ Syntaxe HTML valide pour \(filename).html")
            } else {
                print("❌ Syntaxe HTML invalide détectée dans \(filename).html")
            }
        case "json":
            print("📦 Contenu JSON brut de \(filename).json :\n\(content)")
        case "md", "txt":
            print("📄 Contenu texte de \(filename).\(fileExtension) :\n\(content)")
        default:
            print("📁 Fichier \(filename).\(fileExtension) chargé, mais aucun traitement défini.")
        }
    }
}

@objc class ConsoleLogger: NSObject {
    @objc class func log(_ message: String) {
        print("🟢 JS console.log:", message)
    }
}

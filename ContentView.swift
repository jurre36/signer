import SwiftUI

struct ContentView: View {
    @State private var p12File: URL?
    @State private var mobileProvision: URL?
    @State private var ipaFile: URL?
    @State private var signingStatus: String = "Waiting for files..."

    var body: some View {
        VStack {
            // Buttons for file selection
            Button("Select .p12 Certificate") {
                selectFile(ofType: "p12") { url in
                    p12File = url
                }
            }
            .padding()

            Button("Select .mobileprovision") {
                selectFile(ofType: "mobileprovision") { url in
                    mobileProvision = url
                }
            }
            .padding()

            Button("Select .ipa file") {
                selectFile(ofType: "ipa") { url in
                    ipaFile = url
                }
            }
            .padding()

            // Sign and Upload Button
            if let p12 = p12File, let mobileProv = mobileProvision, let ipa = ipaFile {
                Button("Sign and Upload IPA") {
                    signAndUploadApp(p12: p12, mobileProvision: mobileProv, ipa: ipa)
                }
                .padding()
            }

            Text(signingStatus) // Display status messages
                .padding()
        }
        .padding()
    }
    
    // Function to select a file using NSOpenPanel (macOS specific)
    func selectFile(ofType type: String, completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = [type]
        if panel.runModal() == .OK {
            completion(panel.url)
        } else {
            completion(nil)
        }
    }
    
    // Main function to handle signing and uploading the app
    func signAndUploadApp(p12: URL, mobileProvision: URL, ipa: URL) {
        signingStatus = "Signing app..."
        
        // Call the function to sign the app
        signApp(with: p12, mobileProvision: mobileProvision, ipa: ipa) { success in
            if success {
                signingStatus = "App signed successfully. Uploading to server..."
                // Upload signed IPA to the server
                uploadSignedApp(ipa: ipa) { uploadSuccess in
                    if uploadSuccess {
                        signingStatus = "App uploaded successfully!"
                    } else {
                        signingStatus = "App upload failed."
                    }
                }
            } else {
                signingStatus = "Failed to sign the app."
            }
        }
    }

    // Function to sign the app using the codesign utility
    func signApp(with p12: URL, mobileProvision: URL, ipa: URL, completion: @escaping (Bool) -> Void) {
        // This usually involves using a subprocess to invoke `codesign`
        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = [
            "-f", // Force signing
            "-s", p12.path, // Path to .p12 certificate
            "--entitlements", mobileProvision.path, // Path to entitlements from .mobileprovision
            ipa.path // Path to IPA to sign
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            completion(true)
        } else {
            completion(false)
        }
    }

    // Function to upload the signed IPA to api.palera.in
    func uploadSignedApp(ipa: URL, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.palera.in/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add IPA file data to the multipart form
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(ipa.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(try! Data(contentsOf: ipa))
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
        
        task.resume()
    }
}

// Helper to append data to a Data object
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

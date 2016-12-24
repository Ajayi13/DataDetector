//
//  ViewController.swift
//  DataDetector
//
//  Created by Ajay Ghodadra on 23/12/16.
//  Copyright © 2016 Ajay Ghodadra. All rights reserved.
//

import UIKit
import Kanna

class ViewController: UIViewController {

    @IBOutlet var txtMessage: UITextView!
    var messageString: String = ""
    var arrLinks: [[String:Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Events
    
    @IBAction func validateEvent(_ sender: Any) {
        
        self.messageString = ""
        self.arrLinks.removeAll()
        
        if(txtMessage.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty){
            self.showAlert("No Message", message: "Please enter your message!")
        }else{
            
            self.messageString = self.txtMessage.text
            
            //Check for the phone number
            let isContainsPhones = self.checkForPhoneNumber(self.txtMessage.text)
            if isContainsPhones.count != 0 {
                //Detected phone numbers
                for phone in isContainsPhones {
                    self.messageString = self.messageString.replacingOccurrences(of: phone, with: String(repeating: "*", count: phone.characters.count))
                }
            }
            
            //Check for the url
            let isContainsUrls = self.checkForUrls(self.txtMessage.text)
            if isContainsUrls.count != 0 {
                //Detected urls
                for strUrl in isContainsUrls {
                    if strUrl.contains("carlist.my") {
                        if let url = URL(string: strUrl) {
                            do {
                                let contents = try String(contentsOf: url)
                                if let doc = Kanna.HTML(html: contents, encoding: String.Encoding.utf8) {
                                    let dict = ["url": strUrl,"title":doc.title ?? ""] as [String : Any]
                                    self.arrLinks.append(dict)
                                    self.messageString = self.messageString.replacingOccurrences(of: strUrl, with: "")
                                }
                            } catch {
                                // contents could not be loaded
                            }
                        } else {
                            // the URL was bad!
                        }
                    }else{
                        self.messageString = self.messageString.replacingOccurrences(of: strUrl, with: String(repeating: "*", count: 5))
                    }
                }
            }
        }
        
        
        if self.arrLinks.count != 0 {
            let dictMessage = [
                "message": [self.messageString],
                "links" : [self.arrLinks],
                ] as [String : Any]
            let jsonData: Data
            do{
                jsonData = try JSONSerialization.data(withJSONObject: dictMessage, options: JSONSerialization.WritingOptions())
                let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as! String
                self.showAlert("Success!", message: jsonString)
                
            } catch _ {
                print ("UH OOO")
            }
        }else{
            let dictMessage = [
                "message": [self.messageString],
                ] as [String : Any]
            let jsonData: Data
            do{
                jsonData = try JSONSerialization.data(withJSONObject: dictMessage, options: JSONSerialization.WritingOptions())
                let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as! String
                self.showAlert("Success!", message: jsonString)
                
            } catch _ {
                print ("UH OOO")
            }
        }
        
    }
    
    // MARK: - Methods
    
    //Phone Detector
    func checkForPhoneNumber(_ message: String) -> [String] {
        var arrPhone:[String] = []
        let inputPhone = message
        let detectorPhone = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        let matchesPhone = detectorPhone.matches(in: inputPhone, options: [], range: NSRange(location: 0, length: inputPhone.utf16.count))
        
        for matchPhone in matchesPhone {
            let phone = (inputPhone as NSString).substring(with: matchPhone.range)
            arrPhone.append(phone)
        }
        
        return arrPhone
    }
    
    //URL Detector
    func checkForUrls(_ message: String) -> [String] {
        var arrUrls:[String] = []
        let inputUrl = message
        let detectorUrl = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matchesUrl = detectorUrl.matches(in: inputUrl, options: [], range: NSRange(location: 0, length: inputUrl.utf16.count))
        
        for matchUrl in matchesUrl {
            let url = (inputUrl as NSString).substring(with: matchUrl.range)
            arrUrls.append(url)
        }
        
        return arrUrls
        
    }
    
    // MARK: - UIAlertController
    
    func showAlert(_ title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) {
            (action) in
            alertController .dismiss(animated: true, completion:nil)
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true) {
            
        }
    }
    
}

extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        
        return fromIndex ..< toIndex
    }
}

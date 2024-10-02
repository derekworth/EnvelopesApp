//
//  ViewController.swift
//  Envelopes
//
//  Created by Derek Worth on 9/23/18.
//  Copyright © 2018 Derek Worth. All rights reserved.
//

import UIKit
import os.log
import CommonCrypto

struct Credentials {
    var username: String
    var password: String
    var ipaddr: String
}

class ViewController: UIViewController, UITextFieldDelegate, CredentialsViewControllerDelegate {
    
    //MARK: IBOutlets
    @IBOutlet weak var cmdTextField: UITextField!
    @IBOutlet weak var responseTextView: UITextView!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var fwdBtn: UIButton!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    //MARK: Global Variables
    var cmdHist = LinkedList<String>()
    var currCmd: LinkedList<String>.LinkedListNode<String>? = nil
    var un: String = "Admin"
    var pw: String = "password"
    var ip: String = "192.168.0.1"
    
    var cred: Credentials?
    
    //MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let diff: CGFloat = 35
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.bottomLayoutConstraint.constant = keyboardFrame.height - diff
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.bottomLayoutConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    //MARK: UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        loadLoginInfo()
        cmdTextField.delegate = self
        responseTextView.layoutManager.allowsNonContiguousLayout = false
        self.backBtn.isEnabled = false
        self.fwdBtn.isEnabled = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        cmdTextField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let credentialsViewController = segue.destination as? CredentialsViewController
            else {
                return
        }
        credentialsViewController.cred = cred
        credentialsViewController.delegate = self
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.backBtn.isEnabled = true
        self.fwdBtn.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.backBtn.isEnabled = false
        self.fwdBtn.isEnabled = false
    }
    
    //MARK: UITextFieldDelegate methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if(textField==cmdTextField) {
            // create message
            let cmd = cmdTextField.text ?? ""
            if(cmd.isEmpty) {
                return true
            }
            
            // save cmd in history
            cmdHist.append(cmd)
            // reset cmd history pointer to end of list
            currCmd = nil
            
            let pwhash = md5(pw)
            let msg = un + " " + cmd
            let msghash = md5(pwhash + msg)
            let finalmsg = msghash + " " + msg + "`\n"
            cmdTextField.text = ""
            
            // connect to server
            let client = TCPClient(address: ip, port:8456)
            switch client.connect(timeout: 4) {
            case .success:
                // send message
                client.send(string: finalmsg)
                
                // receive response
                var responseStr: String = ""
                
                while(true) {
                    let blk = client.read(1024, timeout: 2)
                    if(blk==nil) {
                        break
                    }
                    responseStr.append(contentsOf: (String(bytes: blk ?? [], encoding: .utf8) ?? "<empty>"))
                }
                
                responseStr = String(responseStr.prefix(upTo: responseStr.index(responseStr.endIndex, offsetBy: -2))) // remove ending ` character
                responseTextView.text.append(responseStr + "\n\n")
                
                client.close()
            default:
                responseTextView.text.append("Server error... failure to connect. Verify credentials or visit https://github.com/derekworth/Text-Envelopes for guidance on how to configure your Envelopes server.\n\n")
            }
            
            // scroll to bottom
            responseTextView.scrollRangeToVisible(NSMakeRange(responseTextView.text.count-1, 0))
        }
        return true
    }
    
    //MARK: IBActions
    @IBAction func clearButton(_ sender: Any) {
        responseTextView.text = "";
    }
    
    @IBAction func backButton(_ sender: Any) {
        if(currCmd==nil) {
            currCmd = cmdHist.last
        } else if( !(currCmd?.previous==nil) ) {
            currCmd = currCmd?.previous
        }
        
        if( !(currCmd==nil) ) {
            cmdTextField.text = currCmd?.value
        }
    }
    
    @IBAction func fwdButton(_ sender: Any) {
        if( !(currCmd==nil) ) {
            if(currCmd?.next==nil) {
                currCmd = nil
                cmdTextField.text = ""
            } else {
                currCmd = currCmd?.next
                cmdTextField.text = currCmd?.value
            }
        }
    }
    
    //MARK: Helper Methods
    func loadLoginInfo() {
        let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let ArchiveURL = DocumentsDirectory.appendingPathComponent("logininfo")
        
        // Load from Disk
        let loadedDictionary = NSDictionary(contentsOf: ArchiveURL)
        if let dictionary = loadedDictionary {
            un = dictionary["un"] as? String ?? "Admin"
            pw = dictionary["pw"] as? String ?? "password"
            ip = dictionary["ip"] as? String ?? "192.168.0.1"
            cred = Credentials.init(username: un, password: pw, ipaddr: ip)
        } else {
            un = "admin"
            pw = "password"
            ip = "192.168.0.1"
            cred = Credentials.init(username: un, password: pw, ipaddr: ip)
        }
    }
    
    func saveLoginInfo() {
        let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let ArchiveURL = DocumentsDirectory.appendingPathComponent("logininfo")
        
        // Write Array to Disk
        let dictionary = ["un" : un, "pw" : pw, "ip" : ip] as NSDictionary
        dictionary.write(toFile: ArchiveURL.path, atomically: true)
    }
    
    func update(_ cred: Credentials) {
        self.cred = cred
        un = cred.username
        pw = cred.password
        ip = cred.ipaddr
        self.saveLoginInfo()
    }
    
    private func md5(_ string: String) -> String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        return hexString
    }
}


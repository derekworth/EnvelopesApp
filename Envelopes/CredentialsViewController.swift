//
//  CredentialsController.swift
//  Envelopes
//
//  Created by Derek Worth on 3/3/19.
//  Copyright © 2019 Derek Worth. All rights reserved.
//

import UIKit

protocol CredentialsViewControllerDelegate: AnyObject {
    func update(_ cred: Credentials)
}

class CredentialsViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: IBOutlets
    @IBOutlet weak var unTextField: UITextField!
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var ipTextField: UITextField!
    
    var cred: Credentials?
    weak var delegate: CredentialsViewControllerDelegate?
    
    //MARK: UIViewController methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        unTextField?.text = cred?.username
        pwTextField?.text = cred?.password
        ipTextField?.text = cred?.ipaddr
        unTextField.delegate = self
        pwTextField.delegate = self
        ipTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ViewController {
            viewController.cred = cred
        }
    }
    
    //MARK: IBActions
    //@IBAction func cancelButton(_ sender: Any) {
    //    self.dismiss(animated: true, completion: nil)
    //}
    
    @IBAction func saveButton(_ sender: Any) {
        cred?.username = unTextField?.text ?? "admin"
        cred?.password = pwTextField?.text ?? "password"
        cred?.ipaddr = ipTextField?.text ?? "10.0.0.1"
        if let cred = cred {
            delegate?.update(cred)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
}

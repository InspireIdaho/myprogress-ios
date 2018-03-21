//  SettingsVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit
import Alamofire

class SettingsVC: UIViewController {
    
    @IBOutlet var saveBarButton: UIBarButtonItem!
    @IBOutlet var cancelBarButton: UIBarButtonItem!
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var savePasswordSwitch: UISwitch!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    
    @IBOutlet var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        var message: String

        if let user = User.principle {
            // set up UI for existing user
            configureUIFor(user: user)
            message = "Login to re-authenticate"

        } else {
            // setup UI for brand new participant
            configureBlankUI()
            message = "Enter Email/Password to register or login as InspireIdaho participant"
        }
        
        messageLabel.text = message
        updateNavButtons()
        updateLoginButton()
    }
    
    @IBAction func save(_ sender: Any) {
        if let user = User.principle {
            if user.hasChanges {
                user.save()
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {

        if let user = User.principle {
            if user.hasChanges {
                // reset to saved state in store
                User.initAtLaunch()
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func clearUser(_ sender: Any) {
        
        let alert = UIAlertController(title: "Delete Settings!", message: "Warning: this action will delete all user login info from app and progress data cached in memory. Data on the server will not be affected.  You will have to re-login to access.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { alert in
            User.deletePrinciple()
            ProgressNode.clearRegistry()
            self.configureBlankUI()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default) { alert in
            
        })
        self.present(alert, animated: true)
    }
    
    @IBAction func changePasswordSave(_ sender: Any) {
        if let user = User.principle {
            user.shouldSavePassword = savePasswordSwitch.isOn
        }
    }
    
    @IBAction func register(_ sender: Any) {
        registerCredentials()
    }
    
    @IBAction func login(_ sender: Any) {
        login()
    }
    
    func configureUIFor(user: User) {
        emailTextField.text = user.email
        emailTextField.isEnabled = false
        passwordTextField.text = user.password
        savePasswordSwitch.isOn = user.shouldSavePassword
        
        loginButton.isEnabled = (user.password != nil)
        registerButton.isEnabled = false
        clearButton.isHidden = false
    }
    
    func configureBlankUI() {
        emailTextField.text = ""
        emailTextField.isEnabled = true
        passwordTextField.text = ""
        savePasswordSwitch.isOn = false
        
        loginButton.isEnabled = true
        registerButton.isEnabled = true
        clearButton.isHidden = true
    }
    
    func updateLoginButton() {
        loginButton.isEnabled = false
        registerButton.isEnabled = false

        if let user = User.principle {
            loginButton.isEnabled = (user.password != nil)
            registerButton.isEnabled = false
            
        } else {
            if emailTextField.text != nil &&
                (emailTextField.text!.lengthOfBytes(using: String.Encoding.ascii) > 3) &&
                passwordTextField.text != nil &&
                (passwordTextField.text!.lengthOfBytes(using:String.Encoding.ascii) >= 7) {
                loginButton.isEnabled = true
                registerButton.isEnabled = true
            }
        }
        
    }
    
    func updateNavButtons() {
        
        cancelBarButton.isEnabled = true
        saveBarButton.isEnabled = false
        
        if let user = User.principle {
            saveBarButton.isEnabled = user.hasChanges
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerCredentials() {
        guard let email = emailTextField.text else { return  }
        guard let password = passwordTextField.text else { return  }

        var params = Parameters()
        params["email"] = email
        params["password"] = password
        
        DataBroker.makeUsersAPIcall(method: .post, json: params) { response in
            if let headers = response.response?.allHeaderFields as Dictionary? {
                //print(headers)
                let authKey = Config.env.authHeaderKey
                if let authToken = headers[authKey] as? String {
                    // success
                    let user = User(email: email)
                    user.token = authToken
                    user.save()
                    user.password = password
                    user.shouldSavePassword = self.savePasswordSwitch.isOn
                    User.principle = user
                    
                    self.messageLabel.text = "Registration Successful"
                    self.configureUIFor(user: user)
                    self.updateNavButtons()
                    //self.updateLoginButton()

                } else {
                    self.messageLabel.text = "Could not register credentials"
                }
            } else {
                print("convert error")
            }
            
        }
    }
    
    
    func login() {
        guard let email = emailTextField.text else { return  }
        guard let password = passwordTextField.text else { return  }

        var params = Parameters()
        params["email"] = email
        params["password"] = password

        DataBroker.makeUsersLoginCall(method: .post, json: params) { response in
            if let headers = response.response?.allHeaderFields as Dictionary? {
                //print(headers)
                let authKey = Config.env.authHeaderKey
                if let authToken = headers[authKey] as? String {
                    if let user = User.principle {
                        user.token = authToken
                        user.save()
                        user.password = password
                        
                        self.configureUIFor(user: user)
                    } else {
                        // create new local user
                        let user = User(email: email)
                        user.token = authToken
                        user.save()
                        user.shouldSavePassword = self.savePasswordSwitch.isOn
                        user.password = password
                        User.principle = user
                        
                        self.configureUIFor(user: user)
                    }
                    self.messageLabel.text = "Login Successful"
                    self.updateNavButtons()
                    
                    DataBroker.getAllProgressNodes() { }

                } else {
                    self.messageLabel.text = "Could not login"
                }
            } else {
                print("convert error")
            }
        }
        
    }

}

extension SettingsVC : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let user = User.principle {
            if textField == passwordTextField {
                user.password = passwordTextField.text
            }
            updateNavButtons()
        }
        updateLoginButton()
        return true
    }
}

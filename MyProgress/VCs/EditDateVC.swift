//  EditDateVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit

protocol EditDateVCDelegate {
    func editDateVCDidCancel()
    func editDateVCDidFinishWith(newdate: Date, for node: ProgressNode)
}

class EditDateVC: UIViewController {

    var targetNode: ProgressNode!
    var delegate: EditDateVCDelegate?
    
    @IBOutlet var cancelBarButton: UIBarButtonItem!
    @IBOutlet var doneBarButton: UIBarButtonItem!
    @IBOutlet var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //title = "Change Date Completed"
        
        datePicker.date = targetNode.completedOn!
        updateButtonState()
        
    }
    
    func updateButtonState() {
        if (targetNode.completedOn! == datePicker.date) {
            cancelBarButton.isEnabled = true
            doneBarButton.isEnabled = false
        } else {
            cancelBarButton.isEnabled = true
            doneBarButton.isEnabled = true
        }
    }
    
    @IBAction func doneEditing(_ sender: Any) {
        delegate?.editDateVCDidFinishWith(newdate: datePicker.date, for: targetNode)
        //navigationController?.popViewController(animated: true)
    }
    @IBAction func cancelEditing(_ sender: Any) {
        delegate?.editDateVCDidCancel()
        //navigationController?.popViewController(animated: true)
    }
    
    @IBAction func dateChanged(_ sender: Any) {
        updateButtonState()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
